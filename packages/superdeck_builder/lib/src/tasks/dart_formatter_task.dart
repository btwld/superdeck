import 'dart:async';

import 'package:superdeck_builder/src/parsers/fenced_code_parser.dart';

import '../core/task.dart';
import '../core/task_context.dart';
import '../services/dart_process_service.dart';

class DartFormatterTask extends Task {
  final DartProcessService _processService;

  DartFormatterTask({
    required DartProcessService processService,
    Map<String, dynamic> configuration = const {},
  })  : _processService = processService,
        super('dart_formatter',
            configuration: configuration, canRunInParallel: true);

  @override
  Future<void> run(TaskContext context) async {
    final lineLength = configuration['lineLength'] as int?;
    final fix = configuration['fix'] as bool? ?? true;

    final fencedCodeParser = const FencedCodeParser();
    final codeBlocks = fencedCodeParser.parse(context.slide.content);
    final dartBlocks = codeBlocks.where((e) => e.language == 'dart');

    for (final dartBlock in dartBlocks) {
      try {
        final formattedCode = await _processService.format(
          dartBlock.content,
          lineLength: lineLength,
          fix: fix,
        );

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
