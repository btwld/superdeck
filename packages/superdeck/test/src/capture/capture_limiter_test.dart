import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/capture/capture_limiter.dart';

void main() {
  test('rejects an invalid concurrency limit', () {
    expect(() => CaptureLimiter(0), throwsArgumentError);
  });

  test(
    'holds work above the concurrency limit until a permit is released',
    () async {
      final limiter = CaptureLimiter(3);
      await Future.wait([
        limiter.acquire(),
        limiter.acquire(),
        limiter.acquire(),
      ]);

      var fourthStarted = false;
      final fourth = limiter.acquire().then((_) => fourthStarted = true);
      await Future<void>.delayed(Duration.zero);

      expect(fourthStarted, isFalse);

      limiter.release();
      await fourth;
      expect(fourthStarted, isTrue);

      limiter.release();
      limiter.release();
      limiter.release();
    },
  );

  test('transfers permits to waiters in FIFO order', () async {
    final limiter = CaptureLimiter(1);
    await limiter.acquire();

    final started = <int>[];
    final second = limiter.acquire().then((_) => started.add(2));
    final third = limiter.acquire().then((_) => started.add(3));

    limiter.release();
    await second;
    expect(started, [2]);

    limiter.release();
    await third;
    expect(started, [2, 3]);

    limiter.release();
  });

  test('rejects releasing a permit that is not active', () {
    final limiter = CaptureLimiter(1);

    expect(limiter.release, throwsStateError);
  });
}
