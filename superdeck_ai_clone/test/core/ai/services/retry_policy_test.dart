import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_ai/core/ai/services/retry_policy.dart';

void main() {
  group('RetryPolicy', () {
    test('retries and succeeds with exponential backoff', () async {
      var attempts = 0;
      final delays = <Duration>[];
      final policy = RetryPolicy(
        maxAttempts: 3,
        baseDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 1),
        jitterFactor: 0,
        delayFn: (delay) async {
          delays.add(delay);
        },
      );

      final result = await policy.run(() async {
        attempts++;
        if (attempts < 3) {
          throw Exception('HTTP 503 UNAVAILABLE');
        }
        return 'ok';
      });

      expect(result, 'ok');
      expect(attempts, 3);
      expect(delays, const [
        Duration(milliseconds: 100),
        Duration(milliseconds: 200),
      ]);
    });

    test('does not retry when predicate returns false', () async {
      var attempts = 0;
      final delays = <Duration>[];
      final policy = RetryPolicy(
        maxAttempts: 5,
        jitterFactor: 0,
        shouldRetry: (_) => false,
        delayFn: (delay) async {
          delays.add(delay);
        },
      );

      await expectLater(
        () => policy.run(() async {
          attempts++;
          throw StateError('nope');
        }),
        throwsA(isA<StateError>()),
      );

      expect(attempts, 1);
      expect(delays, isEmpty);
    });

    test('stops after max attempts and rethrows', () async {
      var attempts = 0;
      final delays = <Duration>[];
      final policy = RetryPolicy(
        maxAttempts: 2,
        baseDelay: const Duration(milliseconds: 50),
        jitterFactor: 0,
        delayFn: (delay) async {
          delays.add(delay);
        },
      );

      await expectLater(
        () => policy.run(() async {
          attempts++;
          throw Exception('503 Service Unavailable');
        }),
        throwsA(isA<Exception>()),
      );

      expect(attempts, 2);
      expect(delays, const [Duration(milliseconds: 50)]);
    });

    test('defaultRetryDecider matches transient errors', () {
      expect(RetryPolicy.defaultRetryDecider('503 UNAVAILABLE'), isTrue);
      expect(
        RetryPolicy.defaultRetryDecider('RESOURCE_EXHAUSTED: quota'),
        isFalse,
      );
      expect(RetryPolicy.defaultRetryDecider('invalid api key'), isFalse);
    });
  });
}
