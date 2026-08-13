import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

import '../mappers/deck_markdown_codec.dart';

/// A [DeckLoader] that parses markdown in-memory for live preview.
class MemoryDeckLoader extends DeckLoader {
  /// Shared with the deck-edit tools so the preview and the tools can never
  /// decode the same markdown differently.
  static const _codec = DeckMarkdownCodec();

  final _controller = StreamController<SlidesEvent>.broadcast();
  bool _disposed = false;
  String? _lastLoadedMarkdown;

  /// Parses the given markdown and emits a [SlidesLoadedEvent].
  void updateMarkdown(String markdown) {
    if (_disposed || markdown == _lastLoadedMarkdown) return;
    _lastLoadedMarkdown = markdown;

    try {
      final slides = _codec.decode(markdown);
      _controller.add(SlidesLoadedEvent(slides));
    } catch (e) {
      _controller.add(SlidesErrorEvent('$e', error: e));
    }
  }

  @override
  Stream<SlidesEvent> load() => _controller.stream;

  @override
  Future<void> reload() async {}

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _controller.close();
  }
}
