import 'dart:async';
import 'dart:collection';

/// Limits concurrent capture work and transfers released permits in FIFO order.
final class CaptureLimiter {
  final int _maximumConcurrent;
  final Queue<Completer<void>> _waiters = Queue();
  var _active = 0;

  CaptureLimiter(int maximumConcurrent)
    : _maximumConcurrent = maximumConcurrent {
    if (maximumConcurrent < 1) {
      throw ArgumentError.value(
        maximumConcurrent,
        'maximumConcurrent',
        'Must be at least one.',
      );
    }
  }

  Future<void> acquire() {
    if (_active < _maximumConcurrent) {
      _active++;
      return Future<void>.value();
    }

    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void release() {
    if (_active == 0) {
      throw StateError(
        'Cannot release a capture permit that was not acquired.',
      );
    }
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
      return;
    }
    _active--;
  }
}
