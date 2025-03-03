import 'dart:convert';

import 'parsers/front_matter_parser.dart';
import 'package:superdeck_core/superdeck_core.dart';

class RawSlideMarkdown {
  final String key;
  String content;
  final Map<String, dynamic> frontmatter;

  RawSlideMarkdown({
    required this.key,
    required this.content,
    required this.frontmatter,
  });
}

/// Responsible for splitting the entire markdown into separate slides,
/// extracting front matter, and capturing comments.
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

  List<RawSlideMarkdown> parse(String markdown) {
    final rawSlides = _splitSlides(markdown);

    final slides = <RawSlideMarkdown>[];

    final frontMatterExtractor = FrontmatterParser();

    for (final rawSlide in rawSlides) {
      final frontmatter = frontMatterExtractor.parse(rawSlide);

      slides.add(
        RawSlideMarkdown(
          key: generateValueHash(rawSlide),
          content: (frontmatter.contents ?? '').trim(),
          frontmatter: frontmatter.frontmatter,
        ),
      );
    }

    return slides;
  }
}
