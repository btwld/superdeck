library superdeck_builder;

export 'src/core/deck_format_exception.dart';
// Add exports for exception classes
export 'src/core/task_exception.dart';
export 'src/generator_pipeline.dart';
export 'src/tasks/formatting/dart_formatter_task.dart';
export 'src/tasks/generation/mermaid_task.dart';
// Commented out task not exported
// export 'src/tasks/image_caching_task.dart';

// Add additional exports for clarity
export 'src/tasks/index.dart'; // This already exports the tasks properly
