import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

import '../fixtures/slide_fixtures.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/slide_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SectionWidget', () {
    group('basic rendering', () {
      testWidgets('renders single block in section', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.singleColumn(),
        );

        tester.expectSectionCount(1);
        tester.expectBlockCount(1);
      });

      testWidgets('renders multiple blocks in section', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnEqual(),
        );

        tester.expectSectionCount(1);
        tester.expectBlockCount(2);
      });

      testWidgets('handles empty section without error', (tester) async {
        final slide = Slide(
          key: 'empty-section',
          sections: [SectionBlock([])],
        );

        await SlideTestHarness.pumpSlide(tester, slide);
        expect(tester.takeException(), isNull);
      });
    });

    group('horizontal flex distribution', () {
      testWidgets('two blocks with equal flex have equal widths', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnEqual(),
        );

        final blocks = find.byType(BlockWidget);
        tester.expectFlexRatio(
          blocks.at(0),
          blocks.at(1),
          1,
          1,
          axis: Axis.horizontal,
        );
      });

      testWidgets('two blocks with 1:2 flex have correct width ratio', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnWeighted(leftFlex: 1, rightFlex: 2),
        );

        final blocks = find.byType(BlockWidget);
        tester.expectFlexRatio(
          blocks.at(0),
          blocks.at(1),
          1,
          2,
          axis: Axis.horizontal,
        );
      });

      testWidgets('three blocks follow 1:2:1 distribution', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.threeColumnWeighted(flex1: 1, flex2: 2, flex3: 1),
        );

        final blocks = find.byType(BlockWidget);
        tester.expectFlexDistribution(
          [blocks.at(0), blocks.at(1), blocks.at(2)],
          [1, 2, 1],
          axis: Axis.horizontal,
        );
      });

      testWidgets('single block fills section width', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.singleColumn(),
        );

        final section = find.byType(SectionWidget);
        final block = find.byType(BlockWidget);

        final sectionWidth = tester.getSize(section).width;
        final blockWidth = tester.getSize(block).width;

        expect(blockWidth, closeTo(sectionWidth, 1.0));
      });
    });

    group('block positioning', () {
      testWidgets('blocks are side by side without overlap', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnEqual(),
        );

        final blocks = find.byType(BlockWidget);
        final rect1 = tester.getRect(blocks.at(0));
        final rect2 = tester.getRect(blocks.at(1));

        expect(rect2.left, closeTo(rect1.right, 1.0));
        expect(rect1.top, closeTo(rect2.top, 1.0));
      });

      testWidgets('blocks fill section height', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnEqual(),
        );

        final section = find.byType(SectionWidget);
        final blocks = find.byType(BlockWidget);

        final sectionHeight = tester.getSize(section).height;
        final blockHeight = tester.getSize(blocks.first).height;

        expect(blockHeight, closeTo(sectionHeight, 1.0));
      });
    });

    group('mixed block types', () {
      testWidgets('renders content and widget blocks together', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.withCustomWidget(widgetName: 'qrcode'),
        );
        tester.expectBlockCount(1);
        expect(tester.takeException(), isNull);
      });
    });

    group('debug mode', () {
      testWidgets('does not throw when debug enabled', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.twoColumnEqual(),
          debug: true,
        );
        expect(tester.takeException(), isNull);
      });
    });
  });
}
