import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation', () {
    setUpAll(() async {
      await TestApp.initialize();
    });

    testWidgets('nextSlide advances to second slide', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(2));
      expect(controller.presentation.currentIndex.value, 0);

      expect(controller.presentation.canGoNext.value, isTrue);
      unawaited(controller.presentation.nextSlide());
      await tester.pumpUntil(
        () => controller.presentation.currentIndex.value == 1,
        timeout: const Duration(seconds: 5),
        debugLabel: 'navigation to slide 1',
      );
      expect(controller.presentation.currentIndex.value, 1);
    });

    testWidgets('previousSlide returns to first slide', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(2));

      await tester.navigateToSlide(controller, 1);
      expect(controller.presentation.canGoPrevious.value, isTrue);

      unawaited(controller.presentation.previousSlide());
      await tester.pumpUntil(
        () => controller.presentation.currentIndex.value == 0,
        timeout: const Duration(seconds: 5),
        debugLabel: 'navigation back to slide 0',
      );
      expect(controller.presentation.currentIndex.value, 0);
    });

    testWidgets('canGoPrevious is false on first slide', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(2));
      expect(controller.presentation.currentIndex.value, 0);
      expect(controller.presentation.canGoPrevious.value, isFalse);
    });

    testWidgets('canGoNext is false on last slide', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(3));
      final lastIndex = controller.presentation.totalSlides.value - 1;
      await tester.navigateToSlide(controller, lastIndex);
      expect(controller.presentation.canGoNext.value, isFalse);
    });

    testWidgets('goToSlide navigates to specific slide', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(4));
      const targetIndex = 3;

      await tester.navigateToSlide(controller, targetIndex);
      expect(controller.presentation.currentIndex.value, targetIndex);
    });

    testWidgets('rapid sequential navigation does not corrupt state', (
      tester,
    ) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(6));

      // Fire multiple goToSlide calls without awaiting each
      controller.presentation.goToSlide(5);
      controller.presentation.goToSlide(2);
      controller.presentation.goToSlide(4);
      controller.presentation.goToSlide(1);

      // Let the transition duration and router settle
      await tester.pumpFor(const Duration(seconds: 2));

      // State should be consistent — no errors, valid index
      expect(controller.session.hasFatalError.value, isFalse);
      expect(
        controller.presentation.currentIndex.value,
        inInclusiveRange(0, controller.presentation.totalSlides.value - 1),
      );
      expect(controller.presentation.currentSlide.value, isNotNull);
    });

    testWidgets('navigation updates currentSlide data', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(3));
      const targetIndex = 2;

      final slide0 = controller.presentation.currentSlide.value;
      expect(slide0, isNotNull);
      expect(slide0!.slideIndex, 0);

      await tester.navigateToSlide(controller, targetIndex);
      final currentSlide = controller.presentation.currentSlide.value;
      expect(currentSlide, isNotNull);
      expect(currentSlide!.slideIndex, targetIndex);
    });
  });
}
