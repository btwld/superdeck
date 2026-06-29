import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Internal utility — not part of the stable 1.0 API surface. May change
/// without a major version bump.
class FileWatcher {
  final File file;
  final int events;
  bool _isProcessing = false;

  FileWatcher(this.file, {this.events = FileSystemEvent.modify});

  static const _pollInterval = Duration(milliseconds: 250);
  static const _throttleInterval = Duration(milliseconds: 100);

  /// Returns a stream of file change events.
  ///
  /// Emits an event each time the file changes. Events are throttled to prevent
  /// multiple emissions during a single file save operation. A polling fallback
  /// is kept active because native file watching is not reliable on every
  /// filesystem used by local and CI test environments.
  Stream<void> watch() {
    final directory = file.parent;
    final targetPath = p.normalize(file.path);
    StreamSubscription<FileSystemEvent>? subscription;
    Timer? throttleTimer;
    Timer? pollTimer;
    var lastSnapshot = _snapshot();

    late final StreamController<void> controller;
    void emitChange() {
      if (_isProcessing) return;

      _isProcessing = true;
      controller.add(null);
      throttleTimer?.cancel();
      throttleTimer = Timer(_throttleInterval, () {
        _isProcessing = false;
      });
    }

    controller = StreamController<void>(
      onListen: () {
        pollTimer = Timer.periodic(_pollInterval, (_) {
          final previousSnapshot = lastSnapshot;
          final currentSnapshot = _snapshot();
          if (currentSnapshot == previousSnapshot) return;

          lastSnapshot = currentSnapshot;
          if (_shouldEmitPolledChange(previousSnapshot, currentSnapshot)) {
            emitChange();
          }
        });
        subscription = directory
            .watch(events: events)
            .listen(
              (event) {
                final eventPath = p.normalize(event.path);

                if (eventPath == targetPath) {
                  lastSnapshot = _snapshot();
                  emitChange();
                }
              },
              onError: controller.addError,
              onDone: controller.close,
            );
      },
      onCancel: () async {
        throttleTimer?.cancel();
        throttleTimer = null;
        pollTimer?.cancel();
        pollTimer = null;
        await subscription?.cancel();
        subscription = null;
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
    );

    return controller.stream;
  }

  bool _hasEvent(int event) {
    return events & event != 0;
  }

  bool _shouldEmitPolledChange(
    ({int changed, int modified, int size})? previous,
    ({int changed, int modified, int size})? current,
  ) {
    if (previous == null && current == null) return false;
    if (previous == null) return _hasEvent(FileSystemEvent.create);
    if (current == null) return _hasEvent(FileSystemEvent.delete);

    return _hasEvent(FileSystemEvent.modify);
  }

  ({int changed, int modified, int size})? _snapshot() {
    final stat = file.statSync();
    if (stat.type == FileSystemEntityType.notFound) return null;

    return (
      changed: stat.changed.microsecondsSinceEpoch,
      modified: stat.modified.microsecondsSinceEpoch,
      size: stat.size,
    );
  }
}
