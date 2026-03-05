import 'package:superdeck_core/superdeck_core.dart';

// ```<language> {<key1>: <value1>, <key2>: <value2>, ...}
// <code content>
// ```

// Data class to hold code block details
class ParsedFencedCode {
  final Map<String, Object?> options;
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

class FencedCodeParser {
  const FencedCodeParser();

  List<ParsedFencedCode> parse(String text) {
    final parsedBlocks = <ParsedFencedCode>[];

    String? activeFence;
    String? openingLine;
    int? startIndex;
    final blockContent = <String>[];

    var offset = 0;
    while (offset < text.length) {
      final newlineIndex = text.indexOf('\n', offset);
      final lineEnd = newlineIndex == -1 ? text.length : newlineIndex;
      final line = text.substring(offset, lineEnd);

      final fence = parseCodeFenceLine(line);
      if (activeFence == null) {
        if (fence != null) {
          activeFence = fence.marker;
          openingLine = fence.rest;
          startIndex = offset;
          blockContent.clear();
        }
      } else if (fence != null &&
          canCloseCodeFence(
            marker: activeFence,
            minLength: activeFence.length,
            line: line,
          )) {
        final endIndex = lineEnd;
        final header = _parseFenceHeader(openingLine!);
        final optionsMap = _parseFenceOptions(
          options: header.options,
          startIndex: startIndex!,
          endIndex: endIndex,
          language: header.language,
        );

        parsedBlocks.add(
          ParsedFencedCode(
            options: optionsMap,
            language: header.language,
            content: blockContent.join('\n').trim(),
            startIndex: startIndex,
            endIndex: endIndex,
          ),
        );

        activeFence = null;
        openingLine = null;
        startIndex = null;
      } else {
        blockContent.add(line);
      }

      if (newlineIndex == -1) {
        break;
      }
      offset = lineEnd + 1;
    }

    return parsedBlocks;
  }

  ({String language, String options}) _parseFenceHeader(String openingLine) {
    final firstLine = openingLine.trim();
    final spaceIndex = firstLine.indexOf(' ');

    if (spaceIndex == -1) {
      return (language: firstLine, options: '');
    }

    return (
      language: firstLine.substring(0, spaceIndex),
      options: firstLine.substring(spaceIndex + 1).trim(),
    );
  }

  Map<String, Object?> _parseFenceOptions({
    required String options,
    required int startIndex,
    required int endIndex,
    required String language,
  }) {
    if (options.isEmpty) return {};

    try {
      return convertYamlToMap(options, strict: true);
    } catch (e) {
      throw Exception(
        'Failed to parse options for code block at position '
        '$startIndex-$endIndex. Language: $language. Options: "$options". '
        'Error: $e',
      );
    }
  }
}

/// Extension methods for lists of ParsedFencedCode
extension ParsedFencedCodeListX on List<ParsedFencedCode> {
  /// Sorts blocks by startIndex in descending order.
  ///
  /// This is useful when replacing multiple blocks in content, as processing
  /// from end to beginning prevents index shifting issues.
  List<ParsedFencedCode> sortedForReplacement() {
    return toList()..sort((a, b) => b.startIndex.compareTo(a.startIndex));
  }
}
