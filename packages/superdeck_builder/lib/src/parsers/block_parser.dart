import '../core/deck_format_exception.dart';
import '../utils/yaml_utils.dart';
import 'base_parser.dart';

class ParsedBlock {
  final String type;
  final int startIndex;
  final int endIndex;
  final Map<String, dynamic> options;

  const ParsedBlock({
    required this.type,
    required this.options,
    required this.startIndex,
    required this.endIndex,
  });
}

class BlockParser extends BaseParser<List<ParsedBlock>> {
  const BlockParser();

  @override
  List<ParsedBlock> parse(String text) {
    // @tag
    // @tag {key: value}
    // @tag{key: value, key2: value2}
    // @tag {key: value, key2: value2, key3: value3}
    // @tag{
    //   key: value
    //   key2: value2
    //   key3: value3
    // }

    // Get the "tag", which could be any word, and also maybe it does not have space
    final tagRegex = RegExp(r'^\s*@(\w+)(?:\s*{([^{}]*)})?', multiLine: true);

    final matches = tagRegex.allMatches(text);

    return matches.map((match) {
      final typeString = match.group(1) ?? '';
      final optionsString = match.group(2) ?? '';

      Map<String, dynamic> options;

      try {
        options = YamlUtils.convertYamlToMap(optionsString);
      } on Exception catch (e) {
        throw DeckFormatException(
          'Failed to parse tag blocks: $e',
          optionsString,
          match.start,
        );
      }

      return ParsedBlock(
        type: typeString,
        options: options,
        startIndex: match.start,
        endIndex: match.end,
      );
    }).toList();
  }
}
