import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/navigation_service.dart';

void main() {
  group('NavigationService', () {
    group('Constructor', () {
      test('initializes with default transition duration', () {
        final service = NavigationService();
        expect(service.transitionDuration, const Duration(seconds: 1));
      });

      test('initializes with custom transition duration', () {
        final customDuration = const Duration(milliseconds: 500);
        final service = NavigationService(transitionDuration: customDuration);
        expect(service.transitionDuration, customDuration);
      });

      test('accepts zero duration for testing', () {
        final service = NavigationService(transitionDuration: Duration.zero);
        expect(service.transitionDuration, Duration.zero);
      });

      test('accepts negative duration (edge case)', () {
        final service = NavigationService(
          transitionDuration: const Duration(milliseconds: -100),
        );
        expect(
          service.transitionDuration,
          const Duration(milliseconds: -100),
        );
      });

      test('accepts very long duration', () {
        final service = NavigationService(
          transitionDuration: const Duration(hours: 24),
        );
        expect(service.transitionDuration, const Duration(hours: 24));
      });
    });

    group('transitionDuration', () {
      test('is accessible after construction', () {
        final service = NavigationService();
        expect(service.transitionDuration, isA<Duration>());
      });

      test('default is one second', () {
        final service = NavigationService();
        expect(service.transitionDuration.inMilliseconds, 1000);
      });

      test('custom duration in microseconds', () {
        final service = NavigationService(
          transitionDuration: const Duration(microseconds: 500000),
        );
        expect(service.transitionDuration.inMicroseconds, 500000);
      });
    });

    group('createRouter', () {
      test('returns a GoRouter instance', () {
        final service = NavigationService();
        final router = service.createRouter(onIndexChanged: (_) {});
        expect(router, isNotNull);
      });

      test('accepts onIndexChanged callback', () {
        final service = NavigationService();
        var called = false;
        service.createRouter(onIndexChanged: (_) => called = true);
        // Just verify it can be created without throwing
        expect(called, isFalse); // Callback not called immediately
      });
    });
  });
}
