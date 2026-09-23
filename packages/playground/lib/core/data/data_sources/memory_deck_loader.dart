import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

import '../mappers/deck_markdown_codec.dart';

/// A [DeckLoader] that parses markdown in-memory for live preview.
class MemoryDeckLoader extends DeckLoader {
  /// Decodes markdown for the live in-memory preview.
  static const _codec = DeckMarkdownCodec();

  final _controller = StreamController<SlidesEvent>.broadcast();
  bool _disposed = false;
  bool _hasMarkdown = false;
  String? _lastLoadedMarkdown;
  List<Slide>? _loadedSlides;
  Object? _loadError;

  void _emitDecoded(String markdown) {
    try {
      final slides = _codec.decode(markdown);
      _loadedSlides = slides;
      _loadError = null;
      _controller.add(SlidesLoadedEvent(slides));
    } catch (error) {
      _loadedSlides = null;
      _loadError = error;
      _controller.add(SlidesErrorEvent('$error', error: error));
    }
  }

  /// Parses the given markdown and emits a [SlidesLoadedEvent].
  void updateMarkdown(String markdown) {
    if (_disposed || markdown == _lastLoadedMarkdown) return;
    _lastLoadedMarkdown = markdown;
    _hasMarkdown = true;
    _emitDecoded(markdown);
  }

  /// Re-emits the last terminal preview result.
  ///
  /// Identical text on [updateMarkdown] stays quiet; a reload repeats the
  /// result so a session waiting on it can leave loading.
  @override
  Future<void> reload() async {
    if (_disposed) return;
    if (!_hasMarkdown) {
      _controller.add(SlidesErrorEvent('No markdown has been supplied.'));
      await Future<void>.delayed(Duration.zero);

      return;
    }
    final error = _loadError;
    if (error != null) {
      _controller.add(SlidesErrorEvent('$error', error: error));
    } else {
      _controller.add(SlidesLoadedEvent(_loadedSlides ?? const []));
    }
    // Broadcast delivery is a later microtask. Stay incomplete until that
    // event has reached listeners, including a session waiting to leave
    // loading.
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Stream<SlidesEvent> load() => _controller.stream;

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _controller.close();
  }
}
