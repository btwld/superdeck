import 'dart:async';
import 'dart:io';

class FileWatcher {
  final File file;
  Timer? _timer;
  DateTime? _lastModified;
  bool _isProcessing = false;

  // Extracted polling interval as a constant for clarity and easy modification.
  static const _pollingInterval = Duration(milliseconds: 500);

  FileWatcher(this.file);

  /// Starts watching the file for changes. Calls [onFileChange] whenever the file changes.
  void startWatching(FutureOr<void> Function() onFileChange) {
    _timer = Timer.periodic(_pollingInterval, (_) async {
      if (_isProcessing) return;

      // Check if the file has actually changed since last time
      if (await _fileHasChanged()) {
        await _runOnFileChange(onFileChange);
      }
    });
  }

  /// Stops watching the file.
  void stopWatching() {
    _timer?.cancel();
    _timer = null;
  }

  /// Checks if the watcher is currently active.
  bool get isWatching => _timer?.isActive ?? false;

  /// Determines if the file has changed since the last recorded timestamp.
  Future<bool> _fileHasChanged() async {
    final currentLastModified = await file.lastModified();
    // If this is the first check, we establish a baseline and do not treat it as a change.
    if (_lastModified == null) {
      _lastModified = currentLastModified;
      return false;
    }

    final changed = currentLastModified != _lastModified;
    _lastModified = currentLastModified;
    return changed;
  }

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
