import 'dart:async';

import 'package:logging/logging.dart';

import 'task_context.dart';

/// Abstract class representing a task in the slide processing pipeline.
/// Each concrete task should implement the [run] method to perform its specific operation.
abstract class Task {
  /// Name of the task, used for logging and identification.
  final String name;

  /// Configuration options for this task
  final Map<String, dynamic> configuration;

  /// Whether this task can run in parallel with other tasks for the same slide
  final bool canRunInParallel;

  /// Logger instance for the task.
  late final Logger logger = Logger('Task: $name');

  Task(
    this.name, {
    this.configuration = const {},
    this.canRunInParallel = false,
  });

  /// Executes the task using the provided [TaskContext].
  FutureOr<void> run(TaskContext context);

  /// Disposes of any resources held by the task.
  /// Override if the task holds resources that need explicit disposal.
  FutureOr<void> dispose() => Future.value();
}
