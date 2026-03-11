import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

/// File-based [DeckLoader] implementation for debug IO runtimes.
///
/// [load] returns a long-lived stream:
/// 1. Emits [DeckLoadingEvent].
/// 2. Emits all subsequent events from `build_status.json`.
class FileDeckLoader extends DeckLoader {
  FileDeckLoader({required super.configuration});

  static const _referenceErrorMessage = 'Superdeck reference error';
  static const _buildStatusErrorMessage = 'Build status error';

  late final _controller = StreamController<DeckEvent>(
    onListen: _onListen,
    onCancel: _stopSession,
  );

  Completer<void>? _sessionCancelSignal;
  Future<void>? _runTask;
  var _disposed = false;

  File get _deckFile => configuration.deckJson;
  File get _statusFile => configuration.buildStatusJson;
  Directory get _statusParentDir => _statusFile.parent;
  Directory get _projectDir => Directory(configuration.projectDir ?? '.');

  bool _isActive(Completer<void> cancelSignal) {
    return !_disposed && !cancelSignal.isCompleted && !_controller.isClosed;
  }

  Exception _toException(Object error) {
    return error is Exception ? error : Exception(error.toString());
  }

  void _emitError({
    required Completer<void> cancelSignal,
    required String message,
    required Object error,
  }) {
    if (_isActive(cancelSignal)) {
      _controller.add(DeckErrorEvent(message, error: _toException(error)));
    }
  }

  void _onListen() {
    if (_disposed || _runTask != null) return;

    final cancelSignal = Completer<void>();
    _sessionCancelSignal = cancelSignal;

    _runTask = _run(cancelSignal)
        .catchError((Object error) {
          _emitError(
            cancelSignal: cancelSignal,
            message: _buildStatusErrorMessage,
            error: error,
          );
        })
        .whenComplete(() {
          if (identical(_sessionCancelSignal, cancelSignal)) {
            _sessionCancelSignal = null;
          }
          _runTask = null;
        });
  }

  Future<void> _stopSession() async {
    final cancelSignal = _sessionCancelSignal;
    if (cancelSignal != null && !cancelSignal.isCompleted) {
      cancelSignal.complete();
    }

    final runTask = _runTask;
    if (runTask != null) {
      await runTask;
    }
  }

  Future<Deck> _readDeckReference() async {
    if (!await _deckFile.exists()) {
      throw Exception('Deck file not found at ${_deckFile.path}');
    }

    Object decoded;
    try {
      decoded = jsonDecode(await _deckFile.readAsString());
    } on Object catch (error) {
      throw Exception(
        'Failed to parse deck reference at ${_deckFile.path}: $error',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Expected JSON object at ${_deckFile.path}, got ${decoded.runtimeType}',
      );
    }

    try {
      return Deck.fromMap(decoded);
    } on Object catch (error) {
      throw Exception(
        'Failed to parse deck reference at ${_deckFile.path}: $error',
      );
    }
  }

  Future<DeckBuildStatus?> _readBuildStatus(
    Completer<void> cancelSignal,
  ) async {
    if (!await _statusFile.exists()) return null;

    try {
      final decoded = jsonDecode(await _statusFile.readAsString());
      return DeckBuildStatus.fromObject(decoded);
    } on Object catch (error) {
      _emitError(
        cancelSignal: cancelSignal,
        message: _buildStatusErrorMessage,
        error: error,
      );
      return null;
    }
  }

  Future<void> _emitDeckFromReference(Completer<void> cancelSignal) async {
    try {
      final deck = await _readDeckReference();
      if (_isActive(cancelSignal)) {
        _controller.add(DeckLoadedEvent(deck));
      }
    } on Object catch (error) {
      _emitError(
        cancelSignal: cancelSignal,
        message: _referenceErrorMessage,
        error: error,
      );
    }
  }

