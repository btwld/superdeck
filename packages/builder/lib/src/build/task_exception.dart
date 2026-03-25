class TaskException implements Exception {
  final String taskName;

  final Exception originalException;

  final int slideIndex;

  const TaskException(this.taskName, this.originalException, this.slideIndex);

  @override
  String toString() {
    return 'Error in task "$taskName" at slide index $slideIndex: $originalException';
  }
}
