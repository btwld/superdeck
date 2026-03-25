import 'dart:async';
import 'dart:math' as math;

import '../utils/dart_code_utils.dart';
import '../utils/markdown_utils.dart';
import 'slide_context.dart';
import 'task.dart';

/// Processes and formats Dart code blocks in slides
final class DartFormatterTask extends Task {
  final Map<String, String>? _environmentOverrides;

  DartFormatterTask({
    Map<String, String>? environmentOverrides,
    Map<String, Object?> configuration = const {},
  }) : _environmentOverrides = environmentOverrides,
       super('dart_formatter', configuration: configuration);

  @override
  Future<void> run(SlideContext context) async {
    final lineLength = configuration['lineLength'] as int?;
    final fix = configuration['fix'] as bool? ?? true;

    final updatedContent = await processFencedCodeBlocks(
      context.slide.content,
      filter: (block) => block.language == 'dart',
      transform: (block) async {
        try {
          final formattedCode = await formatDartCode(
            block.content,
            lineLength: lineLength,
            fix: fix,
            environmentOverrides: _environmentOverrides,
          );

          return '```dart\n$formattedCode\n```';
        } catch (e, stackTrace) {
          final codePreview = block.content.length > 100
              ? '${block.content.substring(0, math.min(100, block.content.length))}...'
              : block.content;

          logger.severe(
            'Failed to format Dart code block for slide ${context.slideIndex}. '
            'Code preview: "$codePreview". '
            'Error: $e',
            e,
            stackTrace,
          );

          logger.warning(
            'Skipping unformatted Dart code block on slide ${context.slideIndex}. '
            'Fix syntax errors and rebuild.',
          );
          // Return null to skip this block on error
          return null;
        }
      },
    );

    context.slide = context.slide.copyWith(content: updatedContent);
  }
}
