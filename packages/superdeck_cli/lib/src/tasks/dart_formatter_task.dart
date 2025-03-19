import 'dart:async';

import 'package:superdeck/superdeck.dart';

import '../generator_pipeline.dart';
import '../helpers/dart_process.dart';

class DartFormatterTask extends Task {
  DartFormatterTask() : super('dart_formatter');

  @override
  Future<void> run(TaskContext context) async {
    final fencedCodeParser = const FencedCodeParser();
    final codeBlocks = fencedCodeParser.parse(context.slide.content);

    final dartBlocks = codeBlocks.where((e) => e.language == 'dart');

    for (final dartBlock in dartBlocks) {
      try {
        final formattedCode = await DartProcess.format(dartBlock.content);

        final updatedMarkdown = context.slide.content.replaceRange(
          dartBlock.startIndex,
          dartBlock.endIndex,
          '```dart\n$formattedCode\n```',
        );

        context.slide.content = updatedMarkdown;
      } catch (e) {
        logger.severe('Failed to format Dart code: $e');
      }
    }
  }
}
