import 'dart:async';

import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// A [DeckLoader] that parses markdown in-memory for live preview.
class MemoryDeckLoader extends DeckLoader {
  final _controller = StreamController<SlidesEvent>.broadcast();
  bool _disposed = false;

  @override
  Stream<SlidesEvent> load() => _controller.stream;

  /// Parses the given markdown and emits a [SlidesLoadedEvent].
  void updateMarkdown(String markdown) {
    if (_disposed) return;

    try {
      final rawSlides = const MarkdownParser().parse(markdown);
      final slides = [
        for (final raw in rawSlides)
          Slide(
            key: raw.key,
            options: .parse(raw.frontmatter),
            sections: const SectionParser().parse(raw.content),
            comments: const CommentParser().parse(raw.content),
          ),
      ];
      _controller.add(SlidesLoadedEvent(slides));
    } catch (e) {
      _controller.add(SlidesErrorEvent('$e', error: e));
    }
  }

  @override
  Future<void> reload() async {}

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _controller.close();
  }
}
