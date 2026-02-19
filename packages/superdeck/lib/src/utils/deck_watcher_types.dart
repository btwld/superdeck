/// Status of the watcher lifecycle.
enum DeckWatcherStatus {
  /// Not started yet.
  idle,

  /// Initial setup is in progress.
  starting,

  /// Watcher is healthy and listening for changes.
  running,

  /// Last build failed.
  failed,

  /// Explicitly stopped via dispose().
  stopped,
}
