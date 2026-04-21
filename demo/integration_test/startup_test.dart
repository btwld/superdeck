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
      expect(controller.session.hasFatalError.value, isFalse);
      expect(controller.presentation.totalSlides.value, greaterThan(0));
      expect(controller.presentation.currentIndex.value, 0);
      expect(controller.presentation.currentSlide.value, isNotNull);
      expect(find.textContaining('Error loading presentation'), findsNothing);
      assertNoFlutterException(tester);
    });

    testWidgets('app transitions through loading state', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pump();

      final controller = findDeckController(tester);

      if (controller != null) {
        expect(
          controller.session.isLoading.value ||
              controller.presentation.totalSlides.value > 0,
          isTrue,
          reason: 'App should be loading or have slides available',
        );
        await tester.waitForSlidesLoaded(controller);
        expect(controller.session.isLoading.value, isFalse);
        assertNoFlutterException(tester);
        return;
      }

      await tester.pumpFor(const Duration(seconds: 1));
      final delayedController = findDeckController(tester);
      expect(delayedController, isNotNull);
      await tester.waitForSlidesLoaded(delayedController!);
      assertNoFlutterException(tester);
    });

    testWidgets('asset-heavy slide loads without errors', (tester) async {
      final controller = await tester.pumpTestApp();
      expect(
        controller.presentation.totalSlides.value,
        greaterThan(4),
        reason: 'Demo deck should keep the asset-heavy slide at index 4.',
      );
      const targetIndex = 4;

      await tester.navigateToSlide(controller, targetIndex);
      expect(controller.presentation.currentIndex.value, targetIndex);
      expect(controller.session.hasFatalError.value, isFalse);
      expect(find.textContaining('Error loading presentation'), findsNothing);
      assertNoFlutterException(tester);
    });
  });
}
