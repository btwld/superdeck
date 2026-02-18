import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'deck_watcher_types.dart';

/// No-op watcher for platforms that do not support runtime file watching.
class DeckWatcher {
  final DeckConfiguration configuration;

  final _status = signal<DeckWatcherStatus>(DeckWatcherStatus.idle);
  final _error = signal<Object?>(null);
  final _isRebuilding = signal<bool>(false);

  bool _disposed = false;

  ReadonlySignal<DeckWatcherStatus> get status => _status;
  ReadonlySignal<Object?> get error => _error;
  ReadonlySignal<bool> get isRebuilding => _isRebuilding;

  DeckWatcher({required this.configuration, DeckService? store});

  Future<void> start() async {
    if (_disposed || _status.value != DeckWatcherStatus.idle) {
      return;
    }

    _status.value = DeckWatcherStatus.running;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _status.value = DeckWatcherStatus.stopped;

    _status.dispose();
    _error.dispose();
    _isRebuilding.dispose();
  }
}
