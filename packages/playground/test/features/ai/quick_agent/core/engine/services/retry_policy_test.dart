import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/retry_policy.dart';

void main() {
  group('run', () {
    test('returns the result without retrying on success', () async {
      var calls = 0;
      final policy = RetryPolicy(delayFn: (_) async {});

      final result = await policy.run(() async {
        calls++;
        return 'ok';
      });

      expect(result, 'ok');
      expect(calls, 1);
    });

    test('retries retryable errors up to maxAttempts then rethrows', () async {
      var calls = 0;
      final delays = <Duration>[];
      final policy = RetryPolicy(
        maxAttempts: 3,
        jitterFactor: 0,
        delayFn: (d) async => delays.add(d),
      );

      await expectLater(
        policy.run(() async {
          calls++;
          throw Exception('503 unavailable');
        }),
        throwsA(isA<Exception>()),
      );

      expect(calls, 3); // initial try + 2 retries
      expect(delays, hasLength(2)); // one delay before each retry
    });

    test('recovers when a later attempt succeeds', () async {
      var calls = 0;
      final policy = RetryPolicy(jitterFactor: 0, delayFn: (_) async {});

      final result = await policy.run(() async {
        calls++;
        if (calls < 3) throw Exception('503');
        return 'recovered';
      });

      expect(result, 'recovered');
      expect(calls, 3);
    });

    test('reports each one-based transport attempt', () async {
      final attempts = <int>[];
      final policy = RetryPolicy(maxAttempts: 3, delayFn: (_) async {});

      final result = await policy.runWithAttempt((attempt) async {
        attempts.add(attempt);
        if (attempt < 3) throw TimeoutException('retry');
        return 'recovered';
      });

      expect(result, 'recovered');
      expect(attempts, [1, 2, 3]);
    });

    test('does not retry non-retryable errors', () async {
      var calls = 0;
      final policy = RetryPolicy(delayFn: (_) async {});

      await expectLater(
        policy.run(() async {
          calls++;
          throw Exception('400 bad request');
        }),
        throwsA(isA<Exception>()),
      );

      expect(calls, 1);
    });

    test('honours a custom shouldRetry predicate', () async {
      var calls = 0;
      final policy = RetryPolicy(
        maxAttempts: 4,
        jitterFactor: 0,
        shouldRetry: (error) => error.toString().contains('retry-me'),
        delayFn: (_) async {},
      );

      await expectLater(
        policy.run(() async {
          calls++;
          throw Exception('retry-me');
        }),
        throwsA(isA<Exception>()),
      );

      expect(calls, 4);
    });

    test('applies exponential backoff capped at maxDelay', () async {
      final delays = <Duration>[];
      final policy = RetryPolicy(
        maxAttempts: 5,
        baseDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(milliseconds: 300),
        jitterFactor: 0,
        delayFn: (d) async => delays.add(d),
      );

      await expectLater(
        policy.run(() async => throw Exception('503')),
        throwsA(isA<Exception>()),
      );

      // 100, 200, 300 (capped), 300 (capped)
      expect(delays, [
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 200),
        const Duration(milliseconds: 300),
        const Duration(milliseconds: 300),
      ]);
    });

    test('keeps jittered delays within +/- jitterFactor of the base', () async {
      final delays = <Duration>[];
      final policy = RetryPolicy(
        maxAttempts: 2,
        baseDelay: const Duration(milliseconds: 1000),
        maxDelay: const Duration(seconds: 10),
        jitterFactor: 0.2,
        random: Random(1),
        delayFn: (d) async => delays.add(d),
      );

      await expectLater(
        policy.run(() async => throw Exception('503')),
        throwsA(isA<Exception>()),
      );

      expect(delays, hasLength(1));
      expect(delays.single.inMilliseconds, inInclusiveRange(800, 1200));
    });
  });

  group('defaultRetryDecider', () {
    test('retries timeouts and 503 markers', () {
      expect(
        RetryPolicy.defaultRetryDecider(TimeoutException('request timed out')),
        isTrue,
      );
      expect(RetryPolicy.defaultRetryDecider(Exception('503')), isTrue);
      expect(RetryPolicy.defaultRetryDecider(Exception('500')), isFalse);
    });
  });
}
