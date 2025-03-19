/// Main export file for superdeck_builder library
library superdeck_builder;

import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/src/core/task_pipeline.dart';
import 'package:superdeck_builder/src/services/browser_service.dart';
import 'package:superdeck_builder/src/services/dart_process_service.dart';
import 'package:superdeck_builder/src/tasks/dart_formatter_task.dart';
import 'package:superdeck_builder/src/tasks/mermaid_task.dart';

// Export parsers
export 'src/parsers/base_parser.dart';
export 'src/parsers/block_parser.dart';
export 'src/parsers/comment_parser.dart';
export 'src/parsers/fenced_code_parser.dart';
export 'src/parsers/front_matter_parser.dart';
export 'src/parsers/markdown_parser.dart';
export 'src/parsers/section_parser.dart';
export 'src/parsers/string_option_parser.dart';
// Export utilities
export 'src/utils/yaml_utils.dart';

TaskPipeline getDefaultPipeline(
  DeckConfiguration configuration,
  FileSystemPresentationRepository store,
) {
  return TaskPipeline(
    tasks: [
      DartFormatterTask(processService: DartProcessService()),
      MermaidConverterTask(browserService: BrowserService()),
    ],
    configuration: configuration,
    store: store,
  );
}
