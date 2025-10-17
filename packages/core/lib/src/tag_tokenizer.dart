import 'package:yaml/yaml.dart';

import 'deck_format_exception.dart';
import 'utils/yaml_utils.dart';

class TagToken {
  final String name;
  final Map<String, dynamic> options;
  final String? rawOptions;
  final int startIndex;
  final int endIndex;
  final int? optionsStartIndex;
  final int? optionsEndIndex;

  const TagToken({
    required this.name,
    required this.options,
    this.rawOptions,
    required this.startIndex,
    required this.endIndex,
    this.optionsStartIndex,
    this.optionsEndIndex,
  });
}

class TagTokenizer {
  const TagTokenizer();

  static final _tagPattern = RegExp(r'^\s*@([\w-]+)', multiLine: true);
  static final _codeBlockPattern = RegExp(r'^```.*?^```', multiLine: true, dotAll: true);

  List<TagToken> tokenize(String text) {
    // Find all code block ranges to exclude from tag matching
    final codeBlockRanges = <_Range>[];
    for (final match in _codeBlockPattern.allMatches(text)) {
      codeBlockRanges.add(_Range(match.start, match.end));
    }

    final tokens = <TagToken>[];

    for (final match in _tagPattern.allMatches(text)) {
      final tagName = match.group(1)!;
      final startIndex = match.start;

      // Skip if this match is inside a code block
      if (_isInsideCodeBlock(startIndex, codeBlockRanges)) {
        continue;
      }

      final optionsStart = _skipWhitespace(text, match.end);

      if (optionsStart < text.length && text[optionsStart] == '{') {
        final extraction = _extractBalancedBraces(
          text,
          optionsStart,
          tagName,
        );

        final inner = extraction.body;
        final innerStart = extraction.openIndex + 1;

        final optionsMap = _parseOptions(
          inner,
          tagName,
          text,
          innerStart,
        );

        tokens.add(
          TagToken(
            name: tagName,
            options: optionsMap,
            rawOptions: inner,
            startIndex: startIndex,
            endIndex: extraction.endIndex,
            optionsStartIndex: extraction.openIndex,
            optionsEndIndex: extraction.endIndex,
          ),
        );
      } else {
        tokens.add(
          TagToken(
            name: tagName,
            options: const {},
            startIndex: startIndex,
            endIndex: match.end,
          ),
        );
      }
    }

    return tokens;
  }

  int _skipWhitespace(String text, int index) {
    var i = index;
    while (i < text.length) {
      final char = text[i];
      if (char != ' ' && char != '\t' && char != '\n' && char != '\r') {
        break;
      }
      i++;
    }
    return i;
  }

  _BraceExtraction _extractBalancedBraces(
    String text,
    int braceStart,
    String tagName,
  ) {
    var depth = 0;
    var inString = false;
    String? stringDelimiter;

    for (var i = braceStart; i < text.length; i++) {
      final char = text[i];
      final previous = i > 0 ? text[i - 1] : '';

      if ((char == '"' || char == "'") && previous != '\\') {
        if (!inString) {
          inString = true;
          stringDelimiter = char;
        } else if (char == stringDelimiter) {
          inString = false;
          stringDelimiter = null;
        }
        continue;
      }

      if (inString) continue;

      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return _BraceExtraction(
            openIndex: braceStart,
            closeIndex: i,
            body: text.substring(braceStart + 1, i),
          );
        }
      }
    }

    throw DeckFormatException(
      'Unclosed braces in @$tagName options',
      text,
      braceStart,
    );
  }

  Map<String, dynamic> _parseOptions(
    String rawInner,
    String tagName,
    String source,
    int innerStartIndex,
  ) {
    if (rawInner.trim().isEmpty) return const {};

    try {
      return convertYamlToMap(rawInner, strict: true);
    } on YamlException catch (e) {
      final span = e.span;
      final offset =
          span != null ? innerStartIndex + span.start.offset : innerStartIndex;
      throw DeckFormatException(
        'Invalid options for @$tagName: ${e.message}',
        source,
        offset,
      );
    } on FormatException catch (e) {
      throw DeckFormatException(
        'Invalid options for @$tagName: ${e.message}',
        source,
        innerStartIndex,
      );
    }
  }

  bool _isInsideCodeBlock(int position, List<_Range> codeBlockRanges) {
    for (final range in codeBlockRanges) {
      if (position >= range.start && position < range.end) {
        return true;
      }
    }
    return false;
  }
}

class _BraceExtraction {
  final int openIndex;
  final int closeIndex;
  final String body;

  const _BraceExtraction({
    required this.openIndex,
    required this.closeIndex,
    required this.body,
  });

  int get endIndex => closeIndex + 1;
}

class _Range {
  final int start;
  final int end;

  const _Range(this.start, this.end);
}
