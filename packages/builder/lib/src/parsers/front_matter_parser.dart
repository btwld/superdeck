import 'package:yaml/yaml.dart';

typedef ExtractedFrontmatter = ({
  Map<String, Object?> frontmatter,
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
    return (
      frontmatter: _parseFrontmatterYaml(result.yaml),
      contents: result.markdown,
    );
  }

  Map<String, Object?> _parseFrontmatterYaml(String yamlString) {
    if (yamlString.isEmpty) return {};

    try {
      final yamlDoc = loadYaml(yamlString);
      if (yamlDoc == null) {
        return {};
      }
      if (yamlDoc is! YamlMap) {
        throw FormatException(
          'Frontmatter must be a YAML map. Received: ${yamlDoc.runtimeType}',
        );
      }
      return _toPlainMap(yamlDoc);
    } catch (e) {
      throw FormatException(
        'Invalid YAML frontmatter in slide. '
        'Check for syntax errors in your slide configuration. '
        'Error: $e',
      );
    }
  }

  Map<String, Object?> _toPlainMap(YamlMap yamlMap) {
    return Map<String, Object?>.fromEntries(
      yamlMap.entries.map(
        (entry) => MapEntry(entry.key.toString(), _toPlainValue(entry.value)),
      ),
    );
  }

  Object? _toPlainValue(Object? value) {
    if (value is YamlMap) return _toPlainMap(value);
    if (value is YamlList) {
      return value.map(_toPlainValue).toList();
    }
    return value;
  }
}
