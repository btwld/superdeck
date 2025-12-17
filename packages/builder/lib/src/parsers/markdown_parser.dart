import 'dart:convert';

import 'package:superdeck_core/superdeck_core.dart';

import 'front_matter_parser.dart';
import 'raw_slide_schema.dart';

/// Stage 1 of 2-stage build-time parsing: Splits presentation markdown into individual slides.
///
/// Splits raw markdown by frontmatter delimiters (---), treating each section as
/// a separate slide. This is build-time processing specific to presentation structure,
/// not standard markdown parsing.
///
/// Markdown content rendering (headings, lists, code blocks) is handled at
/// runtime by flutter_markdown_plus, not during the build phase.
///
/// See also:
/// - [SectionParser] - Stage 2: Parses @section/@column directives into layout structure
class MarkdownParser {
  const MarkdownParser();

  /// Splits the entire markdown into slides.
  ///
  /// A "slide" is defined by frontmatter sections delimited with `---`.
  /// Code blocks (fenced by ```) are respected, so `---` inside a code block
  /// won't be treated as frontmatter delimiters.
  static List<String> _splitSlides(String content) {
    content = content.trim();
    final lines = LineSplitter().convert(content);
    final slides = <String>[];
    final buffer = StringBuffer();
    bool insideFrontMatter = false;

    var isCodeBlock = false;

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        isCodeBlock = !isCodeBlock;
      }
      if (isCodeBlock) {
        buffer.writeln(line);
        continue;
      }

      if (insideFrontMatter && trimmed.isEmpty) {
        insideFrontMatter = false;
      }

      if (trimmed == '---') {
        if (!insideFrontMatter) {
          if (buffer.isNotEmpty) {
            slides.add(buffer.toString().trim());
            buffer.clear();
          }
        }
        insideFrontMatter = !insideFrontMatter;
      }
      buffer.writeln(line);
    }

    if (buffer.isNotEmpty) {
      slides.add(buffer.toString());
    }

    return slides;
  }

  List<RawSlideMarkdownType> parse(String markdown) {
    final rawSlides = _splitSlides(markdown);

    final slides = <RawSlideMarkdownType>[];

    final frontMatterExtractor = FrontmatterParser();

    for (final rawSlide in rawSlides) {
      final frontmatter = frontMatterExtractor.parse(rawSlide);

      final slideData = {
        'key': generateValueHash(rawSlide),
        'content': (frontmatter.contents ?? '').trim(),
        'frontmatter': frontmatter.frontmatter,
      };

      slides.add(RawSlideMarkdownType.parse(slideData));
    }

    return slides;
  }
}
