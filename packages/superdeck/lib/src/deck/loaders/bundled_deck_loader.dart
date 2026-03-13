import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Asset-based [DeckLoader] implementation for runtimes without file processes.
///
/// [load] returns a stable stream that emits [DeckLoadingEvent] followed by
/// [DeckLoadedEvent] (on success) or [DeckErrorEvent] (on failure).
/// [reload] replays that bundled load cycle without any file watching.
class BundledDeckLoader extends DeckLoader {
  final _controller = StreamController<DeckEvent>();
  Future<void>? _loadTask;
  var _disposed = false;
  var _started = false;

  BundledDeckLoader({required super.configuration});

  Future<void> _emitLoad() async {
    if (_disposed || _controller.isClosed) return;

    _controller.add(DeckLoadingEvent('Loading bundled deck…'));
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
      if (_disposed || _controller.isClosed) return;

      final data = Map<String, Object?>.from(decoded);
      _controller.add(DeckLoadedEvent(Deck.parse(data)));
    } on Exception catch (error) {
      if (_disposed || _controller.isClosed) return;
      _controller.add(
        DeckErrorEvent('Superdeck reference error', error: error),
      );
    } on Error catch (error) {
      // rootBundle.loadString throws FlutterError (an Error, not Exception)
      if (_disposed || _controller.isClosed) return;
      _controller.add(
        DeckErrorEvent(
          'Superdeck reference error',
          error: Exception(error.toString()),
        ),
      );
    }
  }

  @override
  Stream<DeckEvent> load() {
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
