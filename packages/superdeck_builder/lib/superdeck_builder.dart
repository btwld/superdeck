/// Main export file for superdeck_builder library
library superdeck_builder;

import 'package:logging/logging.dart';
import 'package:superdeck_builder/src/core/task_pipeline.dart';
import 'package:superdeck_builder/src/services/browser_service.dart';
import 'package:superdeck_builder/src/tasks/dart_formatter_task.dart';
import 'package:superdeck_builder/src/tasks/mermaid_task.dart';
import 'package:superdeck_core/src/storage/asset_storage.dart'
    show DefaultAssetStorageFactory;
import 'package:superdeck_core/superdeck_core.dart';

// Export assets
export 'src/assets/export_assets.dart';
// Export core exceptions
export 'src/core/deck_format_exception.dart';
export 'src/core/task.dart';
export 'src/core/task_context.dart';
export 'src/core/task_exception.dart';
export 'src/core/task_metrics.dart';
export 'src/core/task_pipeline.dart';
// Export parsers
export 'src/parsers/base_parser.dart';
export 'src/parsers/block_parser.dart';
export 'src/parsers/comment_parser.dart';
export 'src/parsers/fenced_code_parser.dart';
export 'src/parsers/front_matter_parser.dart';
export 'src/parsers/markdown_parser.dart';
export 'src/parsers/section_parser.dart';
export 'src/parsers/string_option_parser.dart';
// Export services
export 'src/services/browser_service.dart';
export 'src/services/dart_process_service.dart';
export 'src/services/disposable.dart';
export 'src/services/http_client_service.dart';
// Export tasks
export 'src/tasks/dart_formatter_task.dart';
export 'src/tasks/mermaid_task.dart';
// Export utilities
export 'src/utils/file_utils.dart';
export 'src/utils/log_utils.dart';
export 'src/utils/process_utils.dart';
export 'src/utils/string_utils.dart';
export 'src/utils/yaml_utils.dart';

/// Creates the default TaskPipeline with standard tasks
TaskPipeline getDefaultPipeline(
  DeckConfiguration configuration,
  FileSystemPresentationRepository store,
) {
  final logger = Logger('SuperdeckBuilder');

  // Create asset storage using the factory
  final assetStorage = DefaultAssetStorageFactory.create(
    assetDirectory: configuration.assetsDir,
    isDevelopment: true, // Always use development mode for builder
    logger: (message) => logger.info(message),
  );

  // Create browser service with robust configuration
  final browserService = BrowserService(
    maxRetries: 3,
    retryDelay: const Duration(seconds: 2),
  );

  return TaskPipeline(
    tasks: [
      DartFormatterTask(),
      MermaidConverterTask(
        browserService: browserService,
        assetStorage: assetStorage,
      ),
    ],
    configuration: configuration,
    store: store,
  );
}
