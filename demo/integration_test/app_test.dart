import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void assertOnlyLayoutOverflowOrNoException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) {
    return;
  }

  final isLayoutOverflow = exception.toString().contains('overflowed');
  expect(
    isLayoutOverflow,
    isTrue,
    reason: 'Only layout overflow is acceptable, got: $exception',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SuperDeck Integration Tests', () {
    setUpAll(() async {
      await TestApp.initialize();
    });

    group('App Startup', () {
      testWidgets('app starts successfully without errors', (tester) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);

        // Verify no error screen is shown
        expect(find.textContaining('Error loading presentation'), findsNothing);
        assertOnlyLayoutOverflowOrNoException(tester);
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
          // Early frames may be either still loading or already loaded.
          expect(
            controller.isLoading.value || controller.totalSlides.value > 0,
            isTrue,
            reason: 'App should be loading or have slides available',
          );
          await tester.waitForSlidesLoaded(controller);
          expect(controller.isLoading.value, isFalse);
          return;
        }

        // Controller may be mounted after first frame on slower CI machines.
        await tester.pumpFor(const Duration(seconds: 1));
        final delayedController = findDeckController(tester);
        expect(delayedController, isNotNull);
        await tester.waitForSlidesLoaded(delayedController!);
      });
    });

    group('Visible UI', () {
      testWidgets('first slide heading is visible', (tester) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);

        expect(find.text('SuperDeck'), findsOneWidget);
        expect(
          find.textContaining('Build presentations with Flutter'),
          findsOneWidget,
        );
      });

      testWidgets('menu button opens controls and updates counter', (
        tester,
      ) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);
        expect(controller!.isMenuOpen.value, isFalse);

        await tester.tap(find.bySemanticsLabel('Open menu'));
        await tester.pumpFor(const Duration(milliseconds: 500));
        expect(controller.isMenuOpen.value, isTrue);

        expect(
          find.textContaining('1 of ${controller.totalSlides.value}'),
          findsOneWidget,
        );

        await tester.tap(find.bySemanticsLabel('Next slide'));
        await tester.pumpUntil(
          () => controller.currentIndex.value == 1,
          debugLabel: 'menu arrow-forward navigation',
          onTimeout: () => describeDeckControllerState(controller),
        );

        expect(
          find.textContaining('2 of ${controller.totalSlides.value}'),
          findsOneWidget,
        );

        await tester.tap(find.bySemanticsLabel('Close menu'));
        await tester.pumpFor(const Duration(milliseconds: 300));
        expect(controller.isMenuOpen.value, isFalse);
      });

      testWidgets('notes panel toggles from bottom bar controls', (
        tester,
      ) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);
        expect(controller!.isNotesOpen.value, isFalse);

        await tester.tap(find.bySemanticsLabel('Open menu'));
        await tester.pumpFor(const Duration(milliseconds: 300));

        await tester.tap(find.bySemanticsLabel('Open notes panel'));
        await tester.pumpUntil(
          () => controller.isNotesOpen.value,
          debugLabel: 'notes panel open from icon',
          onTimeout: () => describeDeckControllerState(controller),
        );

        // Semantics label updates can lag on some macOS runners. Use whichever
        // toggle label is currently available to close the notes panel.
        final closeNotesFinder = find.bySemanticsLabel('Close notes panel');
        final openNotesFinder = find.bySemanticsLabel('Open notes panel');

        if (closeNotesFinder.evaluate().isNotEmpty) {
          await tester.tap(closeNotesFinder);
        } else if (openNotesFinder.evaluate().isNotEmpty) {
          await tester.tap(openNotesFinder);
        } else {
          fail(
            'Could not find notes toggle button after opening panel.\n'
            '${describeDeckControllerState(controller)}',
          );
        }

        await tester.pumpUntil(
          () => !controller.isNotesOpen.value,
          debugLabel: 'notes panel close from icon',
          onTimeout: () => describeDeckControllerState(controller),
        );
      });

      testWidgets('thumbnail workflow supports navigation and regenerate', (
        tester,
      ) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);
        expect(controller!.slides.value.length, greaterThanOrEqualTo(2));

        final firstSlideKey = controller.slides.value.first.key;

        await tester.tap(find.bySemanticsLabel('Open menu'));
        await tester.pumpFor(const Duration(milliseconds: 500));
        expect(controller.isMenuOpen.value, isTrue);

        await tester.pumpUntil(
          () => controller.getThumbnail(firstSlideKey) != null,
          timeout: const Duration(seconds: 10),
          debugLabel: 'thumbnail cache warmup on menu open',
          onTimeout: () => describeDeckControllerState(controller),
        );

        expect(find.bySemanticsLabel('Slide thumbnail 1'), findsWidgets);
        expect(find.bySemanticsLabel('Slide thumbnail 2'), findsWidgets);

        await tester.tap(find.bySemanticsLabel('Slide thumbnail 2').first);
        await tester.pumpUntil(
          () => controller.currentIndex.value == 1,
          debugLabel: 'thumbnail navigation to slide 2',
          onTimeout: () => describeDeckControllerState(controller),
        );

        await tester.tap(find.bySemanticsLabel('Regenerate thumbnails'));
        await tester.pumpFor(const Duration(milliseconds: 300));

        expect(controller.getThumbnail(firstSlideKey), isNotNull);
        expect(find.textContaining('Error loading presentation'), findsNothing);
        assertOnlyLayoutOverflowOrNoException(tester);
      });
    });

    group('Slide Loading', () {
      testWidgets('slides load and display', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(
          controller,
          isNotNull,
          reason: 'DeckController should be available',
        );
        expect(
          controller!.isLoading.value,
          isFalse,
          reason: 'Loading should complete',
        );
        expect(
          controller.hasError.value,
          isFalse,
          reason: 'No error should occur',
        );

        final slideCount = controller.totalSlides.value;
        expect(
          slideCount,
          greaterThan(0),
          reason: 'Should have at least one slide',
        );
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
        expect(
          controller!.currentIndex.value,
          0,
          reason: 'Should start at first slide',
        );
        expect(
          controller.currentSlide.value,
          isNotNull,
          reason: 'Current slide should be available',
        );
      });

      testWidgets('asset-heavy slide loads without presentation error', (
        tester,
      ) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);

        await tester.navigateToSlide(controller!, 4);
        expect(controller.currentIndex.value, 4);
        expect(controller.hasError.value, isFalse);
        expect(find.textContaining('Error loading presentation'), findsNothing);
        assertOnlyLayoutOverflowOrNoException(tester);
      });
    });

    group('Navigation', () {
      testWidgets('can navigate to next slide', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.currentIndex.value, 0);
        expect(
          controller.canGoNext.value,
          isTrue,
          reason: 'Should be able to go next',
        );

        // Navigate to next slide
        await controller.nextSlide();
        await tester.pumpUntil(
          () => controller.currentIndex.value == 1,
          timeout: const Duration(seconds: 5),
          debugLabel: 'navigation to slide 1',
        );

        expect(
          controller.currentIndex.value,
          1,
          reason: 'Should be on second slide',
        );
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
        await tester.pumpUntil(
          () => controller.currentIndex.value == 0,
          timeout: const Duration(seconds: 5),
          debugLabel: 'navigation back to slide 0',
        );

        expect(
          controller.currentIndex.value,
          0,
          reason: 'Should be back on first slide',
        );
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
        await tester.pumpUntil(
          () => controller.isMenuOpen.value,
          timeout: const Duration(seconds: 3),
          debugLabel: 'menu open',
        );
        expect(controller.isMenuOpen.value, isTrue);

        controller.closeMenu();
        await tester.pumpUntil(
          () => !controller.isMenuOpen.value,
          timeout: const Duration(seconds: 3),
          debugLabel: 'menu close',
        );
        expect(controller.isMenuOpen.value, isFalse);
      });

      testWidgets('notes panel can be toggled', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.isNotesOpen.value, isFalse);

        controller.toggleNotes();
        await tester.pumpUntil(
          () => controller.isNotesOpen.value,
          timeout: const Duration(seconds: 3),
          debugLabel: 'notes open',
        );
        expect(controller.isNotesOpen.value, isTrue);

        controller.toggleNotes();
        await tester.pumpUntil(
          () => !controller.isNotesOpen.value,
          timeout: const Duration(seconds: 3),
          debugLabel: 'notes close',
        );
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
