import 'dart:async';
import 'dart:io';

class FileWatcher {
  final File file;
  StreamSubscription<FileSystemEvent>? _subscription;
  bool _isProcessing = false;

  FileWatcher(this.file);

  /// Returns a stream of file change events.
  ///
  /// Emits an event each time the file is modified. Events are throttled to prevent
  /// multiple emissions during a single file save operation.
  Stream<void> watch() {
    final directory = file.parent;
    StreamSubscription<FileSystemEvent>? subscription;
    Timer? debounceTimer;

    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        subscription = directory.watch(events: FileSystemEvent.modify).listen((
          event,
        ) {
          final eventPath = event.path.replaceFirst('./', '');
          final targetPath = file.path.replaceFirst('./', '');

          if (eventPath == targetPath && !_isProcessing) {
            _isProcessing = true;
            controller.add(null);
            // Use cancelable Timer instead of Future.delayed
            debounceTimer?.cancel();
            debounceTimer = Timer(const Duration(milliseconds: 100), () {
              _isProcessing = false;
            });
          }
        });
      },
      onCancel: () async {
        debounceTimer?.cancel();
        debounceTimer = null;
        await subscription?.cancel();
        subscription = null;
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
    );

    return controller.stream;
  }

  /// Starts watching the file for changes using native file system events.
  /// Calls [onFileChange] whenever the file changes.
  void startWatching(FutureOr<void> Function() onFileChange) {
    // Watch the parent directory for changes to this specific file
    final directory = file.parent;

    _subscription = directory.watch(events: FileSystemEvent.modify).listen((
      event,
    ) async {
      if (_isProcessing) return;

      // Check if this event is for our target file
      // Normalize paths to handle cases like "./slides.md" vs "slides.md"
      final eventPath = event.path.replaceFirst('./', '');
      final targetPath = file.path.replaceFirst('./', '');

      if (eventPath == targetPath) {
        await _runOnFileChange(onFileChange);
      }
    });
  }

  /// Stops watching the file.
  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Checks if the watcher is currently active.
  bool get isWatching => _subscription != null;

  /// Runs the provided [onFileChange] callback, managing _isProcessing state and error handling.
  Future<void> _runOnFileChange(FutureOr<void> Function() onFileChange) async {
    _isProcessing = true;
    try {
      await onFileChange();
    } finally {
      _isProcessing = false;
    }
  }
}
