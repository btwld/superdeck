import 'dart:async';
import 'dart:math' as math;

import '../utils/dart_code_utils.dart';
import '../utils/markdown_utils.dart';
import 'slide_context.dart';
import 'task.dart';

/// Processes and formats Dart code blocks in slides
final class DartFormatterTask extends Task {
  final Map<String, String>? _environmentOverrides;
  final int? _lineLength;
  final bool _fix;

  DartFormatterTask({
    Map<String, String>? environmentOverrides,
    int? lineLength,
    bool fix = true,
  }) : _environmentOverrides = environmentOverrides,
       _lineLength = lineLength,
       _fix = fix,
       super('dart_formatter');

  @override
  Future<void> run(SlideContext context) async {
    final updatedContent = await processFencedCodeBlocks(
      context.slide.content,
      filter: (block) => block.language == 'dart',
      transform: (block) async {
        try {
          final formattedCode = await formatDartCode(
            block.content,
            lineLength: _lineLength,
            fix: _fix,
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

    context.updateSlide(context.slide.copyWith(content: updatedContent));
  }
}
