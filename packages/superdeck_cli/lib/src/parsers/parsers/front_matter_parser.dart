import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/logger.dart';
import 'base_parser.dart';

typedef ExtractedFrontmatter = ({
  Map<String, dynamic> frontmatter,
  String? contents,
});

typedef FrontMatter = ({String markdown, String yaml});

/// Parses frontmatter from markdown content
FrontMatter parseFrontMatter(String input) {
  const delimiter = '---';

  input = input.trimLeft();
  if (!input.startsWith(delimiter)) {
    // No YAML front matter, entire content is markdown
    return (yaml: '', markdown: input);
  }

  // Special case: just "---" by itself
  if (input.trim() == delimiter) {
    return (yaml: '', markdown: '');
  }

  // Special case: "---\n---" (empty front matter)
  final emptyFrontMatterRegex =
      RegExp(r'^---\s*\n---\s*\n([\s\S]*)$', multiLine: true);
  final emptyMatch = emptyFrontMatterRegex.firstMatch(input);
  if (emptyMatch != null) {
    return (yaml: '', markdown: emptyMatch.group(1)?.trim() ?? '');
  }

  // Special case: single delimiter with content
  final singleDelimiterRegex = RegExp(r'^---\s*\n([\s\S]*)$', multiLine: true);
  final singleMatch = singleDelimiterRegex.firstMatch(input);
  if (singleMatch != null && !input.substring(3).contains('\n---')) {
    return (yaml: '', markdown: singleMatch.group(1)?.trim() ?? '');
  }

  // Remove the initial delimiter
  input = input.substring(delimiter.length).trimLeft();

  final endIndex = input.indexOf('\n$delimiter');
  if (endIndex == -1) {
    // This should not throw an exception anymore since we handle special cases above
    return (yaml: '', markdown: input.trim());
  }

  final yamlPart = input.substring(0, endIndex).trim();
  final markdownPart = input.substring(endIndex + delimiter.length + 1).trim();

  return (yaml: yamlPart, markdown: markdownPart);
}

/// Parser for frontmatter in markdown files
class FrontmatterParser extends BaseParser<ExtractedFrontmatter> {
  const FrontmatterParser();

  @override
  ExtractedFrontmatter parse(String content) {
    final result = parseFrontMatter(content);

    final yamlString = result.yaml;
    final markdownContent = result.markdown;
    Map<String, dynamic> yamlMap = {};

    try {
      yamlMap = YamlUtils.convertYamlToMap(yamlString);
    } catch (e) {
      logger.err('Cannot parse yaml frontmatter: $e');
      yamlMap = {};
    }

    return (frontmatter: yamlMap, contents: markdownContent);
  }
}
