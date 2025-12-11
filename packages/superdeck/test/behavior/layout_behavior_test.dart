import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck/src/rendering/slides/slide_view.dart';

import '../fixtures/slide_fixtures.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/slide_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Layout Behavior', () {
    group('fixture rendering', () {
      final fixtures = {
        'singleColumn': SlideFixtures.singleColumn,
        'twoColumnEqual': SlideFixtures.twoColumnEqual,
        'twoColumnWeighted': () => SlideFixtures.twoColumnWeighted(),
        'threeColumn': SlideFixtures.threeColumn,
        'threeColumnWeighted': () => SlideFixtures.threeColumnWeighted(),
        'twoSectionEqual': SlideFixtures.twoSectionEqual,
        'twoSectionWeighted': () => SlideFixtures.twoSectionWeighted(),
        'threeSectionLayout': () => SlideFixtures.threeSectionLayout(),
        'multiSectionMultiColumn': SlideFixtures.multiSectionMultiColumn,
        'allAlignments': SlideFixtures.allAlignments,
        'scrollableBlock': () => SlideFixtures.scrollableBlock(),
        'nonScrollableBlock': () => SlideFixtures.nonScrollableBlock(),
        'withCodeBlock': () => SlideFixtures.withCodeBlock(),
        'mixedMarkdown': SlideFixtures.mixedMarkdown,
      };

      fixtures.forEach((name, builder) {
        testWidgets('$name renders without errors', (tester) async {
          await SlideTestHarness.pumpSlide(tester, builder());
          expect(find.byType(SlideView), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      });
    });

    group('column layouts', () {
      testWidgets('single column fills width', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.singleColumn(),
        );
        final block = find.byType(BlockWidget);
        final size = tester.getSize(block);
        expect(size.width, greaterThan(700));
      });

      testWidgets('two equal columns split width roughly 50/50', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnEqual(),
        );
        final blocks = find.byType(BlockWidget);
        final size1 = tester.getSize(blocks.at(0));
        final size2 = tester.getSize(blocks.at(1));
        expect((size1.width - size2.width).abs(), lessThan(10));
      });

      testWidgets('1:2 columns reflect ratio', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnWeighted(leftFlex: 1, rightFlex: 2),
        );
        final blocks = find.byType(BlockWidget);
        tester.expectFlexRatio(blocks.at(0), blocks.at(1), 1, 2);
      });

      testWidgets('1:2:1 columns reflect distribution', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.threeColumnWeighted(),
        );
        final blocks = find.byType(BlockWidget);
        tester.expectFlexDistribution(
          [blocks.at(0), blocks.at(1), blocks.at(2)],
          [1, 2, 1],
        );
      });
    });

    group('section layouts', () {
      testWidgets('two equal sections split height roughly 50/50', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoSectionEqual(),
        );
        final sections = find.byType(SectionWidget);
        final size1 = tester.getSize(sections.at(0));
        final size2 = tester.getSize(sections.at(1));
        expect((size1.height - size2.height).abs(), lessThan(10));
      });

      testWidgets('1:2 sections reflect ratio', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoSectionWeighted(topFlex: 1, bottomFlex: 2),
        );
        final sections = find.byType(SectionWidget);
        tester.expectFlexRatio(sections.at(0), sections.at(1), 1, 2, axis: Axis.vertical);
      });

      testWidgets('header/body/footer 1:3:1', (tester) async {
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
    });

    group('complex & edge cases', () {
      testWidgets('multi-section multi-column renders', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.multiSectionMultiColumn(),
        );
        tester.expectSectionCount(2);
        tester.expectBlockCount(3);
        expect(tester.takeException(), isNull);
      });

      testWidgets('very wide flex ratio 1:10', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnWeighted(leftFlex: 1, rightFlex: 10),
        );
        final blocks = find.byType(BlockWidget);
        tester.expectFlexRatio(blocks.at(0), blocks.at(1), 1, 10);
      });

      testWidgets('many columns (5)', (tester) async {
        final slide = Slide(
          key: 'five-columns',
          sections: [
            SectionBlock([
              ContentBlock('1'),
              ContentBlock('2'),
              ContentBlock('3'),
              ContentBlock('4'),
              ContentBlock('5'),
            ]),
          ],
        );
        await SlideTestHarness.pumpSlide(tester, slide);
        tester.expectBlockCount(5);
        expect(tester.takeException(), isNull);
      });

      testWidgets('many sections (5)', (tester) async {
        final slide = Slide(
          key: 'five-sections',
          sections: List.generate(
            5,
            (i) => SectionBlock([ContentBlock('Section $i')]),
          ),
        );
        await SlideTestHarness.pumpSlide(tester, slide);
        tester.expectSectionCount(5);
        expect(tester.takeException(), isNull);
      });

      testWidgets('non-scrollable long content does not throw overflow', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.nonScrollableBlock(lineCount: 200),
        );
        expect(tester.takeException(), isNull);
      });
    });
  });
}
