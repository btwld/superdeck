import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Keyboard Navigation', () {
    setUpAll(() async {
      await TestApp.initialize();
    });

    testWidgets('Meta+ArrowRight advances to next slide', (tester) async {
      final controller = await tester.pumpTestApp();
      if (controller.presentation.totalSlides.value <= 1) return;

      expect(controller.presentation.currentIndex.value, 0);
      await tester.sendMetaKey(LogicalKeyboardKey.arrowRight);
      await tester.pumpUntil(
        () => controller.presentation.currentIndex.value == 1,
        timeout: const Duration(seconds: 5),
        debugLabel: 'Meta+ArrowRight navigation',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(controller.presentation.currentIndex.value, 1);
    });

    testWidgets('Meta+ArrowDown advances to next slide', (tester) async {
      final controller = await tester.pumpTestApp();
      if (controller.presentation.totalSlides.value <= 1) return;

      expect(controller.presentation.currentIndex.value, 0);
      await tester.sendMetaKey(LogicalKeyboardKey.arrowDown);
      await tester.pumpUntil(
        () => controller.presentation.currentIndex.value == 1,
        timeout: const Duration(seconds: 5),
        debugLabel: 'Meta+ArrowDown navigation',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(controller.presentation.currentIndex.value, 1);
    });

    testWidgets('Meta+ArrowLeft goes to previous slide', (tester) async {
      final controller = await tester.pumpTestApp();
      if (controller.presentation.totalSlides.value <= 1) return;

      await tester.navigateToSlide(controller, 1);

      await tester.sendMetaKey(LogicalKeyboardKey.arrowLeft);
      await tester.pumpUntil(
        () => controller.presentation.currentIndex.value == 0,
        timeout: const Duration(seconds: 5),
        debugLabel: 'Meta+ArrowLeft navigation',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(controller.presentation.currentIndex.value, 0);
    });

    testWidgets('Meta+ArrowUp goes to previous slide', (tester) async {
      final controller = await tester.pumpTestApp();
      if (controller.presentation.totalSlides.value <= 1) return;

      await tester.navigateToSlide(controller, 1);

      await tester.sendMetaKey(LogicalKeyboardKey.arrowUp);
      await tester.pumpUntil(
        () => controller.presentation.currentIndex.value == 0,
        timeout: const Duration(seconds: 5),
        debugLabel: 'Meta+ArrowUp navigation',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(controller.presentation.currentIndex.value, 0);
    });

    testWidgets('arrow keys without Meta do not navigate', (tester) async {
      final controller = await tester.pumpTestApp();
      if (controller.presentation.totalSlides.value <= 1) return;

      expect(controller.presentation.currentIndex.value, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpFor(const Duration(milliseconds: 300));
      expect(controller.presentation.currentIndex.value, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpFor(const Duration(milliseconds: 300));
      expect(controller.presentation.currentIndex.value, 0);
    });

    testWidgets('Meta+ArrowRight on last slide stays on last', (tester) async {
      final controller = await tester.pumpTestApp();
      final lastIndex = controller.presentation.totalSlides.value - 1;
      await tester.navigateToSlide(controller, lastIndex);

      await tester.sendMetaKey(LogicalKeyboardKey.arrowRight);
      await tester.pumpFor(const Duration(milliseconds: 300));
      expect(controller.presentation.currentIndex.value, lastIndex);
    });
  });
}
