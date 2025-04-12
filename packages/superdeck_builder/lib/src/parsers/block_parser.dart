import 'package:superdeck_core/superdeck_core.dart';

import '../core/deck_format_exception.dart';
import '../utils/yaml_utils.dart';
import 'base_parser.dart';

class ParsedBlock {
  final String type;
  final int startIndex;
  final int endIndex;
  final Map<String, dynamic> _data;

  const ParsedBlock({
    required this.type,
    required Map<String, dynamic> data,
    required this.startIndex,
    required this.endIndex,
  }) : _data = data;

  Map<String, dynamic> get data {
    final keys = [
      SlideSection.key,
      MarkdownElement.key,
      ImageElement.key,
      DartPadBlock.key,
      CustomElement.key,
    ];

    return !keys.contains(type)
        ? {..._data, 'id': type, 'type': CustomElement.key}
        : {..._data, 'type': type};
  }
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
        data: options,
        startIndex: match.start,
        endIndex: match.end,
      );
    }).toList();
  }
}
