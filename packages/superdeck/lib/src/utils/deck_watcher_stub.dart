import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

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

/// No-op watcher for platforms that do not support runtime file watching.
class DeckWatcher {
  final DeckConfiguration configuration;

  final _status = signal<DeckWatcherStatus>(DeckWatcherStatus.idle);
  final _error = signal<Exception?>(null);
  final _isRebuilding = signal<bool>(false);
  final _lastBuildStatus = signal<String>('unsupported');
  final _lastBuildStatusPayload = signal<Map<String, dynamic>?>(null);

  bool _disposed = false;

  ReadonlySignal<DeckWatcherStatus> get status => _status;
  ReadonlySignal<Exception?> get error => _error;
  ReadonlySignal<bool> get isRebuilding => _isRebuilding;
  ReadonlySignal<String> get lastBuildStatus => _lastBuildStatus;

  Map<String, dynamic>? get lastBuildStatusPayload {
    final payload = _lastBuildStatusPayload.value;
    if (payload == null) return null;
    return Map<String, dynamic>.unmodifiable(payload);
  }

  DeckWatcher({required this.configuration});

  Future<void> start() async {
    if (_disposed) return;

    _status.value = DeckWatcherStatus.failed;
    _error.value = Exception(
      'Runtime watch mode is not available on this platform.',
    );
    _lastBuildStatusPayload.value = {
      'status': 'unsupported',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _status.value = DeckWatcherStatus.stopped;

    _status.dispose();
    _error.dispose();
    _isRebuilding.dispose();
    _lastBuildStatus.dispose();
    _lastBuildStatusPayload.dispose();
  }
}
