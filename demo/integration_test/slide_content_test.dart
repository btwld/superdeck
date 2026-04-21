import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Slide Content', () {
    setUpAll(() async {
      await TestApp.initialize();
    });

    testWidgets('first slide has content blocks', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(1));
      final slide = controller.presentation.currentSlide.value;
      expect(slide, isNotNull);
      expect(slide!.slideIndex, 0);

      final slideData = controller.slides.value.first;
      expect(slideData.sections, isNotEmpty);
      assertNoFlutterException(tester);
    });

    testWidgets('slide counter reflects correct position after navigation', (
      tester,
    ) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(2));
      final total = controller.presentation.totalSlides.value;

      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.presentation.isMenuOpen.value,
        debugLabel: 'menu open for counter check',
        onTimeout: () => describeDeckControllerState(controller),
      );

      expect(find.textContaining('1 of $total'), findsOneWidget);

      await tester.navigateToSlide(controller, 1);
      await tester.pumpFor(const Duration(milliseconds: 200));
      expect(find.textContaining('2 of $total'), findsOneWidget);
      assertNoFlutterException(tester);
    });

    testWidgets('each slide has unique keys', (tester) async {
      final controller = await tester.pumpTestAppWithSlides(makeSlides(3));
      final slides = controller.slides.value;

      expect(slides[0].key, isNot(equals(slides[1].key)));

      final slidesToCheck = slides.length > 3 ? 3 : slides.length;
      for (var i = 0; i < slidesToCheck; i++) {
        await tester.navigateToSlide(controller, i);
        expect(controller.presentation.currentSlide.value?.slideIndex, i);
      }
      assertNoFlutterException(tester);
    });
  });
}
