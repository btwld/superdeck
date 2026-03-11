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

  var _controller = StreamController<DeckEvent>();
  var _cancelSignal = Completer<void>();
  Future<void>? _runTask;
  var _disposed = false;

  File get _deckFile => configuration.deckJson;
  File get _statusFile => configuration.buildStatusJson;
  Directory get _statusParentDir => _statusFile.parent;
  Directory get _projectDir => Directory(configuration.projectDir ?? '.');

  bool _isCycleActive(
    StreamController<DeckEvent> ctrl,
    Completer<void> cancel,
  ) =>
      !_disposed && !ctrl.isClosed && !cancel.isCompleted;

  Future<void> _processStatus(StreamController<DeckEvent> ctrl, Completer<void> cancel) async {
    if (!await _statusFile.exists()) return;

    try {
      final decoded = jsonDecode(await _statusFile.readAsString());
      if (decoded is! Map) return;
      final status = DeckBuildStatus.fromMap(
        Map<String, dynamic>.from(decoded),
      );

      if (!_isCycleActive(ctrl, cancel)) return;

      switch (status.phase) {
        case DeckBuildPhase.building:
          ctrl.add(DeckRebuildingEvent());
        case DeckBuildPhase.failure:
          final message = status.error?.message ?? 'Deck build failed';
          ctrl.add(DeckErrorEvent(message, error: Exception(message)));
        case DeckBuildPhase.success:
          try {
            final deckJson = jsonDecode(await _deckFile.readAsString());
            if (deckJson is! Map) {
              throw Exception(
                'Expected JSON object at ${_deckFile.path}, '
                'got ${deckJson.runtimeType}',
              );
            }
            if (_isCycleActive(ctrl, cancel)) {
              ctrl.add(
                DeckLoadedEvent(
                  Deck.parse(Map<String, Object?>.from(deckJson)),
                ),
              );
            }
          } on Object catch (error) {
            if (_isCycleActive(ctrl, cancel)) {
              ctrl.add(
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
      if (_isCycleActive(ctrl, cancel)) {
        ctrl.add(
          DeckErrorEvent('Build status error', error: _asException(error)),
        );
      }
    }
  }

  /// Waits for the status parent directory to be created.
  Future<void> _waitForDirectoryCreation(Completer<void> cancel) async {
    if (_disposed || cancel.isCompleted || await _statusParentDir.exists()) {
      return;
    }

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
      await Future.any<void>([wait.future, cancel.future]);
    } on FileSystemException {
      // Directory may not exist yet
    } finally {
      await sub?.cancel();
    }
  }

  /// Waits for the status file to change using [FileWatcher].
  ///
  /// Returns `true` if a change was detected, `false` if cancelled.
  Future<bool> _waitForStatusChange(Completer<void> cancel) async {
    final watcher = FileWatcher(
      _statusFile,
      events: FileSystemEvent.create | FileSystemEvent.modify,
    );

    final changed = Completer<void>();
    final sub = watcher.watch().listen((_) {
      if (!changed.isCompleted) changed.complete();
    });

    try {
      await Future.any<void>([changed.future, cancel.future]);
      return changed.isCompleted;
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _run(StreamController<DeckEvent> ctrl, Completer<void> cancel) async {
    if (_isCycleActive(ctrl, cancel)) {
      ctrl.add(DeckLoadingEvent('Loading deck…'));
    }

    while (_isCycleActive(ctrl, cancel)) {
      if (!await _statusParentDir.exists()) {
        await _waitForDirectoryCreation(cancel);
        continue;
      }

      await _processStatus(ctrl, cancel);
      if (!_isCycleActive(ctrl, cancel)) return;

      final changed = await _waitForStatusChange(cancel);
      if (!changed) return;
    }
  }

  @override
  Stream<DeckEvent> load() {
    if (_disposed) return _controller.stream;

    // Abort any in-flight _run() cycle.
    if (_runTask != null) {
      if (!_cancelSignal.isCompleted) _cancelSignal.complete();
      _controller.close();
      _cancelSignal = Completer<void>();
      _controller = StreamController<DeckEvent>();
      _runTask = null;
    }

    final ctrl = _controller;
    final cancel = _cancelSignal;
    _runTask = _run(ctrl, cancel).catchError((Object error) {
      if (_isCycleActive(ctrl, cancel)) {
        ctrl.add(
          DeckErrorEvent('Build status error', error: _asException(error)),
        );
      }
    });

    return _controller.stream;
  }

  @override
  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    _disposed = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
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
