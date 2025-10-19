import 'dart:async';

import '../dart_code_utils.dart';
import '../markdown_utils.dart';
import 'slide_context.dart';
import 'task.dart';

/// Processes and formats Dart code blocks in slides
final class DartFormatterTask extends Task {
  final Map<String, String>? _environmentOverrides;

  DartFormatterTask({
    Map<String, String>? environmentOverrides,
    Map<String, dynamic> configuration = const {},
  }) : _environmentOverrides = environmentOverrides,
       super('dart_formatter', configuration: configuration);

  @override
  Future<void> run(SlideContext context) async {
    final lineLength = configuration['lineLength'] as int?;
    final fix = configuration['fix'] as bool? ?? true;

    logger.info('DartFormatterTask: Processing slide ${context.slideIndex}');

    try {
      final updatedContent = await processFencedCodeBlocks(
        context.slide.content,
        filter: (block) => block.language == 'dart',
        transform: (block) async {
          logger.info(
            'Formatting dart block at indices ${block.startIndex}-${block.endIndex} for slide ${context.slideIndex}',
          );

          try {
            final formattedCode = await formatDartCode(
              block.content,
              lineLength: lineLength,
              fix: fix,
              environmentOverrides: _environmentOverrides,
            );

            logger.info('Formatted dart block for slide ${context.slideIndex}');

            return '```dart\n$formattedCode\n```';
          } catch (e) {
            logger.severe('Failed to format Dart code: $e');
            // Return null to skip this block on error
            return null;
          }
        },
      );

      context.slide = context.slide.copyWith(content: updatedContent);
    } catch (e) {
      logger.severe(
        'Failed to process Dart formatting for slide ${context.slideIndex}: $e',
      );
      rethrow;
    }
  }
}
