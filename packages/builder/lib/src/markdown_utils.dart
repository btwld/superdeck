import 'package:superdeck_builder/src/parsers/fenced_code_parser.dart';

/// Transforms fenced code blocks in markdown content.
///
/// Parses all fenced code blocks, filters them based on the [filter] criteria,
/// and transforms matching blocks using the [transform] function.
///
/// The [transform] function should return the replacement text, or null to
/// skip the block. Blocks are processed in reverse order (end to beginning)
/// to prevent index shifting issues during replacement.
///
/// Returns the updated content with transformed blocks replaced.
///
/// ## Example
///
/// ```dart
/// final updated = await processFencedCodeBlocks(
///   content,
///   filter: (block) => block.language == 'dart',
///   transform: (block) async {
///     final formatted = await formatCode(block.content);
///     return '```dart\n$formatted\n```';
///   },
/// );
/// ```
Future<String> processFencedCodeBlocks(
  String content, {
  required bool Function(ParsedFencedCode block) filter,
  required Future<String?> Function(ParsedFencedCode block) transform,
  FencedCodeParser parser = const FencedCodeParser(),
}) async {
  // Parse all fenced code blocks
  final blocks = parser.parse(content);

  // Filter blocks based on criteria
  final matchingBlocks = blocks.where(filter).toList();

  // Sort in reverse order (end to beginning) to prevent index shifting
  final sortedBlocks = matchingBlocks.sortedForReplacement();

  // Process each block and replace in content
  String result = content;
  for (final block in sortedBlocks) {
    try {
      final replacement = await transform(block);
      if (replacement != null) {
        result = result.replaceRange(
          block.startIndex,
          block.endIndex,
          replacement,
        );
      }
    } catch (e) {
      final contentPreview = block.content.length > 200
          ? '${block.content.substring(0, 200)}...'
          : block.content;

      throw Exception(
        'Failed to transform fenced code block at position ${block.startIndex}-${block.endIndex}. '
        'Language: ${block.language}, Content length: ${block.content.length} chars. '
        'Content preview: "$contentPreview". '
        'Original error: $e',
      );
    }
  }

  return result;
}
