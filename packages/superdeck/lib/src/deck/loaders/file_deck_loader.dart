import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:superdeck_core/superdeck_core.dart';

/// File-based [DeckLoader] implementation for debug IO runtimes.
///
/// [load] returns a long-lived stream:
/// 1. Emits [SlidesLoadingEvent].
/// 2. Emits all subsequent events from `build_status.json`.
class FileDeckLoader extends DeckLoader {
  final _controller = StreamController<SlidesEvent>();
  var _cancelSignal = Completer<void>();
  Future<void>? _runTask;
  var _disposed = false;
  var _started = false;

  FileDeckLoader({DeckConfiguration? configuration})
    : super(configuration: configuration ?? DeckConfiguration());

  File get _deckFile => configuration.deckJson;
  File get _statusFile => configuration.buildStatusJson;
  Directory get _statusParentDir => _statusFile.parent;
  Directory get _projectDir => configuration.projectDirectory;

  bool _isCycleActive(Completer<void> cancel) {
    return !_disposed &&
        !_controller.isClosed &&
        identical(cancel, _cancelSignal) &&
        !cancel.isCompleted;
  }

  void _emit(SlidesEvent event, Completer<void> cancel) {
    if (_isCycleActive(cancel)) {
      _controller.add(event);
    }
  }

  Future<void> _emitLoadedSlides(Completer<void> cancel) async {
    try {
      final slidesJson = jsonDecode(await _deckFile.readAsString());
      if (slidesJson is! List) {
        throw Exception(
          'Expected JSON array at ${_deckFile.path}, '
          'got ${slidesJson.runtimeType}',
        );
      }
      _emit(SlidesLoadedEvent(parseSlidesContract(slidesJson)), cancel);
    } on Exception catch (error) {
      _emit(
        SlidesErrorEvent('Superdeck reference error', error: error),
        cancel,
      );
    }
  }

  Future<void> _processStatus(Completer<void> cancel) async {
    if (!await _statusFile.exists()) return;

    try {
      final decoded = jsonDecode(await _statusFile.readAsString());
      if (decoded is! Map) return;
      final status = DeckBuildStatus.fromMap(
        Map<String, dynamic>.from(decoded),
      );

      if (!_isCycleActive(cancel)) return;

      switch (status.phase) {
        case DeckBuildPhase.building:
          _emit(SlidesRebuildingEvent(), cancel);
          return;
        case DeckBuildPhase.failure:
          final buildError =
              status.error ??
              const DeckBuildError(message: 'Presentation build failed');
          _emit(
            SlidesErrorEvent(buildError.message, error: buildError),
            cancel,
          );
          return;
        case DeckBuildPhase.success:
          await _emitLoadedSlides(cancel);
          return;
        case DeckBuildPhase.unknown:
          return;
      }
    } on Exception catch (error) {
      _emit(SlidesErrorEvent('Build status error', error: error), cancel);
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

  void _startCycle() {
    final cancel = _cancelSignal;
    _runTask = _run(cancel).catchError((Object error) {
      final exception = error is Exception
          ? error
          : Exception(error.toString());
      _emit(SlidesErrorEvent('Build status error', error: exception), cancel);
    });
  }

  Future<void> _restartCycle() async {
    if (!_cancelSignal.isCompleted) {
      _cancelSignal.complete();
    }

    final previousRunTask = _runTask;
    _runTask = null;
    if (previousRunTask != null) {
      await previousRunTask;
    }

    if (_disposed) return;

    _cancelSignal = Completer<void>();
    _startCycle();
  }

  Future<void> _run(Completer<void> cancel) async {
    _emit(SlidesLoadingEvent('Loading slides…'), cancel);

    while (_isCycleActive(cancel)) {
      if (!await _statusParentDir.exists()) {
        await _waitForDirectoryCreation(cancel);
        continue;
      }

      await _processStatus(cancel);
      if (!_isCycleActive(cancel)) return;

      final changed = await _waitForStatusChange(cancel);
      if (!changed) return;
    }
  }

  @override
  Stream<SlidesEvent> load() {
    if (_disposed) {
      return _controller.stream;
    }
    if (!_started) {
      _started = true;
      _startCycle();
    }

    return _controller.stream;
  }

  @override
  Future<void> reload() async {
    if (_disposed) return;
    if (!_started) {
      _started = true;
      _startCycle();
      return;
    }
    await _restartCycle();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return Future<void>.value();
    _disposed = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
    await (_runTask ?? Future<void>.value());
    await _controller.close();
  }
}
