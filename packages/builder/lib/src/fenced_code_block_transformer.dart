import 'package:superdeck_builder/src/parsers/fenced_code_parser.dart';

/// Lightweight utility for transforming fenced code blocks in markdown content.
///
/// This utility encapsulates the common pattern of:
/// 1. Parsing fenced code blocks from markdown
/// 2. Filtering blocks based on criteria
/// 3. Transforming matching blocks
/// 4. Replacing blocks in reverse order to prevent index shifting
///
/// This is a stateless utility with an injectable parser for testability.
/// It provides the shared algorithm for block-based content transformation.
///
/// ## Example Usage
///
/// ```dart
/// final transformer = const FencedCodeBlockTransformer();
///
/// final updated = await transformer.processBlocks(
///   content,
///   filter: (block) => block.language == 'dart',
///   transform: (block) async {
///     final formatted = await formatCode(block.content);
///     return '```dart\n$formatted\n```';
///   },
/// );
/// ```
class FencedCodeBlockTransformer {
  final FencedCodeParser _parser;

  const FencedCodeBlockTransformer({
    FencedCodeParser parser = const FencedCodeParser(),
  }) : _parser = parser;

  /// Transforms all code blocks in content that match the filter.
  ///
  /// The [filter] function determines which blocks to transform.
  /// The [transform] function is called for each matching block and should
  /// return the replacement text, or null to skip the block.
  ///
  /// Blocks are processed in reverse order (end to beginning) to prevent
  /// index shifting issues during replacement.
  ///
  /// Returns the updated content with transformed blocks replaced.
  Future<String> processBlocks(
    String content, {
    required bool Function(ParsedFencedCode block) filter,
    required Future<String?> Function(ParsedFencedCode block) transform,
  }) async {
    // Parse all fenced code blocks
    final blocks = _parser.parse(content);

    // Filter blocks based on criteria
    final matchingBlocks = blocks.where(filter).toList();

    // Sort for safe replacement (end to beginning prevents index shifting)
    final sortedBlocks = matchingBlocks.sortedForReplacement();

    // Process each block and replace in content
    String result = content;
    for (final block in sortedBlocks) {
      final replacement = await transform(block);
      if (replacement != null) {
        result = result.replaceRange(
          block.startIndex,
          block.endIndex,
          replacement,
        );
      }
    }

    return result;
  }
}
