/// Metrics for a task execution
class TaskMetrics {
  final String taskName;
  final int slideIndex;
  final Duration duration;
  final bool success;
  final String? errorMessage;

  TaskMetrics({
    required this.taskName,
    required this.slideIndex,
    required this.duration,
    this.success = true,
    this.errorMessage,
  });

  @override
  String toString() {
    final status = success ? 'Success' : 'Failed';
    final error = errorMessage != null ? ' Error: $errorMessage' : '';
    return 'Task $taskName on slide $slideIndex: $status, Duration: ${duration.inMilliseconds}ms$error';
  }
}
