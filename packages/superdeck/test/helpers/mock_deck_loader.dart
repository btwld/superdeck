import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

import 'test_helpers.dart';

/// Reusable test double for [DeckLoader].
///
/// By default, auto-loads [createTestSlidesPayload] on [load]/[reload].
/// Call [disableAutoLoad] to emit events manually via [emitEvent]/[emitError].
class MockDeckLoader extends DeckLoader {
  final StreamController<SlidesEvent> _eventController =
      StreamController<SlidesEvent>.broadcast();
  final List<Slide> _slidesToReturn;

  bool _autoLoad = true;
  var _disposed = false;

  MockDeckLoader({List<Slide>? slides})
    : _slidesToReturn = slides ?? createTestSlidesPayload(),
      super();

  int loadCalls = 0;
  int reloadCalls = 0;

  @override
  Stream<SlidesEvent> load() {
    loadCalls++;
    _scheduleAutoLoad();
    return _eventController.stream;
  }

  @override
  Future<void> reload() async {
    reloadCalls++;
    _scheduleAutoLoad();
  }

  void _scheduleAutoLoad() {
    if (_autoLoad) {
      Future.microtask(() {
        _eventController.add(SlidesLoadingEvent('Loading…'));
        _eventController.add(SlidesLoadedEvent(_slidesToReturn));
      });
    }
  }

  /// Disable auto-loading so events must be emitted manually.
  void disableAutoLoad() {
    _autoLoad = false;
  }

  void emitEvent(SlidesEvent event) {
    _eventController.add(event);
  }

  void emitError(Object error, [StackTrace? stackTrace]) {
    _eventController.addError(error, stackTrace ?? StackTrace.current);
  }

  @override
  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    _disposed = true;
    return _eventController.close();
  }
}
