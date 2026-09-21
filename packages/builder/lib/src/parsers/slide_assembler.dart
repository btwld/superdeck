import 'package:superdeck_core/superdeck_core.dart';

import 'comment_parser.dart';
import 'markdown_parser.dart';
import 'section_parser.dart';

/// Builds slide models from deck Markdown.
///
/// This is the whole of stage 1 and 2 parsing: split the document into slides,
/// read each slide's front matter into options, and parse its content into
/// sections and comments. The CLI build and the editor's preview codec both
/// call it, so a deck cannot parse one way on disk and another way on screen.
///
/// Callers add their own concerns around it: the build applies its plugins,
/// and the editor wraps failures in a [DeckFormatException] it can show.
///
/// Throws [FormatException] for front matter that is recognized but invalid.
List<Slide> assembleSlides(String markdown) {
  return [
    for (final raw in const MarkdownParser().parse(markdown))
      Slide(
        key: raw.key,
        options: SlideOptions.parse(raw.frontmatter),
        sections: const SectionParser().parse(raw.content),
        comments: const CommentParser().parse(raw.content),
      ),
  ];
}
