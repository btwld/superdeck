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
      final controller = await tester.pumpTestApp();
      expect(controller.currentIndex.value, 0);

      if (controller.totalSlides.value <= 1) {
        expect(controller.canGoNext.value, isFalse);
        return;
      }

      expect(controller.canGoNext.value, isTrue);
      await controller.nextSlide();
      await tester.pumpUntil(
        () => controller.currentIndex.value == 1,
        timeout: const Duration(seconds: 5),
        debugLabel: 'navigation to slide 1',
      );
      expect(controller.currentIndex.value, 1);
    });

    testWidgets('previousSlide returns to first slide', (tester) async {
      final controller = await tester.pumpTestApp();
      if (controller.totalSlides.value <= 1) return;

      await tester.navigateToSlide(controller, 1);
      expect(controller.canGoPrevious.value, isTrue);

      await controller.previousSlide();
      await tester.pumpUntil(
        () => controller.currentIndex.value == 0,
        timeout: const Duration(seconds: 5),
        debugLabel: 'navigation back to slide 0',
      );
      expect(controller.currentIndex.value, 0);
    });

    testWidgets('canGoPrevious is false on first slide', (tester) async {
      final controller = await tester.pumpTestApp();
      expect(controller.currentIndex.value, 0);
      expect(controller.canGoPrevious.value, isFalse);
    });

    testWidgets('canGoNext is false on last slide', (tester) async {
      final controller = await tester.pumpTestApp();
      final lastIndex = controller.totalSlides.value - 1;
      await tester.navigateToSlide(controller, lastIndex);
      expect(controller.canGoNext.value, isFalse);
    });

    testWidgets('goToSlide navigates to specific slide', (tester) async {
      final controller = await tester.pumpTestApp();
      final targetIndex = clampSlideIndex(controller, 3);

      await tester.navigateToSlide(controller, targetIndex);
      expect(controller.currentIndex.value, targetIndex);
    });

    testWidgets('rapid sequential navigation does not corrupt state', (
      tester,
    ) async {
      final controller = await tester.pumpTestApp();
      if (controller.totalSlides.value <= 5) return;

      // Fire multiple goToSlide calls without awaiting each
      controller.goToSlide(5);
      controller.goToSlide(2);
      controller.goToSlide(4);
      controller.goToSlide(1);

      // Let the transition duration and router settle
      await tester.pumpFor(const Duration(seconds: 2));

      // State should be consistent — no errors, valid index
      expect(controller.hasError.value, isFalse);
      expect(
        controller.currentIndex.value,
        inInclusiveRange(0, controller.totalSlides.value - 1),
      );
      expect(controller.currentSlide.value, isNotNull);
    });

    testWidgets('navigation updates currentSlide data', (tester) async {
      final controller = await tester.pumpTestApp();
      final targetIndex = clampSlideIndex(controller, 2);

      final slide0 = controller.currentSlide.value;
      expect(slide0, isNotNull);
      expect(slide0!.slideIndex, 0);

      await tester.navigateToSlide(controller, targetIndex);
      final currentSlide = controller.currentSlide.value;
      expect(currentSlide, isNotNull);
      expect(currentSlide!.slideIndex, targetIndex);
    });
  });
}
