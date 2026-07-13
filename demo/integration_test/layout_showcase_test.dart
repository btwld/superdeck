import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'package:superdeck_example/src/layout_showcase/layout_showcase.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('layout showcase', () {
    setUpAll(TestApp.initialize);

    testWidgets('renders and captures every showcase slide', (tester) async {
      tester.view
        ..physicalSize = const Size(1280, 720)
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });

      final loader = FileDeckLoader(workspace: layoutShowcaseWorkspace);
      addTearDown(loader.dispose);

      await tester.pumpWidget(
        TestApp(
          deckLoader: loader,
          workspace: layoutShowcaseWorkspace,
          options: layoutShowcaseOptions(),
        ),
      );
      await tester.pumpFor(const Duration(milliseconds: 250));
      await tester.pumpUntil(
        () => findDeckController(tester) != null,
        debugLabel: 'layout showcase controller',
      );

      final controller = findDeckController(tester)!;
      await tester.waitForSlidesLoaded(controller);

      expect(controller.presentation.totalSlides.value, 11);
      expect(find.text('The system makes room.'), findsOneWidget);

      final widgetBlocks = controller.slides.value
          .expand((slide) => slide.sections)
          .expand((section) => section.blocks)
          .whereType<WidgetBlock>()
          .toList();
      expect(
        widgetBlocks.where((block) => block.name == 'image'),
        hasLength(11),
      );
      expect(
        widgetBlocks
            .where((block) => block.name != 'image')
            .map((block) => block.name),
        ['showcaseMetric'],
      );
      assertPresentationHealthy(tester, controller);

      for (var index = 0; index < controller.slides.value.length; index++) {
        await tester.navigateToSlide(
          controller,
          index,
          context: 'layout showcase slide $index',
        );
        assertPresentationHealthy(tester, controller);
      }

      final screenshotsDir = await captureRenderedSlidesForReview(
        tester,
        controller,
        suiteName: 'layout_showcase',
        scenarioName: 'editorial_deck',
      );
      await assertReviewScreenshots(
        outputDir: screenshotsDir,
        expectedCount: 11,
      );
    });
  });
}
