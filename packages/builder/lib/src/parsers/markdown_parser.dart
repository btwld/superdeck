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

  /// Any mapping entry, including quoted and non-identifier keys.
  ///
  /// Only accepted once [_yamlKeyPattern] has opened the block, so prose that
  /// happens to contain a colon cannot pass as YAML on its own.
  static final _yamlEntryPattern = RegExp(r'^\S.*?:(\s|$)');

  /// A block sequence item, with or without a value on the same line.
  static final _yamlListItemPattern = RegExp(r'^-(\s|$)');

  /// Leading characters that mark a line as markdown body (heading, directive,
  /// blockquote, image/link) and therefore rule out YAML frontmatter.
  static const _markdownLeadChars = {'#', '@', '>', '!'};

  /// Splits the entire markdown into slides.
  ///
  /// A slide is bounded by `---` separator lines. A slide may begin with an
  /// optional YAML frontmatter block delimited by a `---` pair at its start.
  /// Fenced code (backtick or tilde, including info strings) is decided by
  /// [fencedCodeLines], so `---` inside a fence is never a separator.
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
    final fenced = fencedCodeLines(lines.join('\n'));
    final separators = <int>{};

    for (var i = 0; i < lines.length; i++) {
      if (!fenced.contains(i) && lines[i].trim() == '---') separators.add(i);
    }

    return separators;
  }

  /// If [openIdx] opens a YAML frontmatter block, returns the index of the
  /// closing `---`. Returns null when no closing `---` is found, or when the
  /// lines between look like markdown content rather than YAML.
  ///
  /// Every line has to belong to a mapping. The first non-blank line opens the
  /// block with an unquoted key; after that, indented lines continue a value,
  /// and a non-indented line has to be another mapping entry or a sequence
  /// item. A bullet list on its own, or any prose line, is slide content.
  static int? _findFrontmatterClose(
    List<String> lines,
    int openIdx,
    Set<int> separators,
  ) {
    var hasKeyLine = false;
    for (var j = openIdx + 1; j < lines.length; j++) {
      // An empty pair (`---\n---`) is a valid (empty) frontmatter block.
      if (separators.contains(j)) return j;

      final line = lines[j];
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Distinctive markdown body indicators rule out frontmatter.
      if (_markdownLeadChars.contains(trimmed[0])) return null;
      if (_yamlKeyPattern.hasMatch(trimmed)) {
        hasKeyLine = true;
        continue;
      }
      // Nothing else can open the block.
      if (!hasKeyLine) return null;
      final isIndented = line.startsWith(' ') || line.startsWith('\t');
      if (isIndented ||
          _yamlListItemPattern.hasMatch(trimmed) ||
          _yamlEntryPattern.hasMatch(trimmed)) {
        continue;
      }

      return null;
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
