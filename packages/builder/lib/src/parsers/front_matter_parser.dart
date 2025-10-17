import 'dart:developer';

import 'package:superdeck_core/superdeck_core.dart';

typedef ExtractedFrontmatter = ({
  Map<String, dynamic> frontmatter,
  String? contents,
});

typedef FrontMatter = ({String markdown, String yaml});

/// Parses frontmatter from markdown content using line-based parsing
FrontMatter parseFrontMatter(String input) {
  const delimiter = '---';

  input = input.trimLeft();

  // No frontmatter at all
  if (!input.startsWith(delimiter)) {
    return (yaml: '', markdown: input);
  }

  // Split into lines for simple parsing
  final lines = input.split('\n');
  int? firstDelimiterLine;
  int? secondDelimiterLine;

  // Find delimiter positions
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() == delimiter) {
      if (firstDelimiterLine == null) {
        firstDelimiterLine = i;
      } else {
        secondDelimiterLine = i;
        break;
      }
    }
  }

  if (firstDelimiterLine == null) {
    return (yaml: '', markdown: input);
  }

  // No closing delimiter - treat everything after first delimiter as markdown
  if (secondDelimiterLine == null) {
    final markdownLines = lines.sublist(firstDelimiterLine + 1);
    return (yaml: '', markdown: markdownLines.join('\n').trim());
  }

  // Extract yaml (between delimiters) and markdown (after second delimiter)
  final yamlLines = lines.sublist(firstDelimiterLine + 1, secondDelimiterLine);
  final markdownLines = lines.sublist(secondDelimiterLine + 1);

  return (
    yaml: yamlLines.join('\n').trim(),
    markdown: markdownLines.join('\n').trim(),
  );
}

/// Parser for frontmatter in markdown files
class FrontmatterParser {
  const FrontmatterParser();

  ExtractedFrontmatter parse(String content) {
    final result = parseFrontMatter(content);

    final yamlString = result.yaml;
    final markdownContent = result.markdown;
    Map<String, dynamic> yamlMap = {};

    try {
      yamlMap = convertYamlToMap(yamlString);
    } catch (e) {
      log('Error parsing yaml: $e');
      yamlMap = {};
    }

    return (frontmatter: yamlMap, contents: markdownContent);
  }
}
