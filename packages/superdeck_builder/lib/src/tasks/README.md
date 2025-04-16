# SuperDeck Builder Tasks

This directory contains task implementations for the SuperDeck Builder package. Tasks are the core building blocks of the slide processing pipeline, performing operations like formatting code blocks, generating assets, and more.

## Organization

Tasks are organized by their primary function:

- **formatting/**: Tasks that format or transform content without generating external assets
  - `dart_formatter_task.dart`: Formats Dart code blocks in slides

- **generation/**: Tasks that generate assets or external files
  - `mermaid_task.dart`: Generates image assets from Mermaid diagram code blocks

## Task Interface

All tasks implement the `Task` abstract class from `core/task.dart`, which defines the following contract:

```dart
abstract class Task {
  final String name;
  final Map<String, dynamic> configuration;
  final bool canRunInParallel;

  Task(this.name, {this.configuration = const {}, this.canRunInParallel = false});

  FutureOr<void> run(TaskContext context);
  FutureOr<void> dispose() => Future.value();
}
```

## Adding New Tasks

To add a new task:

1. Identify the appropriate category based on the task's primary function
2. Create a new task file in the corresponding directory
3. Implement the `Task` abstract class
4. Add the task to the exports in `index.dart`
5. Register the task in the pipeline (typically in `superdeck_builder.dart`)

## Task Pipeline

Tasks are executed by the `TaskPipeline` in `core/task_pipeline.dart`. The pipeline:

1. Loads the deck's markdown content
2. Parses the content into individual slides
3. Executes all tasks for each slide
4. Performs cleanup operations if needed
5. Saves the processed slides

See the `TaskPipeline` class for more details on execution flow. 