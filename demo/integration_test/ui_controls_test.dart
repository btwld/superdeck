import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

Finder? _notesToggleFinder() {
  final closeLabel = find.bySemanticsLabel('Close notes panel');
  if (closeLabel.evaluate().isNotEmpty) return closeLabel;

  final openLabel = find.bySemanticsLabel('Open notes panel');
  if (openLabel.evaluate().isNotEmpty) return openLabel;

  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UI Controls', () {
    setUpAll(() async {
      await TestApp.initialize();
    });

    testWidgets('menu opens, updates counter, and closes', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(2));
      expect(controller.presentation.isMenuOpen.value, isFalse);
      final totalSlides = controller.presentation.totalSlides.value;
      expect(totalSlides, 2);

      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.presentation.isMenuOpen.value,
        debugLabel: 'menu open',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(controller.presentation.isMenuOpen.value, isTrue);
      expect(find.textContaining('1 of $totalSlides'), findsOneWidget);

      await tester.tapByLabel('Next slide');
      await tester.pumpUntil(
        () => controller.presentation.currentIndex.value == 1,
        debugLabel: 'menu arrow-forward navigation',
        onTimeout: () => describeDeckControllerState(controller),
      );
      await tester.pumpUntil(
        () => find.textContaining('2 of $totalSlides').evaluate().isNotEmpty,
        debugLabel: 'menu counter to show slide 2',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(find.textContaining('2 of $totalSlides'), findsOneWidget);

      await tester.tapByLabel('Previous slide');
      await tester.pumpUntil(
        () => controller.presentation.currentIndex.value == 0,
        debugLabel: 'menu arrow-back navigation',
        onTimeout: () => describeDeckControllerState(controller),
      );
      await tester.pumpUntil(
        () => find.textContaining('1 of $totalSlides').evaluate().isNotEmpty,
        debugLabel: 'menu counter to show slide 1',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(find.textContaining('1 of $totalSlides'), findsOneWidget);

      await tester.tapByLabel('Close menu');
      await tester.pumpUntil(
        () => !controller.presentation.isMenuOpen.value,
        debugLabel: 'menu close',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(controller.presentation.isMenuOpen.value, isFalse);
      assertNoFlutterException(tester);
    });

    testWidgets('notes panel toggles from bottom bar', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(1));
      expect(controller.presentation.isNotesOpen.value, isFalse);

      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.presentation.isMenuOpen.value,
        debugLabel: 'menu open for notes',
        onTimeout: () => describeDeckControllerState(controller),
      );

      await tester.tapByLabel('Open notes panel');
      await tester.pumpUntil(
        () => controller.presentation.isNotesOpen.value,
        debugLabel: 'notes panel open',
        onTimeout: () => describeDeckControllerState(controller),
      );

      // Semantics label updates can lag on some macOS runners — try either label.
      // Use raw finders here because tapByLabel can fail when the semantics
      // node exists but the underlying widget is at the viewport edge.
      final toggleFinder = _notesToggleFinder();

      if (toggleFinder == null) {
        fail(
          'Could not find notes toggle button after opening panel.\n'
          '${describeDeckControllerState(controller)}',
        );
      }

      await tester.ensureVisible(toggleFinder.first);
      await tester.tap(toggleFinder, warnIfMissed: false);

      await tester.pumpUntil(
        () => !controller.presentation.isNotesOpen.value,
        debugLabel: 'notes panel close',
        onTimeout: () => describeDeckControllerState(controller),
      );
      assertNoFlutterException(tester);
    });

    testWidgets('thumbnail workflow supports navigation and regenerate', (
      tester,
    ) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(2));
      final totalSlides = controller.slides.value.length;
      expect(totalSlides, 2);

      final firstSlideKey = controller.slides.value.first.key;

      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.presentation.isMenuOpen.value,
        debugLabel: 'menu open for thumbnails',
        onTimeout: () => describeDeckControllerState(controller),
      );

      final thumb1 = find.byKey(const ValueKey<String>('slide-thumbnail-1'));
      await tester.pumpUntil(
        () => thumb1.evaluate().isNotEmpty,
        debugLabel: 'slide thumbnail 1 visible',
        onTimeout: () => describeDeckControllerState(controller),
      );
      await tester.ensureVisible(thumb1.first);
      await tester.tap(thumb1.first, warnIfMissed: false);
      await tester.pumpFor(const Duration(milliseconds: 300));

      final thumb2 = find.byKey(const ValueKey<String>('slide-thumbnail-2'));
      await tester.pumpUntil(
        () => thumb2.evaluate().isNotEmpty,
        debugLabel: 'slide thumbnail 2 visible',
        onTimeout: () => describeDeckControllerState(controller),
      );
      await tester.ensureVisible(thumb2.first);
      await tester.tap(thumb2.first, warnIfMissed: false);
      await tester.pumpUntil(
        () => controller.presentation.currentIndex.value == 1,
        debugLabel: 'thumbnail navigation to slide 2',
        onTimeout: () => describeDeckControllerState(controller),
      );

      await tester.tapByLabel('Regenerate thumbnails');
      await tester.pumpFor(const Duration(milliseconds: 300));

      expect(controller.presentation.getThumbnail(firstSlideKey), isNotNull);
      expect(find.textContaining('Error loading presentation'), findsNothing);
      assertNoFlutterException(tester);
    });
  });
}
