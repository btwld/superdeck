import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck/superdeck.dart';

import 'helpers/test_helpers.dart';

const _minimumDemoSlideCount = 5;

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
        final controller = findDeckHandle(tester);

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
        final delayedController = findDeckHandle(tester);
        expect(delayedController, isNotNull);
        await tester.waitForSlidesLoaded(delayedController!);
      });
    });

    group('Visible UI', () {
      testWidgets('first slide is available after load', (tester) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);

        await tester.pumpUntil(
          () => controller!.currentSlide.value != null,
          debugLabel: 'current slide availability',
          onTimeout: () => describeDeckState(controller),
        );

        expect(controller!.hasError.value, isFalse);
        expect(
          controller.totalSlides.value,
          greaterThanOrEqualTo(_minimumDemoSlideCount),
        );
        expect(controller.currentIndex.value, 0);
        expect(controller.currentSlide.value, isNotNull);
        expect(find.textContaining('Error loading presentation'), findsNothing);
        assertOnlyLayoutOverflowOrNoException(tester);
      });

      testWidgets('menu button opens controls and updates counter', (
        tester,
      ) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);
        expect(controller!.isMenuOpen.value, isFalse);
        final totalSlides = controller.totalSlides.value;
        expect(totalSlides, greaterThanOrEqualTo(_minimumDemoSlideCount));

        await tester.tap(find.bySemanticsLabel('Open menu'));
        await tester.pumpFor(const Duration(milliseconds: 500));
        expect(controller.isMenuOpen.value, isTrue);

        expect(find.textContaining('1 of $totalSlides'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Next slide'));
        await tester.pumpUntil(
          () => controller.currentIndex.value == 1,
          debugLabel: 'menu arrow-forward navigation',
          onTimeout: () => describeDeckState(controller),
        );
        expect(find.textContaining('2 of $totalSlides'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Close menu'));
        await tester.pumpFor(const Duration(milliseconds: 300));
        expect(controller.isMenuOpen.value, isFalse);
        assertOnlyLayoutOverflowOrNoException(tester);
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
          onTimeout: () => describeDeckState(controller),
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
            '${describeDeckState(controller)}',
          );
        }

        await tester.pumpUntil(
          () => !controller.isNotesOpen.value,
          debugLabel: 'notes panel close from icon',
          onTimeout: () => describeDeckState(controller),
        );
      });

      testWidgets('thumbnail workflow supports navigation and regenerate', (
        tester,
      ) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);
        final totalSlides = controller!.slides.value.length;
        expect(totalSlides, greaterThanOrEqualTo(_minimumDemoSlideCount));

        await tester.tap(find.bySemanticsLabel('Open menu'));
        await tester.pumpFor(const Duration(milliseconds: 500));
        expect(controller.isMenuOpen.value, isTrue);

        // The thumbnail panel uses a lazy ScrollablePositionedList that may
        // not build items on headless CI runners (zero-size viewport during
        // SizeTransition). Instead of relying on semantics labels from the
        // list items, verify the panel is mounted and use the controller API
        // for navigation.
        final thumb1 = find.bySemanticsLabel('Slide thumbnail 1');
        final panelItemsVisible = thumb1.evaluate().isNotEmpty;

        if (panelItemsVisible) {
          await tester.tap(thumb1.first);
          await tester.pumpFor(const Duration(milliseconds: 300));

          // Slide thumbnail 2 may be off-screen in the lazy list on narrow
          // CI viewports — only tap it if visible.
          final thumb2 = find.bySemanticsLabel('Slide thumbnail 2');
          if (thumb2.evaluate().isNotEmpty) {
            await tester.tap(thumb2.first);
            await tester.pumpUntil(
              () => controller.currentIndex.value == 1,
              debugLabel: 'thumbnail navigation to slide 2',
              onTimeout: () => describeDeckState(controller),
            );
          }
        } else {
          // Fallback: use controller-based navigation when panel items
          // are not rendered (headless CI with zero-viewport lazy list).
          await tester.navigateToSlide(controller, 1);
          expect(controller.currentIndex.value, 1);
          await tester.navigateToSlide(controller, 0);
        }

        await tester.tap(find.bySemanticsLabel('Regenerate thumbnails'));
        await tester.pumpFor(const Duration(milliseconds: 300));

        expect(
          controller.currentIndex.value,
          inInclusiveRange(0, totalSlides - 1),
        );
        expect(find.bySemanticsLabel('Regenerate thumbnails'), findsOneWidget);
        expect(find.textContaining('Error loading presentation'), findsNothing);
        assertOnlyLayoutOverflowOrNoException(tester);
      });
    });

    group('Navigation', () {
      testWidgets('asset-heavy slide loads without presentation error', (
        tester,
      ) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);
        expect(
          controller!.totalSlides.value,
          greaterThanOrEqualTo(_minimumDemoSlideCount),
        );
        const targetIndex = 4;

        await tester.navigateToSlide(controller, targetIndex);
        expect(controller.currentIndex.value, targetIndex);
        expect(controller.hasError.value, isFalse);
        expect(find.textContaining('Error loading presentation'), findsNothing);
        assertOnlyLayoutOverflowOrNoException(tester);
      });

      testWidgets('can navigate to next slide', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(controller!.currentIndex.value, 0);
        expect(
          controller.totalSlides.value,
          greaterThanOrEqualTo(_minimumDemoSlideCount),
        );
        expect(
          controller.canGoNext.value,
          isTrue,
          reason: 'Should be able to go next',
        );

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
        expect(
          controller!.totalSlides.value,
          greaterThanOrEqualTo(_minimumDemoSlideCount),
        );

        // First navigate to slide 1
        await tester.navigateToSlide(controller, 1);
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
        expect(
          controller!.totalSlides.value,
          greaterThanOrEqualTo(_minimumDemoSlideCount),
        );
        const targetIndex = 3;

        await tester.navigateToSlide(controller, targetIndex);

        expect(controller.currentIndex.value, targetIndex);
      });

      testWidgets('navigation updates currentSlide', (tester) async {
        final controller = await tester.pumpTestApp();

        expect(controller, isNotNull);
        expect(
          controller!.totalSlides.value,
          greaterThanOrEqualTo(_minimumDemoSlideCount),
        );
        const targetIndex = 2;

        final slide0 = controller.currentSlide.value;
        expect(slide0, isNotNull);
        expect(slide0!.slideIndex, 0);

        await tester.navigateToSlide(controller, targetIndex);

        final currentSlide = controller.currentSlide.value;
        expect(currentSlide, isNotNull);
        expect(currentSlide!.slideIndex, targetIndex);
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

    group('Keyboard Navigation', () {
      testWidgets('Meta+ArrowRight navigates to next slide', (tester) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);
        expect(controller!.currentIndex.value, 0);
        expect(
          controller.totalSlides.value,
          greaterThanOrEqualTo(2),
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

        await tester.pumpUntil(
          () => controller.currentIndex.value == 1,
          debugLabel: 'keyboard Meta+ArrowRight navigation',
          onTimeout: () => describeDeckState(controller),
        );

        expect(controller.currentIndex.value, 1);
        assertOnlyLayoutOverflowOrNoException(tester);
      });

      testWidgets('Meta+ArrowLeft navigates to previous slide', (
        tester,
      ) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);

        await tester.navigateToSlide(controller!, 1);
        expect(controller.currentIndex.value, 1);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

        await tester.pumpUntil(
          () => controller.currentIndex.value == 0,
          debugLabel: 'keyboard Meta+ArrowLeft navigation',
          onTimeout: () => describeDeckState(controller),
        );

        expect(controller.currentIndex.value, 0);
        assertOnlyLayoutOverflowOrNoException(tester);
      });

      testWidgets('Meta+ArrowDown navigates to next slide', (tester) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);
        expect(controller!.currentIndex.value, 0);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

        await tester.pumpUntil(
          () => controller.currentIndex.value == 1,
          debugLabel: 'keyboard Meta+ArrowDown navigation',
          onTimeout: () => describeDeckState(controller),
        );

        expect(controller.currentIndex.value, 1);
      });

      testWidgets('arrow key without Meta does not navigate', (tester) async {
        final controller = await tester.pumpTestApp();
        expect(controller, isNotNull);
        expect(controller!.currentIndex.value, 0);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpFor(const Duration(milliseconds: 300));

        expect(controller.currentIndex.value, 0);
        assertOnlyLayoutOverflowOrNoException(tester);
      });
    });

  });

  group('Live Edit', () {
    late SuperDeckRuntime watchRuntime;
    late String originalContent;

    setUpAll(() async {
      originalContent = await slidesFile.readAsString();
      watchRuntime = await createTestRuntime(watch: true);
    });

    tearDown(() async {
      // Always restore original slides.md content after each test
      await slidesFile.writeAsString(originalContent);
      // Allow the file watcher debounce to settle so subsequent tests
      // start from a clean state.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });

    testWidgets('modifying slides.md updates the presentation', (
      tester,
    ) async {
      final controller = await tester.pumpTestApp(runtime: watchRuntime);
      expect(controller, isNotNull);

      final initialSlideCount = controller!.totalSlides.value;
      expect(
        initialSlideCount,
        greaterThanOrEqualTo(_minimumDemoSlideCount),
      );

      // Append a simple new slide (no mermaid/external tools)
      final modifiedContent = '$originalContent\n---\n\n# Watch Test Slide\n';
      await slidesFile.writeAsString(modifiedContent);

      // Wait for the full pipeline: FileWatcher detects change →
      // DeckBuilder rebuilds deck.json → DeckService stream emits →
      // DeckController updates signals
      await tester.pumpUntil(
        () => controller.totalSlides.value > initialSlideCount,
        timeout: const Duration(seconds: 30),
        debugLabel: 'live-edit slide count increase',
        onTimeout: () => [
          describeDeckState(controller),
          'Expected totalSlides > $initialSlideCount',
        ].join('\n'),
      );

      expect(
        controller.totalSlides.value,
        initialSlideCount + 1,
        reason: 'Appending one slide separator should add exactly one slide',
      );
      expect(controller.hasError.value, isFalse);
      assertOnlyLayoutOverflowOrNoException(tester);
    });
  });
}
