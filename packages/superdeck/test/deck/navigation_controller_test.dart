import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/navigation_controller.dart';
import 'package:superdeck/src/deck/navigation_events.dart';

void main() {
  group('NavigationController', () {
    late NavigationController controller;
    int totalSlides = 10;

    setUp(() {
      controller = NavigationController(
        getTotalSlides: () => totalSlides,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('initializes with default values', () {
        expect(controller.currentIndex, 0);
        expect(controller.history, isEmpty);
        expect(controller.isTransitioning, false);
        expect(controller.totalSlides, 10);
      });

      test('router is initialized with correct initial location', () {
        expect(controller.router.routeInformationProvider.value.uri.path,
            '/slides/0');
      });
    });

    group('Computed Properties', () {
      test('canGoNext returns true when not at last slide', () {
        controller.updateCurrentIndex(0);
        expect(controller.canGoNext, true);
      });

      test('canGoNext returns false when at last slide', () {
        controller.updateCurrentIndex(9);
        expect(controller.canGoNext, false);
      });

      test('canGoPrevious returns false when at first slide', () {
        controller.updateCurrentIndex(0);
        expect(controller.canGoPrevious, false);
      });

      test('canGoPrevious returns true when not at first slide', () {
        controller.updateCurrentIndex(5);
        expect(controller.canGoPrevious, true);
      });

      test('canGoBack returns false when history is empty', () {
        expect(controller.canGoBack, false);
      });

      test('canGoBack returns true when history has items', () {
        controller.updateCurrentIndex(0);
        controller.goToSlide(5);
        expect(controller.canGoBack, true);
      });
    });

    group('Navigation', () {
      // Note: These tests are commented out because router-based navigation
      // requires a full Flutter app context with MaterialApp and routing setup.
      // These would be better suited as integration tests.

      test('goToSlide ignores invalid indices', () async {
        controller.updateCurrentIndex(0);
        await controller.goToSlide(-1);
        expect(controller.currentIndex, 0);

        await controller.goToSlide(100);
        expect(controller.currentIndex, 0);
      });

      test('nextSlide does nothing at last slide', () async {
        controller.updateCurrentIndex(9);
        await controller.nextSlide();
        expect(controller.currentIndex, 9);
      });

      test('previousSlide does nothing at first slide', () async {
        controller.updateCurrentIndex(0);
        await controller.previousSlide();
        expect(controller.currentIndex, 0);
      });
    });

    group('Event Handling', () {
      // Note: Event handling tests require full router context
      // These would be better as integration tests with MaterialApp setup

      test('handleNavigationEvent accepts valid events', () {
        // Just verify events can be called without errors
        expect(() => controller.handleNavigationEvent(NextSlideEvent()),
            returnsNormally);
        expect(() => controller.handleNavigationEvent(PreviousSlideEvent()),
            returnsNormally);
        expect(() => controller.handleNavigationEvent(GoToSlideEvent(5)),
            returnsNormally);
      });
    });

    group('State Updates', () {
      test('updateCurrentIndex clamps to valid range', () {
        controller.updateCurrentIndex(-5);
        expect(controller.currentIndex, 0);

        controller.updateCurrentIndex(100);
        expect(controller.currentIndex, 9);
      });

      test('updateCurrentIndex notifies listeners on change', () {
        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.updateCurrentIndex(5);
        expect(notified, true);
      });

      test('updateCurrentIndex does not notify listeners if unchanged', () {
        controller.updateCurrentIndex(5);
        var notifyCount = 0;
        controller.addListener(() {
          notifyCount++;
        });

        controller.updateCurrentIndex(5);
        expect(notifyCount, 0);
      });
    });

    group('Edge Cases', () {
      test('handles zero slides gracefully', () {
        final emptyController = NavigationController(
          getTotalSlides: () => 0,
        );

        expect(emptyController.totalSlides, 0);
        expect(emptyController.canGoNext, false);
        expect(emptyController.canGoPrevious, false);

        emptyController.dispose();
      });

      test('handles single slide deck', () {
        final singleController = NavigationController(
          getTotalSlides: () => 1,
        );

        singleController.updateCurrentIndex(0);
        expect(singleController.canGoNext, false);
        expect(singleController.canGoPrevious, false);

        singleController.dispose();
      });
    });
  });
}
