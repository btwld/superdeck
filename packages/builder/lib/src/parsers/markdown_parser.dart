import 'dart:convert';

import 'package:superdeck_core/superdeck_core.dart';

import 'front_matter_parser.dart';
import 'raw_slide_schema.dart';

String _uniquifyKey(
  String baseKey,
  Set<String> usedKeys, {
  String separator = '__',
}) {
  if (!usedKeys.contains(baseKey)) return baseKey;
  var suffix = 2;
  while (true) {
    final candidate = '$baseKey$separator$suffix';
    if (!usedKeys.contains(candidate)) return candidate;
    suffix++;
  }
}

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
/// - [SectionParser] - Stage 2: Parses @section/@block directives into layout structure
class MarkdownParser {
  const MarkdownParser();

  static final _yamlKeyPattern = RegExp(r'^[A-Za-z_][\w-]*\s*:');

  /// Leading characters that mark a line as markdown body (heading, directive,
  /// blockquote, image/link) and therefore rule out YAML frontmatter.
  static const _markdownLeadChars = {'#', '@', '>', '!'};

  /// Splits the entire markdown into slides.
  ///
  /// A slide is bounded by `---` separator lines. A slide may begin with an
  /// optional YAML frontmatter block delimited by a `---` pair at its start.
  /// Fenced code (backtick or tilde, including info strings) is decided by
  /// [fencedCodeRanges], so `---` inside a fence is never a separator.
  static List<String> _splitSlides(String content) {
    content = content.trim();
    if (content.isEmpty) return [];

    final lines = LineSplitter().convert(content);
    final separators = _findSeparatorLines(lines);

    final slides = <String>[];
    final buffer = StringBuffer();

    void flush() {
      final pending = buffer.toString().trim();
      if (pending.isNotEmpty) slides.add(pending);
      buffer.clear();
    }

    var i = 0;
    while (i < lines.length) {
      if (!separators.contains(i)) {
        buffer.writeln(lines[i]);
        i++;
        continue;
      }

      flush();
      final closeIdx = _findFrontmatterClose(lines, i, separators);
      if (closeIdx == null) {
        i++;
        continue;
      }

      // Consume the frontmatter block (open `---`, YAML body, close `---`).
      for (var j = i; j <= closeIdx; j++) {
        buffer.writeln(lines[j]);
      }
      i = closeIdx + 1;
    }

    flush();
    return slides;
  }

  /// Returns the indices of `---` lines that sit outside fenced code blocks.
  static Set<int> _findSeparatorLines(List<String> lines) {
    final text = lines.join('\n');
    final fences = fencedCodeRanges(text);
    final separators = <int>{};
    var offset = 0;

    for (var i = 0; i < lines.length; i++) {
      if (!isInsideFencedCode(offset, fences) && lines[i].trim() == '---') {
        separators.add(i);
      }
      offset += lines[i].length + 1;
    }

    return separators;
  }

  /// If [openIdx] opens a YAML frontmatter block, returns the index of the
  /// closing `---`. Returns null when no closing `---` is found, or when the
  /// lines between look like markdown content rather than YAML.
  static int? _findFrontmatterClose(
    List<String> lines,
    int openIdx,
    Set<int> separators,
  ) {
    var hasContent = false;
    var hasYamlMarker = false;
    for (var j = openIdx + 1; j < lines.length; j++) {
      if (separators.contains(j)) {
        // An empty pair (`---\n---`) is a valid (empty) frontmatter block.
        // Otherwise require at least one YAML-shaped line.
        return (!hasContent || hasYamlMarker) ? j : null;
      }
      final trimmed = lines[j].trim();
      if (trimmed.isEmpty) continue;
      // Distinctive markdown body indicators rule out frontmatter.
      if (_markdownLeadChars.contains(trimmed[0])) return null;
      hasContent = true;
      if (_yamlKeyPattern.hasMatch(trimmed) || trimmed.startsWith('- ')) {
        hasYamlMarker = true;
      }
    }
    // Reached EOF without a closing `---`.
    return null;
  }

  List<RawSlideMarkdown> parse(String markdown) {
    final rawSlides = _splitSlides(markdown);

    final slides = <RawSlideMarkdown>[];
    final usedKeys = <String>{};

    final frontMatterExtractor = FrontmatterParser();

    for (final rawSlide in rawSlides) {
      final frontmatter = frontMatterExtractor.parse(rawSlide);
      final baseKey = generateValueHash(rawSlide);
      final key = _uniquifyKey(baseKey, usedKeys);
      usedKeys.add(key);

      final slideData = {
        'key': key,
        'content': (frontmatter.contents ?? '').trim(),
        'frontmatter': frontmatter.frontmatter,
      };

      slides.add(RawSlideMarkdown.parse(slideData));
    }

    return slides;
  }
}
