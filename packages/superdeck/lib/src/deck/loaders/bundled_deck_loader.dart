import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Asset-based [DeckLoader] implementation for runtimes without file processes.
///
/// [load] returns a stable stream that emits [SlidesLoadingEvent] followed by
/// [SlidesLoadedEvent] (on success) or [SlidesErrorEvent] (on failure).
/// [reload] replays that bundled load cycle without any file watching.
class BundledDeckLoader extends DeckLoader {
  final _controller = StreamController<SlidesEvent>();
  Future<void>? _loadTask;
  var _disposed = false;
  var _started = false;

  BundledDeckLoader({DeckWorkspace? workspace})
    : super(workspace: workspace ?? DeckWorkspace());

  Future<void> _emitLoad() async {
    if (_disposed || _controller.isClosed) return;

    _controller.add(SlidesLoadingEvent('Loading bundled slides…'));
    try {
      final content = await rootBundle.loadString(
        workspace.bundledDeckJsonPath,
      );
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        throw Exception(
          'Expected JSON array in bundled slides at '
          '${workspace.bundledDeckJsonPath}, got ${decoded.runtimeType}',
        );
      }
      if (_disposed || _controller.isClosed) return;

      _controller.add(SlidesLoadedEvent(parseSlidesContract(decoded)));
    } on Exception catch (error) {
      if (_disposed || _controller.isClosed) return;
      _controller.add(
        SlidesErrorEvent('Superdeck reference error', error: error),
      );
    } on Error catch (error) {
      // rootBundle.loadString throws FlutterError (an Error, not Exception)
      if (_disposed || _controller.isClosed) return;
      _controller.add(
        SlidesErrorEvent(
          'Superdeck reference error',
          error: Exception(error.toString()),
        ),
      );
    }
  }

  @override
  Stream<SlidesEvent> load() {
    if (_disposed) {
      return _controller.stream;
    }
    if (!_started) {
      _started = true;
      _loadTask = _emitLoad();
    }
    return _controller.stream;
  }

  @override
  Future<void> reload() async {
    if (_disposed) return;
    await (_loadTask ?? Future<void>.value());
    if (_disposed) return;
    _loadTask = _emitLoad();
    await _loadTask;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await (_loadTask ?? Future<void>.value());
    await _controller.close();
  }
}