  Future<void> _emitEventsForStatus(
    Completer<void> cancelSignal,
    DeckBuildStatus status,
  ) async {
    if (!_isActive(cancelSignal)) return;

    switch (status.phase) {
      case DeckBuildPhase.building:
        _controller.add(DeckRebuildingEvent());
      case DeckBuildPhase.failure:
        final message = status.error?.message ?? 'Deck build failed';
        _controller.add(DeckErrorEvent(message, error: Exception(message)));
      case DeckBuildPhase.success:
        await _emitDeckFromReference(cancelSignal);
      case DeckBuildPhase.unknown:
        break;
    }
  }

  Future<void> _waitForDirectoryCreation(Completer<void> cancelSignal) async {
    if (cancelSignal.isCompleted || await _statusParentDir.exists()) return;

    final wait = Completer<void>();
    StreamSubscription<FileSystemEvent>? watch;
    try {
      watch = _projectDir
          .watch(events: FileSystemEvent.create, recursive: true)
          .listen(
            (_) async {
              if (cancelSignal.isCompleted || wait.isCompleted) return;
              if (await _statusParentDir.exists() && !wait.isCompleted) {
                wait.complete();
              }
            },
            onError: (_, __) {
              if (!wait.isCompleted) {
                wait.complete();
              }
            },
            onDone: () {
              if (!wait.isCompleted) {
                wait.complete();
              }
            },
          );

      if (await _statusParentDir.exists() && !wait.isCompleted) {
        wait.complete();
      }

      await Future.any<void>([wait.future, cancelSignal.future]);
    } finally {
      await watch?.cancel();
    }
  }

  Future<bool> _waitForStatusChange(Completer<void> cancelSignal) async {
    final wait = Completer<void>();
    final statusPath = p.normalize(_statusFile.path);
    var statusChanged = false;
    StreamSubscription<FileSystemEvent>? watch;

    try {
      watch = _statusParentDir
          .watch(events: FileSystemEvent.create | FileSystemEvent.modify)
          .listen(
            (event) {
              if (cancelSignal.isCompleted ||
                  p.normalize(event.path) != statusPath) {
                return;
              }

              statusChanged = true;
              if (!wait.isCompleted) {
                wait.complete();
              }
            },
            onError: (_, __) {
              if (!wait.isCompleted) {
                wait.complete();
              }
            },
            onDone: () {
              if (!wait.isCompleted) {
                wait.complete();
              }
            },
          );

      await Future.any<void>([wait.future, cancelSignal.future]);
      return statusChanged;
    } on FileSystemException {
      return false;
    } finally {
      await watch?.cancel();
    }
  }

  Future<void> _run(Completer<void> cancelSignal) async {
    if (_isActive(cancelSignal)) {
      _controller.add(DeckLoadingEvent('Loading deck…'));
    }

    var shouldReadStatus = true;

    while (_isActive(cancelSignal)) {
      if (!await _statusParentDir.exists()) {
        await _waitForDirectoryCreation(cancelSignal);
        shouldReadStatus = true;
        continue;
      }

      if (shouldReadStatus) {
        final status = await _readBuildStatus(cancelSignal);
        if (status != null) {
          await _emitEventsForStatus(cancelSignal, status);
        }
      }
      if (!_isActive(cancelSignal)) return;

      shouldReadStatus = await _waitForStatusChange(cancelSignal);
    }
  }

  @override
  Stream<DeckEvent> load() {
    return _controller.stream;
  }

  @override
  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    _disposed = true;
    final stopFuture = _stopSession();
    final closeFuture = _controller.close();
    return Future.wait<void>([stopFuture, closeFuture]).then((_) {});
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
      final data = jsonDecode(content) as Map<String, dynamic>;
      yield DeckLoadedEvent(Deck.fromMap(data));
    } on Object catch (error) {
      yield DeckErrorEvent(
        'Superdeck reference error',
        error: error is Exception ? error : Exception(error.toString()),
      );
    }
  }

  @override
  Future<void> dispose() => Future<void>.value();
}
