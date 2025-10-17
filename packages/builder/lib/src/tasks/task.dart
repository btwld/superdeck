import 'dart:async';

import 'package:logging/logging.dart';

import 'slide_context.dart';

/// Base class representing a task in the slide processing builder.
/// Each concrete task should extend this class and implement the [run] method to perform its specific operation.
abstract base class Task {
  /// Name of the task, used for logging and identification.
  final String name;

  /// Configuration options for this task
  final Map<String, dynamic> configuration;

  /// Logger instance for the task.
  late final Logger logger = Logger('Task: $name');

  Task(
    this.name, {
    this.configuration = const {},
  });

  /// Executes the task using the provided [SlideContext].
  FutureOr<void> run(SlideContext context);

  /// Disposes of any resources held by the task.
  /// Override if the task holds resources that need explicit disposal.
  FutureOr<void> dispose() => Future.value();
}