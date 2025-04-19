import 'dart:async';

import '../parsers/fenced_code_parser.dart';
import '../pipeline/builder_context.dart';
import '../utils/process_utils.dart';
import 'task.dart';

class DartFormatterTask extends Task {
  final Map<String, dynamic> configuration;
  final Map<String, String>? _environmentOverrides;

  DartFormatterTask({
    Map<String, String>? environmentOverrides,
    this.configuration = const {},
  })  : _environmentOverrides = environmentOverrides,
        super('dart_formatter');

  @override
  Future<void> run(BuilderContext context) async {
    final lineLength = configuration['lineLength'] as int?;
    final fix = configuration['fix'] as bool? ?? true;

    final fencedCodeParser = const FencedCodeParser();
    final codeBlocks = fencedCodeParser.parse(context.slide.content);
    final dartBlocks = codeBlocks.where((e) => e.language == 'dart');

    for (final dartBlock in dartBlocks) {
      try {
        final formattedCode = await ProcessUtils.formatDartCode(
          dartBlock.content,
          lineLength: lineLength,
          fix: fix,
          environmentOverrides: _environmentOverrides,
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
