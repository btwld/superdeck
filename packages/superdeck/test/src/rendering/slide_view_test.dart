import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck/src/deck/slide_configuration_builder.dart';
import 'package:superdeck/src/rendering/blocks/block_widget.dart';
import 'package:superdeck/src/rendering/slides/slide_view.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/layout_assertions.dart';
import '../../helpers/slide_test_harness.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlideView', () {
    group('basic rendering', () {
      testWidgets('renders single section slide', (tester) async {
        await SlideTestHarness.pumpSlide(tester, SlideFixtures.singleColumn());

        expect(find.byType(SlideView), findsOneWidget);
        tester.expectSectionCount(1);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders empty slide without errors', (tester) async {
        final emptySlide = Slide(key: 'empty', sections: []);
        await SlideTestHarness.pumpSlide(tester, emptySlide);

        expect(find.byType(SlideView), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders in debug mode without throwing', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnEqual(),
          debug: true,
        );
        expect(find.byType(SlideView), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders the provided slide configuration instance', (
        tester,
      ) async {
        final slide = Slide(key: 'simple-slide');
        final config = SlideConfiguration(
          slide: slide,
          slideIndex: 0,
          style: SlideStyle(),
          thumbnailKey: '',
        );

        await tester.pumpWithScaffold(
          InheritedData(data: config, child: SlideView(config)),
        );

        final finder = find.byType(SlideView);
        expect(finder, findsOneWidget);
        expect(tester.widget<SlideView>(finder).slide, same(config));
      });
    });

    group('section layout - vertical flex', () {
      testWidgets('two sections with equal flex have equal heights', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoSectionEqual(),
        );

        final sections = find.byType(SectionWidget);
        tester.expectFlexRatio(
          sections.at(0),
          sections.at(1),
          1,
          1,
          axis: Axis.vertical,
        );
      });

      testWidgets('two sections with 1:2 flex have correct height ratio', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoSectionWeighted(topFlex: 1, bottomFlex: 2),
        );

        final sections = find.byType(SectionWidget);
        tester.expectFlexRatio(
          sections.at(0),
          sections.at(1),
          1,
          2,
          axis: Axis.vertical,
        );
      });

      testWidgets('three sections follow 1:3:1 flex distribution', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.threeSectionLayout(),
        );

        final sections = find.byType(SectionWidget);
        tester.expectFlexDistribution(
          [sections.at(0), sections.at(1), sections.at(2)],
          [1, 3, 1],
          axis: Axis.vertical,
        );
      });

      testWidgets('sections stack vertically without overlap', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoSectionEqual(),
        );

        final sections = find.byType(SectionWidget);
        final rect1 = tester.getRect(sections.at(0));
        final rect2 = tester.getRect(sections.at(1));
        expect(rect2.top, closeTo(rect1.bottom, 1.0));
      });

      testWidgets('header and footer reserve vertical space for sections', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoSectionEqual(),
          parts: const SlideParts(
            header: PreferredSize(
              preferredSize: Size.fromHeight(80),
              child: SizedBox.shrink(),
            ),
            footer: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: SizedBox.shrink(),
            ),
          ),
        );

        final sections = find.byType(SectionWidget);
        final topSection = tester.getRect(sections.at(0));
        final bottomSection = tester.getRect(sections.at(1));

        expect(topSection.top, closeTo(80, 1.0));
        expect(bottomSection.bottom, closeTo(680, 1.0));
        expect(topSection.height + bottomSection.height, closeTo(600, 1.0));
      });

      testWidgets('fullscreen sections receive full slide size', (
        tester,
      ) async {
        final slide = Slide(
          key: 'fullscreen',
          options: SlideOptions(layout: SlideLayout.fullscreen),
          sections: [
            SectionBlock([ContentBlock('Fullscreen content')]),
          ],
        );
        final configuration =
            const SlideConfigurationBuilder().buildConfigurations(
              [slide],
              DeckOptions(
                parts: const SlideParts(
                  header: PreferredSize(
                    preferredSize: Size.fromHeight(80),
                    child: SizedBox.shrink(),
                  ),
                  footer: PreferredSize(
                    preferredSize: Size.fromHeight(40),
                    child: SizedBox.shrink(),
                  ),
                ),
              ),
            ).single;

        await SlideTestHarness.pumpConfiguration(tester, configuration);

        final section = find.byType(SectionWidget);
        final sectionRect = tester.getRect(section);

        expect(sectionRect.top, 0);
        expect(sectionRect.size, const Size(1280, 720));
      });
    });

    group('slide size', () {
      testWidgets('renders at default resolution (kResolution)', (
        tester,
      ) async {
        final originalSize = tester.view.physicalSize;
        final originalDpr = tester.view.devicePixelRatio;
        tester.view
          ..physicalSize = const Size(1600, 1000)
          ..devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view
            ..physicalSize = originalSize
            ..devicePixelRatio = originalDpr;
        });

        await SlideTestHarness.pumpSlide(tester, SlideFixtures.singleColumn());

        final slideView = find.byType(SlideView);
        final size = tester.getSize(slideView);

        expect(size.width, 1280);
        expect(size.height, 720);
      });

      testWidgets('sections fill available width', (tester) async {
        final originalSize = tester.view.physicalSize;
        final originalDpr = tester.view.devicePixelRatio;
        tester.view
          ..physicalSize = const Size(1600, 1000)
          ..devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view
            ..physicalSize = originalSize
            ..devicePixelRatio = originalDpr;
        });

        await SlideTestHarness.pumpSlide(tester, SlideFixtures.singleColumn());

        final section = find.byType(SectionWidget);
        final size = tester.getSize(section);

        expect(size.width, 1280);
      });
    });
  });
}
