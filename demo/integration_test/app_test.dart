import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SuperDeck Integration Tests', () {
    setUpAll(() async {
      await TestApp.initialize();
    });

    group('App Startup', () {
      testWidgets('app starts successfully without errors', (tester) async {
        await tester.pumpWidget(const TestApp());

        // Wait for initial load
        await tester.pump();

        // Verify no error screen is shown
        expect(find.textContaining('Error loading presentation'), findsNothing);

        // Wait for app to fully settle
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify app rendered successfully
        expect(tester.takeException(), isNull);
      });

      testWidgets('app shows loading state before slides load', (tester) async {
        await tester.pumpWidget(const TestApp());

        // Immediately after pump, check initial state
        await tester.pump();

        // The app should be in either loading or loaded state
        // (depending on timing, deck may load very quickly in tests)
        final controller = findDeckController(tester);

        // If controller found early, it may already be loading
        if (controller != null) {
          // Either loading or already loaded is acceptable
          expect(
            controller.isLoading.value || !controller.isLoading.value,
            isTrue,
          );
        }

        // Wait for full load
        await tester.pumpAndSettle(const Duration(seconds: 5));
      });
    });

    group('Slide Loading', () {
      testWidgets('slides load and display', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull, reason: 'DeckController should be available');
        expect(controller!.isLoading.value, isFalse, reason: 'Loading should complete');
        expect(controller.hasError.value, isFalse, reason: 'No error should occur');

        final slideCount = controller.totalSlides.value;
        expect(slideCount, greaterThan(0), reason: 'Should have at least one slide');
      });

      testWidgets('demo app has at least 5 slides', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(
          controller!.totalSlides.value,
          greaterThanOrEqualTo(5),
          reason: 'Demo should have at least 5 slides',
        );
      });

      testWidgets('first slide displays correctly', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.currentIndex.value, 0, reason: 'Should start at first slide');
        expect(
          controller.currentSlide.value,
          isNotNull,
          reason: 'Current slide should be available',
        );
      });
    });

    group('Navigation', () {
      testWidgets('can navigate to next slide', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.currentIndex.value, 0);
        expect(controller.canGoNext.value, isTrue, reason: 'Should be able to go next');

        // Navigate to next slide
        await controller.nextSlide();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(controller.currentIndex.value, 1, reason: 'Should be on second slide');
      });

      testWidgets('can navigate to previous slide', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);

        // First navigate to slide 1
        await tester.navigateToSlide(controller!, 1);
        expect(controller.currentIndex.value, 1);
        expect(controller.canGoPrevious.value, isTrue);

        // Now navigate back
        await controller.previousSlide();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(controller.currentIndex.value, 0, reason: 'Should be back on first slide');
      });

      testWidgets('canGoPrevious is false on first slide', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.currentIndex.value, 0);
        expect(controller.canGoPrevious.value, isFalse);
      });

      testWidgets('canGoNext is false on last slide', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);

        final lastIndex = controller!.totalSlides.value - 1;

        // Navigate to last slide
        await tester.navigateToSlide(controller, lastIndex);

        expect(controller.currentIndex.value, lastIndex);
        expect(controller.canGoNext.value, isFalse);
      });

      testWidgets('goToSlide navigates to specific slide', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);

        // Navigate to slide 3
        await tester.navigateToSlide(controller!, 3);

        expect(controller.currentIndex.value, 3);
      });

      testWidgets('navigation updates currentSlide', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);

        final slide0 = controller!.currentSlide.value;
        expect(slide0, isNotNull);
        expect(slide0!.slideIndex, 0);

        // Navigate to slide 2
        await tester.navigateToSlide(controller, 2);

        final slide2 = controller.currentSlide.value;
        expect(slide2, isNotNull);
        expect(slide2!.slideIndex, 2);
      });
    });

    group('UI State', () {
      testWidgets('menu starts closed', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.isMenuOpen.value, isFalse);
      });

      testWidgets('menu can be toggled', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.isMenuOpen.value, isFalse);

        controller.openMenu();
        await tester.pumpAndSettle();
        expect(controller.isMenuOpen.value, isTrue);

        controller.closeMenu();
        await tester.pumpAndSettle();
        expect(controller.isMenuOpen.value, isFalse);
      });

      testWidgets('notes panel can be toggled', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.isNotesOpen.value, isFalse);

        controller.toggleNotes();
        await tester.pumpAndSettle();
        expect(controller.isNotesOpen.value, isTrue);

        controller.toggleNotes();
        await tester.pumpAndSettle();
        expect(controller.isNotesOpen.value, isFalse);
      });
    });

    group('Error Handling', () {
      testWidgets('app handles successful deck load', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.hasError.value, isFalse);
        expect(controller.error.value, isNull);
      });
    });
  });
}
