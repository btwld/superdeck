import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UI Controls', () {
    setUpAll(() async {
      await TestApp.initialize();
    });

    testWidgets('menu opens, updates counter, and closes', (tester) async {
      final controller = await tester.pumpTestApp();
      expect(controller.isMenuOpen.value, isFalse);
      final totalSlides = controller.totalSlides.value;

      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.isMenuOpen.value,
        debugLabel: 'menu open',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(controller.isMenuOpen.value, isTrue);
      expect(find.textContaining('1 of $totalSlides'), findsOneWidget);

      if (totalSlides > 1) {
        await tester.tapByLabel('Next slide');
        // Waiting on the rendered counter covers both the signal update and
        // the Watch widget rebuild without a fixed delay.
        await tester.pumpUntil(
          () => find
              .textContaining('2 of $totalSlides')
              .evaluate()
              .isNotEmpty,
          debugLabel: 'menu arrow-forward counter update',
          onTimeout: () => describeDeckControllerState(controller),
        );
        expect(controller.currentIndex.value, 1);

        await tester.tapByLabel('Previous slide');
        await tester.pumpUntil(
          () => find
              .textContaining('1 of $totalSlides')
              .evaluate()
              .isNotEmpty,
          debugLabel: 'menu arrow-back counter update',
          onTimeout: () => describeDeckControllerState(controller),
        );
        expect(controller.currentIndex.value, 0);
      }

      await tester.tapByLabel('Close menu');
      await tester.pumpUntil(
        () => !controller.isMenuOpen.value,
        debugLabel: 'menu close',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(controller.isMenuOpen.value, isFalse);
      assertOnlyLayoutOverflowOrNoException(tester);
    });

    testWidgets('notes panel toggles from bottom bar', (tester) async {
      final controller = await tester.pumpTestApp();
      expect(controller.isNotesOpen.value, isFalse);

      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.isMenuOpen.value,
        debugLabel: 'menu open for notes',
        onTimeout: () => describeDeckControllerState(controller),
      );

      await tester.tapByLabel('Open notes panel');
      await tester.pumpUntil(
        () => controller.isNotesOpen.value,
        debugLabel: 'notes panel open',
        onTimeout: () => describeDeckControllerState(controller),
      );

      // Semantics label updates can lag on some macOS runners — try either label.
      // Use raw finders here because tapByLabel can fail when the semantics
      // node exists but the underlying widget is at the viewport edge.
      final closeLabel = find.bySemanticsLabel('Close notes panel');
      final openLabel = find.bySemanticsLabel('Open notes panel');
      final toggleFinder = closeLabel.evaluate().isNotEmpty
          ? closeLabel
          : openLabel.evaluate().isNotEmpty
          ? openLabel
          : null;

      if (toggleFinder == null) {
        fail(
          'Could not find notes toggle button after opening panel.\n'
          '${describeDeckControllerState(controller)}',
        );
      }

      await tester.ensureVisible(toggleFinder.first);
      await tester.tap(toggleFinder, warnIfMissed: false);

      await tester.pumpUntil(
        () => !controller.isNotesOpen.value,
        debugLabel: 'notes panel close',
        onTimeout: () => describeDeckControllerState(controller),
      );
    });

    testWidgets('thumbnail workflow supports navigation and regenerate', (
      tester,
    ) async {
      final controller = await tester.pumpTestApp();
      final totalSlides = controller.slides.value.length;
      expect(totalSlides, greaterThan(0));

      final firstSlideKey = controller.slides.value.first.key;

      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.isMenuOpen.value,
        debugLabel: 'menu open for thumbnails',
        onTimeout: () => describeDeckControllerState(controller),
      );

      final thumb1 = find.bySemanticsLabel('Slide thumbnail 1');
      final panelItemsVisible = thumb1.evaluate().isNotEmpty;

      if (panelItemsVisible && totalSlides > 1) {
        await tester.ensureVisible(thumb1.first);
        await tester.tap(thumb1.first, warnIfMissed: false);
        await tester.pumpFor(const Duration(milliseconds: 300));

        final thumb2 = find.bySemanticsLabel('Slide thumbnail 2');
        if (thumb2.evaluate().isNotEmpty) {
          await tester.ensureVisible(thumb2.first);
          await tester.tap(thumb2.first, warnIfMissed: false);
          await tester.pumpUntil(
            () => controller.currentIndex.value == 1,
            debugLabel: 'thumbnail navigation to slide 2',
            onTimeout: () => describeDeckControllerState(controller),
          );
        }
      } else if (totalSlides > 1) {
        await tester.navigateToSlide(controller, 1);
        expect(controller.currentIndex.value, 1);
        await tester.navigateToSlide(controller, 0);
      }

      await tester.tapByLabel('Regenerate thumbnails');
      // First wait for regeneration to start, then for it to settle.
      // Otherwise the background work leaks into the next test and starves
      // its event loop with 15+ seconds of thumbnail generation.
      await tester.pumpUntil(
        () => controller.hasLoadingThumbnails,
        timeout: const Duration(seconds: 5),
        debugLabel: 'thumbnail regeneration to start',
        onTimeout: () => describeDeckControllerState(controller),
      );
      await tester.pumpUntil(
        () => !controller.hasLoadingThumbnails,
        timeout: const Duration(seconds: 30),
        debugLabel: 'thumbnail regeneration to complete',
        onTimeout: () => describeDeckControllerState(controller),
      );

      expect(controller.getThumbnail(firstSlideKey), isNotNull);
      expect(find.textContaining('Error loading presentation'), findsNothing);
      assertOnlyLayoutOverflowOrNoException(tester);
    });
  });
}
