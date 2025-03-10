import 'package:superdeck_core/superdeck_core.dart';

import 'base_parser.dart';

final _codeFencePattern = RegExp(
  r'```(?<backtickInfo>[^`]*)[\s\S]*?```',
  multiLine: true,
);

// ```<language> {<key1>: <value1>, <key2>: <value2>, ...}
// <code content>
// ```

// Data class to hold code block details
class ParsedFencedCode {
  final Map<String, dynamic> options;
  final String language;
  final String content;
  // The first index of the opening fence
  final int startIndex;
  // The last index of the closing fence
  final int endIndex;

  const ParsedFencedCode({
    required this.options,
    required this.language,
    required this.content,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  String toString() {
    return 'ParsedCodeBlock(language: $language, content: $content, startIndex: $startIndex, endIndex: $endIndex)';
  }
}

class FencedCodeParser extends BaseParser<List<ParsedFencedCode>> {
  const FencedCodeParser();

  @override
  List<ParsedFencedCode> parse(String text) {
    final matches = _codeFencePattern.allMatches(text);
    List<ParsedFencedCode> parsedBlocks = [];

    for (final match in matches) {
      final backtickInfo = match.namedGroup('backtickInfo');

      final lines = backtickInfo?.split('\n');
      final firstLine = lines?.first ?? '';
      final rest = lines?.sublist(1).join('\n') ?? '';

      final language = firstLine.split(' ')[0];
      final options = firstLine.replaceFirst(language, '').trim();

      final content = rest;

      final startIndex = match.start;
      final endIndex = match.end;

      final Map<String, dynamic> optionsMap =
          options.isNotEmpty ? YamlUtils.convertYamlToMap(options) : {};

      parsedBlocks.add(
        ParsedFencedCode(
          options: optionsMap,
          language: language,
          content: content.trim(),
          startIndex: startIndex,
          endIndex: endIndex,
        ),
      );
    }

    return parsedBlocks;
  }
}
