import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Converts between an editor Markdown document and the canonical slide model.
class DeckMarkdownCodec {
  const DeckMarkdownCodec();

  /// Parses [markdown] with the same pipeline used by the live preview loader.
  List<Slide> decode(String markdown) {
    try {
      final rawSlides = const MarkdownParser().parse(markdown);

      return [
        for (final raw in rawSlides)
          Slide(
            key: raw.key,
            options: SlideOptions.parse(raw.frontmatter),
            sections: const SectionParser().parse(raw.content),
            comments: const CommentParser().parse(raw.content),
          ),
      ];
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        DeckFormatException(
          'Failed to decode deck Markdown: $error',
          markdown,
          null,
        ),
        stackTrace,
      );
    }
  }

  /// Serializes [slides] to canonical SuperDeck Markdown.
  String encode(List<Slide> slides) =>
      const SlideSerializer().serialize(slides);
}
