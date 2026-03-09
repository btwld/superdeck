import 'package:superdeck_core/superdeck_core.dart';

const unsupportedColumnDirectiveMessage =
    '`@column` is no longer supported. Use `@block` instead.';

class ParsedBlock {
  final String type;
  final int startIndex;
  final int endIndex;
  final Map<String, Object?> _data;

  const ParsedBlock({
    required this.type,
    required Map<String, Object?> data,
    required this.startIndex,
    required this.endIndex,
  }) : _data = data;

  Map<String, Object?> get data {
    return switch (type) {
      SectionBlock.key ||
      ContentBlock.key ||
      WidgetBlock.key => {..._data, 'type': type},
      _ => {..._data, 'name': type, 'type': WidgetBlock.key},
    };
  }
}

/// Parses build-time layout directives (@section, @block) with YAML-style options.
///
/// Extracts custom directives like:
/// - `@section` or `@section{flex: 1}`
/// - `@block{align: center, flex: 2}`
///
/// **Why regex instead of markdown package BlockSyntax?**
/// - These are build-time directives, not markdown syntax
/// - BlockSyntax operates at render-time; we need build-time extraction
/// - Regex is simpler, faster, and sufficient for these patterns
/// - Avoids markdown package dependency in builder layer
///
/// See also:
/// - [SectionParser] - Aggregates parsed blocks into section structure
class BlockParser {
  const BlockParser();

  List<ParsedBlock> parse(String text) {
    final tokens = const TagTokenizer().tokenize(text);

    for (final token in tokens) {
      if (token.name == 'column') {
        throw DeckFormatException(
          unsupportedColumnDirectiveMessage,
          text,
          token.startIndex,
        );
      }
    }

    return tokens
        .map(
          (token) => ParsedBlock(
            type: token.name,
            data: token.options,
            startIndex: token.startIndex,
            endIndex: token.endIndex,
          ),
        )
        .toList();
  }
}
