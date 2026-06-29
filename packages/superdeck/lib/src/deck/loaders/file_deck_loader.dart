import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:superdeck_core/superdeck_core.dart';

import 'json_deck_loader_base.dart';

const missingBuildOutputMessage =
    'No SuperDeck build output found. '
    'SuperDeck uses the default workspace layout. '
    'Run `dart run superdeck_cli:main build --watch` in one terminal and '
    '`flutter run` in another.';

/// File-based [DeckLoader] implementation for debug IO runtimes.
///
/// [load] returns a long-lived stream:
/// 1. Emits [SlidesLoadingEvent].
/// 2. Emits all subsequent events from `build_status.json`.
class FileDeckLoader extends DeckLoader {
  final _controller = StreamController<SlidesEvent>();
  final DeckWorkspace workspace;
  var _cancelSignal = Completer<void>();
  Future<void>? _runTask;
  var _disposed = false;
  var _started = false;
  var _didEmitMissingBuildOutput = false;
  Future<void>? _disposeTask;

  FileDeckLoader({DeckWorkspace? workspace})
    : workspace = workspace ?? DeckWorkspace();

  File get _deckFile => workspace.deckJson;
  File get _statusFile => workspace.buildStatusJson;
  Directory get _statusParentDir => _statusFile.parent;

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

  void _emitMissingBuildOutput(Completer<void> cancel) {
    if (_didEmitMissingBuildOutput) return;
    _didEmitMissingBuildOutput = true;
    _emit(SlidesErrorEvent(missingBuildOutputMessage), cancel);
  }

  Future<void> _emitLoadedSlides(Completer<void> cancel) async {
    try {
      final content = await _deckFile.readAsString();
      _didEmitMissingBuildOutput = false;
      _emit(decodeSlidesEvent(content, _deckFile.path), cancel);
    } on Exception catch (error) {
      _emit(wrapReferenceError(error), cancel);
    }
  }

  Future<String?> _readStatusSnapshot() async {
    if (!await _statusFile.exists()) return null;
    return _statusFile.readAsString();
  }

  Future<void> _processStatus(Completer<void> cancel) async {
    if (!await _statusFile.exists()) {
      _emitMissingBuildOutput(cancel);
      return;
    }

    try {
      final decoded = jsonDecode(await _statusFile.readAsString());
      if (decoded is! Map) {
        _emit(
          SlidesErrorEvent(
            'Build status error',
            error: Exception(
              'Expected JSON object in ${_statusFile.path}, '
              'got ${decoded.runtimeType}',
            ),
          ),
          cancel,
        );
        return;
      }
      final status = DeckBuildStatus.fromMap(
        Map<String, dynamic>.from(decoded),
      );

      if (!_isCycleActive(cancel)) return;

      switch (status.phase) {
        case DeckBuildPhase.building:
          _didEmitMissingBuildOutput = false;
          _emit(SlidesRebuildingEvent(), cancel);
          return;
        case DeckBuildPhase.failure:
          _didEmitMissingBuildOutput = false;
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
          _emitMissingBuildOutput(cancel);
          return;
      }
    } on Exception catch (error) {
      _emit(SlidesErrorEvent('Build status error', error: error), cancel);
    }
  }

  /// Waits for the status parent directory to be created.
  Future<void> _waitForDirectoryCreation(Completer<void> cancel) async {
    while (_isCycleActive(cancel) && !await _statusParentDir.exists()) {
      await Future.any<void>([
        Future<void>.delayed(const Duration(milliseconds: 50)),
        cancel.future,
      ]);
    }
  }

  /// Waits for the status file to change using [FileWatcher].
  ///
  /// Returns `true` if a change was detected, `false` if cancelled.
  Future<bool> _waitForStatusChange(
    Completer<void> cancel, {
    required String? statusAtStart,
  }) async {
    while (_isCycleActive(cancel)) {
      final contentNow = await _readStatusSnapshot();
      if (contentNow != statusAtStart) {
        return true;
      }

      await Future.any<void>([
        Future<void>.delayed(const Duration(milliseconds: 50)),
        cancel.future,
      ]);
    }

    return false;
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
    _didEmitMissingBuildOutput = false;
    _emit(SlidesLoadingEvent('Loading slides…'), cancel);

    while (_isCycleActive(cancel)) {
      if (!await _statusParentDir.exists()) {
        _emitMissingBuildOutput(cancel);
        await _waitForDirectoryCreation(cancel);
        continue;
      }

      final statusAtStart = await _readStatusSnapshot();
      await _processStatus(cancel);
      if (!_isCycleActive(cancel)) return;

      final changed = await _waitForStatusChange(
        cancel,
        statusAtStart: statusAtStart,
      );
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
  Future<void> dispose() {
    return _disposeTask ??= _dispose();
  }

  Future<void> _dispose() async {
    if (_disposed) return Future<void>.value();
    _disposed = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
    await (_runTask ?? Future<void>.value());
    await _controller.close();
  }
}
