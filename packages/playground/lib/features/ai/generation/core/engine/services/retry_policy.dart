import 'dart:async';
import 'dart:math';

/// Retry helper with exponential backoff and optional jitter.
class RetryPolicy {
  RetryPolicy({
    this.maxAttempts = 5,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 8),
    this.jitterFactor = 0.2,
    this.shouldRetry,
    Random? random,
    Future<void> Function(Duration)? delayFn,
  }) : _random = random ?? Random(),
       _delayFn = delayFn ?? Future.delayed;

  /// Maximum total attempts (initial try + retries).
  final int maxAttempts;

  /// Base delay for the first retry attempt.
  final Duration baseDelay;

  /// Maximum backoff delay between attempts.
  final Duration maxDelay;

  /// Jitter percentage applied to the delay (0.2 = +/-20%).
  final double jitterFactor;

  /// Optional custom retry predicate. If null, uses [defaultRetryDecider].
  final bool Function(Object error)? shouldRetry;

  final Random _random;
  final Future<void> Function(Duration) _delayFn;

  /// Runs [action] with retry/backoff.
  Future<T> run<T>(Future<T> Function() action) =>
      runWithAttempt((_) => action());

  /// Runs [action] and exposes the one-based transport attempt number.
  Future<T> runWithAttempt<T>(
    Future<T> Function(int transportAttempt) action,
  ) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await action(attempt);
      } catch (error) {
        final retryDecider = shouldRetry ?? defaultRetryDecider;
        final canRetry = attempt < maxAttempts && retryDecider(error);
        if (!canRetry) {
          rethrow;
        }
        final delay = _computeDelay(attempt);
        if (delay > Duration.zero) {
          await _delayFn(delay);
        }
      }
    }
  }

  Duration _computeDelay(int attempt) {
    if (baseDelay <= Duration.zero) {
      return Duration.zero;
    }

    final baseMs = baseDelay.inMilliseconds;
    final maxMs = maxDelay.inMilliseconds;
    final exponent = attempt - 1;
    final scaled = baseMs * (1 << exponent);
    var delayMs = scaled > maxMs ? maxMs : scaled;
    var delay = delayMs.toDouble();

    if (jitterFactor > 0) {
      final jitter = delay * jitterFactor;
      final min = delay - jitter;
      final max = delay + jitter;
      delay = min + (_random.nextDouble() * (max - min));
    }

    if (delay < 0) {
      delay = 0;
    } else if (delay > maxMs) {
      delay = maxMs.toDouble();
    }

    return Duration(milliseconds: delay.round());
  }

  /// Default retry predicate for transient transport failures.
  static bool defaultRetryDecider(Object error) {
    if (error is TimeoutException) return true;
    final message = error.toString().toLowerCase();
    return message.contains('503');
  }
}
