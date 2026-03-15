// Main export file for superdeck_builder.
// Export assets
export 'src/assets/asset_generation_pipeline.dart';
export 'src/assets/asset_generator.dart';
export 'src/assets/mermaid_generator.dart';
// Export build
export 'src/build/build_event.dart';
export 'src/build/deck_builder.dart';
export 'src/build/slide_processor.dart';
export 'src/build/task_exception.dart';
// Export core exceptions
export 'package:superdeck_core/superdeck_core.dart' show DeckFormatException;
// Export parsers
export 'src/parsers/block_parser.dart';
export 'src/parsers/comment_parser.dart';
export 'src/parsers/fenced_code_parser.dart';
export 'src/parsers/front_matter_parser.dart';
export 'src/parsers/markdown_parser.dart';
export 'src/parsers/section_parser.dart';
// Export tasks
export 'src/tasks/asset_generation_task.dart';
export 'src/tasks/dart_formatter_task.dart';
export 'src/tasks/slide_context.dart';
export 'src/tasks/task.dart';
// Export utilities
export 'src/utils/markdown_utils.dart';
