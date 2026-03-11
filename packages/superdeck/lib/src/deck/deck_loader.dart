import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:superdeck_core/superdeck_core.dart';

Exception _asException(Object error) {
  return error is Exception ? error : Exception(error.toString());
}

/// File-based [DeckLoader] implementation for debug IO runtimes.
///
/// [load] returns a long-lived stream:
/// 1. Emits [DeckLoadingEvent].
/// 2. Emits all subsequent events from `build_status.json`.
class FileDeckLoader extends DeckLoader {
  FileDeckLoader({required super.configuration});

  final _controller = StreamController<DeckEvent>();
  final _disposeSignal = Completer<void>();
  Future<void>? _runTask;
  var _disposed = false;

  File get _deckFile => configuration.deckJson;
  File get _statusFile => configuration.buildStatusJson;
  Directory get _statusParentDir => _statusFile.parent;
  Directory get _projectDir => Directory(configuration.projectDir ?? '.');

  bool get _isActive => !_disposed && !_controller.isClosed;

  Future<void> _processStatus() async {
    if (!await _statusFile.exists()) return;

    try {
      final decoded = jsonDecode(await _statusFile.readAsString());
      if (decoded is! Map) return;
      final status = DeckBuildStatus.fromMap(
        Map<String, dynamic>.from(decoded),
      );

      if (!_isActive) return;

      switch (status.phase) {
        case DeckBuildPhase.building:
          _controller.add(DeckRebuildingEvent());
        case DeckBuildPhase.failure:
          final message = status.error?.message ?? 'Deck build failed';
          _controller.add(DeckErrorEvent(message, error: Exception(message)));
        case DeckBuildPhase.success:
          try {
            final deckJson = jsonDecode(await _deckFile.readAsString());
            if (deckJson is! Map) {
              throw Exception(
                'Expected JSON object at ${_deckFile.path}, '
                'got ${deckJson.runtimeType}',
              );
            }
            if (_isActive) {
              _controller.add(
                DeckLoadedEvent(
                  Deck.parse(Map<String, Object?>.from(deckJson)),
                ),
              );
            }
          } on Object catch (error) {
            if (_isActive) {
              _controller.add(
                DeckErrorEvent(
                  'Superdeck reference error',
                  error: _asException(error),
                ),
              );
            }
          }
        case DeckBuildPhase.unknown:
          break;
      }
    } on Object catch (error) {
      if (_isActive) {
        _controller.add(
          DeckErrorEvent('Build status error', error: _asException(error)),
        );
      }
    }
  }

  /// Waits for the status parent directory to be created.
  Future<void> _waitForDirectoryCreation() async {
    if (_disposed || await _statusParentDir.exists()) return;

    final wait = Completer<void>();
    StreamSubscription<FileSystemEvent>? sub;
    try {
      sub = _projectDir
          .watch(events: FileSystemEvent.create, recursive: true)
          .listen(
            // Any create event could be the directory — wake up and let the
            // main loop re-check rather than risking a race condition.
            (_) {
              if (!wait.isCompleted) wait.complete();
            },
            onError: (_, __) {
              if (!wait.isCompleted) wait.complete();
            },
            onDone: () {
              if (!wait.isCompleted) wait.complete();
            },
          );
      await Future.any<void>([wait.future, _disposeSignal.future]);
    } on FileSystemException {
      // Directory may not exist yet
    } finally {
      await sub?.cancel();
    }
  }

  /// Waits for the status file to change using [FileWatcher].
  ///
  /// Returns `true` if a change was detected, `false` if disposed.
  Future<bool> _waitForStatusChange() async {
    final watcher = FileWatcher(
      _statusFile,
      events: FileSystemEvent.create | FileSystemEvent.modify,
    );

    final changed = Completer<void>();
    final sub = watcher.watch().listen((_) {
      if (!changed.isCompleted) changed.complete();
    });

    try {
      await Future.any<void>([changed.future, _disposeSignal.future]);
      return changed.isCompleted;
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _run() async {
    if (_isActive) {
      _controller.add(DeckLoadingEvent('Loading deck…'));
    }

    while (_isActive) {
      if (!await _statusParentDir.exists()) {
        await _waitForDirectoryCreation();
        continue;
      }

      await _processStatus();
      if (!_isActive) return;

      final changed = await _waitForStatusChange();
      if (!changed) return;
    }
  }

  @override
  Stream<DeckEvent> load() {
    if (_runTask == null && !_disposed) {
      _runTask = _run().catchError((Object error) {
        if (_isActive) {
          _controller.add(
            DeckErrorEvent('Build status error', error: _asException(error)),
          );
        }
      });
    }
    return _controller.stream;
  }

  @override
  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    _disposed = true;
    if (!_disposeSignal.isCompleted) _disposeSignal.complete();
    final runFuture = _runTask ?? Future<void>.value();
    final closeFuture = _controller.close();
    return Future.wait<void>([runFuture, closeFuture]).then((_) {});
  }
}

/// Asset-based [DeckLoader] implementation for runtimes without file processes.
///
/// [load] returns a short stream that emits [DeckLoadingEvent] followed by
/// [DeckLoadedEvent] (on success) or [DeckErrorEvent] (on failure),
/// then closes. No build-status watching in bundled mode.
class BundledDeckLoader extends DeckLoader {
  BundledDeckLoader({required super.configuration});

  @override
  Stream<DeckEvent> load() async* {
    yield DeckLoadingEvent('Loading bundled deck…');
    try {
      final content = await rootBundle.loadString(
        configuration.bundledDeckJsonPath,
      );
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        throw Exception(
          'Expected JSON object in bundled deck at '
          '${configuration.bundledDeckJsonPath}, got ${decoded.runtimeType}',
        );
      }
      final data = Map<String, Object?>.from(decoded);
      yield DeckLoadedEvent(Deck.parse(data));
    } on Object catch (error) {
      yield DeckErrorEvent(
        'Superdeck reference error',
        error: _asException(error),
      );
    }
  }

  @override
  Future<void> dispose() => Future<void>.value();
}
