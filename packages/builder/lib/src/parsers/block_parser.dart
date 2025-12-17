import 'package:superdeck_core/superdeck_core.dart';

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
    // Normalize 'block' tag to 'column' for backward compatibility
    final normalizedType = type == 'block' ? ContentBlock.key : type;

    return switch (normalizedType) {
      SectionBlock.key ||
      ContentBlock.key ||
      WidgetBlock.key => {..._data, 'type': normalizedType},
      _ => {..._data, 'name': type, 'type': WidgetBlock.key},
    };
  }
}

/// Parses build-time layout directives (@section, @column, @block) with YAML-style options.
///
/// Extracts custom directives like:
/// - `@section` or `@section{flex: 1}`
/// - `@column{align: center, flex: 2}` or `@block{align: center, flex: 2}`
///
/// Both `@column` and `@block` tags create [ContentBlock] instances.
/// The `@block` tag is legacy and normalized to `@column` for backward compatibility.
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
