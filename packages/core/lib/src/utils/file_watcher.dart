import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

class FileWatcher {
  final File file;
  final int events;
  bool _isProcessing = false;

  FileWatcher(this.file, {this.events = FileSystemEvent.modify});

  /// Returns a stream of file change events.
  ///
  /// Emits an event each time the file changes. Events are throttled to prevent
  /// multiple emissions during a single file save operation.
  Stream<void> watch() {
    final directory = file.parent;
    final targetPath = p.normalize(file.path);
    StreamSubscription<FileSystemEvent>? subscription;
    Timer? throttleTimer;

    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        subscription = directory.watch(events: events).listen(
          (event) {
            final eventPath = p.normalize(event.path);

            if (eventPath == targetPath && !_isProcessing) {
              _isProcessing = true;
              controller.add(null);
              throttleTimer?.cancel();
              throttleTimer = Timer(const Duration(milliseconds: 100), () {
                _isProcessing = false;
              });
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () async {
        throttleTimer?.cancel();
        throttleTimer = null;
        await subscription?.cancel();
        subscription = null;
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
    );

    return controller.stream;
  }
}
