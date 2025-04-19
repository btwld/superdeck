/// Custom exception for errors that occur during task execution.
class BuilderTaskException implements Exception {
  /// Name of the task where the error occurred.
  final String taskName;

  /// The original exception that was thrown.
  final Exception originalException;

  /// Index of the slide being processed when the error occurred.
  final int slideIndex;

  const BuilderTaskException(
      this.taskName, this.originalException, this.slideIndex);

  @override
  String toString() {
    return 'Error in task "$taskName" at slide index $slideIndex: $originalException';
  }
}

/// Exception for errors related to the builder pipeline.
class BuilderPipelineException implements Exception {
  /// Description of what caused the error.
  final String message;

  /// The original exception that was thrown, if any.
  final Exception? originalException;

  const BuilderPipelineException(this.message, [this.originalException]);

  @override
  String toString() {
    if (originalException != null) {
      return 'Builder pipeline error: $message (Caused by: $originalException)';
    }
    return 'Builder pipeline error: $message';
  }
}
