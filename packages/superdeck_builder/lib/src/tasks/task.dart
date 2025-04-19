import 'dart:async';

import 'package:logging/logging.dart';

import '../pipeline/builder_context.dart';

/// Abstract class representing a generic task in the slide processing pipeline.
/// Each concrete task should implement the [run] method to perform its specific operation.
abstract class Task {
  /// Name of the task, used for logging and identification.
  final String name;

  /// Logger instance for the task.
  late final Logger logger = Logger('Task: $name');

  Task(this.name);

  /// Executes the task using the provided [BuilderContext].
  FutureOr<void> run(BuilderContext context);

  /// Disposes of any resources held by the task.
  /// Override if the task holds resources that need explicit disposal.
  FutureOr<void> dispose() {
    return Future.value();
  }
}

/// Interface for tasks that need to perform cleanup operations after all slides are processed.
/// This is particularly useful for tasks that generate assets or temporary files.
abstract class CleanupCapableTask implements Task {
  /// Clean up any resources or unused assets after all slides have been processed.
  FutureOr<void> cleanup();
}
