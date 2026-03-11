import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Startup', () {
    setUpAll(() async {
      await TestApp.initialize();
    });

    testWidgets('app starts and loads deck without errors', (tester) async {
      final controller = await tester.pumpTestApp();
      expect(controller.hasError.value, isFalse);
      expect(controller.totalSlides.value, greaterThan(0));
      expect(controller.currentIndex.value, 0);
      expect(controller.currentSlide.value, isNotNull);
      expect(find.textContaining('Error loading presentation'), findsNothing);
      assertOnlyLayoutOverflowOrNoException(tester);
    });

    testWidgets('app transitions through loading state', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pump();

      final controller = findDeckController(tester);

      if (controller != null) {
        expect(
          controller.isLoading.value || controller.totalSlides.value > 0,
          isTrue,
          reason: 'App should be loading or have slides available',
        );
        await tester.waitForSlidesLoaded(controller);
        expect(controller.isLoading.value, isFalse);
        return;
      }

      await tester.pumpFor(const Duration(seconds: 1));
      final delayedController = findDeckController(tester);
      expect(delayedController, isNotNull);
      await tester.waitForSlidesLoaded(delayedController!);
    });

    testWidgets('asset-heavy slide loads without errors', (tester) async {
      final controller = await tester.pumpTestApp();
      final targetIndex = clampSlideIndex(controller, 4);

      await tester.navigateToSlide(controller, targetIndex);
      expect(controller.currentIndex.value, targetIndex);
      expect(controller.hasError.value, isFalse);
      expect(find.textContaining('Error loading presentation'), findsNothing);
      assertOnlyLayoutOverflowOrNoException(tester);
    });
  });
}
