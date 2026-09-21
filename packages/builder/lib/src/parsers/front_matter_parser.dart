import 'package:superdeck_core/superdeck_core.dart';

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

  /// Reads the front matter block of one slide.
  ///
  /// [MarkdownParser] only keeps a block that is shaped like a YAML mapping,
  /// so a block that fails to parse, or that parses to anything other than a
  /// map, is a mistake in the slide rather than content. [parseYamlMap]
  /// reports both, naming the slide's front matter as the source.
  ExtractedFrontmatter parse(String content) {
    final result = parseFrontMatter(content);

    final yamlString = result.yaml;
    final markdownContent = result.markdown;
    // An empty block parses to no options, so the empty case needs no guard.
    final yamlMap = parseYamlMap(yamlString, sourceLabel: 'slide front matter');

    return (frontmatter: yamlMap, contents: markdownContent);
  }
}
