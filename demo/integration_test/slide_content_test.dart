import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck_core/superdeck_core.dart';

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
      assertPresentationHealthy(tester, controller);
      await captureAllSlidesForReview(
        tester,
        controller,
        suiteName: 'slide_content',
        scenarioName: 'first slide has content blocks',
      );
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
      assertPresentationHealthy(tester, controller);
      await captureAllSlidesForReview(
        tester,
        controller,
        suiteName: 'slide_content',
        scenarioName: 'slide counter navigation',
      );
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
      assertPresentationHealthy(tester, controller);
      await captureAllSlidesForReview(
        tester,
        controller,
        suiteName: 'slide_content',
        scenarioName: 'unique slide keys',
      );
    });

    testWidgets('representative authored layouts and widgets render', (
      tester,
    ) async {
      final controller = await tester.pumpTestAppWithSlides(
        _representativeSlides(),
      );

      expect(controller.presentation.totalSlides.value, 3);

      for (var i = 0; i < controller.presentation.totalSlides.value; i++) {
        await tester.navigateToSlide(controller, i);
        expect(controller.presentation.currentSlide.value?.slideIndex, i);
        assertPresentationHealthy(tester, controller);
      }

      final layoutSlide = controller.slides.value[0];
      expect(layoutSlide.sections, hasLength(2));
      expect(layoutSlide.sections.first.blocks, hasLength(2));
      expect(layoutSlide.sections.first.blocks[1].scrollable, isTrue);

      final widgetSlide = controller.slides.value[1];
      final widgetBlocks = widgetSlide.sections.single.blocks
          .whereType<WidgetBlock>()
          .toList();
      expect(widgetBlocks.map((block) => block.name), ['qrcode', 'image']);

      final customSlide = controller.slides.value[2];
      expect(
        customSlide.sections.single.blocks.whereType<WidgetBlock>().single.name,
        'mix-simple-box',
      );
      await captureAllSlidesForReview(
        tester,
        controller,
        suiteName: 'slide_content',
        scenarioName: 'representative authored layouts and widgets',
      );
    });
  });
}

List<Slide> _representativeSlides() {
  return [
    Slide(
      key: 'representative-layout',
      sections: [
        SectionBlock([
          ContentBlock(
            '## Left\n\nTop-left content.',
            flex: 1,
            align: ContentAlignment.topLeft,
          ),
          ContentBlock(
            '## Right\n\n${List.filled(18, 'Scrollable line').join('\n')}',
            flex: 2,
            scrollable: true,
          ),
        ], flex: 2),
        SectionBlock([
          ContentBlock('Footer row', align: ContentAlignment.bottomRight),
        ], flex: 1),
      ],
    ),
    Slide(
      key: 'representative-builtins',
      sections: [
        SectionBlock([
          WidgetBlock(
            name: 'qrcode',
            args: const {
              'text': 'https://superdeck.dev',
              'size': 96.0,
              'errorCorrection': 'high',
            },
          ),
          WidgetBlock(
            name: 'image',
            args: const {
              'src': _transparentPixelDataUri,
              'fit': 'contain',
              'width': 96.0,
              'height': 96.0,
            },
          ),
        ]),
      ],
    ),
    Slide(
      key: 'representative-custom-widget',
      sections: [
        SectionBlock([
          ContentBlock('## Custom Widget'),
          WidgetBlock(name: 'mix-simple-box'),
        ]),
      ],
    ),
  ];
}

const _transparentPixelDataUri =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
