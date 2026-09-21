import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Converts between a deck Markdown document and the canonical slide model.
class DeckMarkdownCodec {
  const DeckMarkdownCodec();

  /// Parses [markdown] with the same assembly the CLI build uses.
  List<Slide> decode(String markdown) {
    try {
      return assembleSlides(markdown);
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
