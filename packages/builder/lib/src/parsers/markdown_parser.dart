import 'dart:convert';

import 'package:superdeck_core/superdeck_core.dart';
import 'package:yaml/yaml.dart';

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
/// - [SectionParser] - Stage 2: Parses @section/@column directives into layout structure
class MarkdownParser {
  const MarkdownParser();

  static final _yamlMapKeyPattern = RegExp(
    r'''^(?:[A-Za-z_][A-Za-z0-9_-]*|"(?:[^"\\]|\\.)+"|'(?:[^'\\]|\\.)+')\s*:''',
  );

  /// Splits the entire markdown into slides.
  ///
  /// A slide boundary is any `---` outside of fenced code blocks.
  /// If a slide starts with a frontmatter block (`---` + YAML map + `---`),
  /// that pair is kept with the slide instead of creating extra boundaries.
  static List<String> _splitSlides(String content) {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return [];

    final lines = LineSplitter()
        .convert(trimmedContent)
        .map((line) => line.replaceAll('\r', ''))
        .toList();

    final slides = <String>[];
    final currentSlide = <String>[];
    String? activeFence;

    void flushCurrentSlide() {
      _appendSlide(currentSlide, slides);
      currentSlide.clear();
    }

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final fenceState = _processFenceLine(activeFence, line);
      activeFence = fenceState.activeFence;
      if (fenceState.isFenceLine) {
        currentSlide.add(line);
        continue;
      }

      if (activeFence == null && line.trim() == '---') {
        final candidateEndIndex = _findFrontMatterEnd(lines, index + 1);

        if (candidateEndIndex != null) {
          final candidateYaml = lines
              .sublist(index + 1, candidateEndIndex)
              .join('\n');

          if (_isFrontMatterCandidate(candidateYaml)) {
            if (currentSlide.isNotEmpty) {
              flushCurrentSlide();
            }

            for (var i = index; i <= candidateEndIndex; i++) {
              currentSlide.add(lines[i]);
            }
            index = candidateEndIndex;
            continue;
          }
        }

        flushCurrentSlide();
        continue;
      }

      currentSlide.add(line);
    }

    _appendSlide(currentSlide, slides);

    return slides;
  }

  static int? _findFrontMatterEnd(List<String> lines, int start) {
    String? activeFence;

    for (var i = start; i < lines.length; i++) {
      final line = lines[i];
      final fenceState = _processFenceLine(activeFence, line);
      activeFence = fenceState.activeFence;
      if (fenceState.isFenceLine) {
        continue;
      }

      if (activeFence == null && line.trim() == '---') {
        return i;
      }
    }

    return null;
  }

  static ({String? activeFence, bool isFenceLine}) _processFenceLine(
    String? activeFence,
    String line,
  ) {
    final fence = parseCodeFenceLine(line);
    if (fence == null) {
      return (activeFence: activeFence, isFenceLine: false);
    }
    if (activeFence == null) {
      return (activeFence: fence.marker, isFenceLine: true);
    }
    if (canCloseCodeFence(
      marker: activeFence,
      minLength: activeFence.length,
      line: line,
    )) {
      return (activeFence: null, isFenceLine: true);
    }
    return (activeFence: activeFence, isFenceLine: true);
  }

  static bool _isFrontMatterCandidate(String value) {
    final candidate = value.trim();
    if (candidate.isEmpty) return true;
    if (_startsWithDirective(candidate)) {
      return false;
    }

    try {
      final yaml = loadYaml(candidate);
      return yaml is YamlMap || yaml is YamlList;
    } on YamlException {
      return _looksLikeFrontMatterCandidate(candidate);
    } catch (_) {
      return false;
    }
  }

  static bool _looksLikeFrontMatterCandidate(String value) {
    var sawMapKey = false;
    for (final rawLine in value.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      if (_yamlMapKeyPattern.hasMatch(line)) {
        sawMapKey = true;
        continue;
      }

      // Allow continuation lines that could belong to multiline YAML values.
      if (rawLine.startsWith(' ') || rawLine.startsWith('\t')) {
        continue;
      }

      return false;
    }

    return sawMapKey;
  }

  static bool _startsWithDirective(String value) {
    for (final rawLine in value.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      return line.startsWith('@');
    }

    return false;
  }

  static void _appendSlide(List<String> lines, List<String> slides) {
    if (lines.isEmpty) return;

    final slideText = lines.join('\n').trim();
    if (slideText.isNotEmpty) {
      slides.add(slideText);
    }
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
