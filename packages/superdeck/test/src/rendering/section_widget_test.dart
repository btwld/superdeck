import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/rendering/blocks/block_widget.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../fixtures/slide_fixtures.dart';
import '../../helpers/layout_assertions.dart';
import '../../helpers/slide_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SectionWidget', () {
    group('basic rendering', () {
      testWidgets('renders single block in section', (tester) async {
        await SlideTestHarness.pumpSlide(tester, SlideFixtures.singleColumn());

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
        final slide = Slide(key: 'empty-section', sections: [SectionBlock([])]);

        await SlideTestHarness.pumpSlide(tester, slide);
        expect(tester.takeException(), isNull);
      });
    });

    group('horizontal flex distribution', () {
      testWidgets('spacing zero preserves existing equal rectangles', (
        tester,
      ) async {
        _setSlideViewport(tester);
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'zero-spacing',
            sections: [
              SectionBlock([ContentBlock('Left'), ContentBlock('Right')]),
            ],
          ),
        );

        final sectionRect = tester.getRect(find.byType(SectionWidget));
        final blocks = find.byType(BlockWidget);
        final firstRect = tester.getRect(blocks.at(0));
        final secondRect = tester.getRect(blocks.at(1));

        expect(sectionRect.width, 1280);
        expect(firstRect.width, 640);
        expect(secondRect.width, 640);
        expect(firstRect.left, sectionRect.left);
        expect(secondRect.left, sectionRect.left + 640);
      });

      testWidgets('one block ignores spacing and fills the section', (
        tester,
      ) async {
        _setSlideViewport(tester);
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'single-block-spacing',
            sections: [
              SectionBlock([ContentBlock('Only')], spacing: 40),
            ],
          ),
        );

        final sectionRect = tester.getRect(find.byType(SectionWidget));
        final blockRect = tester.getRect(find.byType(BlockWidget));

        expect(blockRect, sectionRect);
      });

      testWidgets('two equal blocks reserve requested spacing', (tester) async {
        _setSlideViewport(tester);
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'two-block-spacing',
            sections: [
              SectionBlock([
                ContentBlock('Left'),
                ContentBlock('Right'),
              ], spacing: 40),
            ],
          ),
        );

        final sectionRect = tester.getRect(find.byType(SectionWidget));
        final blocks = find.byType(BlockWidget);
        final firstRect = tester.getRect(blocks.at(0));
        final secondRect = tester.getRect(blocks.at(1));

        expect(firstRect.width, 620);
        expect(secondRect.width, 620);
        expect(firstRect.left, sectionRect.left);
        expect(secondRect.left, sectionRect.left + 660);
      });

      testWidgets('three weighted blocks preserve flex after gaps', (
        tester,
      ) async {
        _setSlideViewport(tester);
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'weighted-spacing',
            sections: [
              SectionBlock([
                ContentBlock('One', flex: 1),
                ContentBlock('Two', flex: 2),
                ContentBlock('Three', flex: 1),
              ], spacing: 20),
            ],
          ),
        );

        final sectionRect = tester.getRect(find.byType(SectionWidget));
        final blocks = find.byType(BlockWidget);
        final firstRect = tester.getRect(blocks.at(0));
        final secondRect = tester.getRect(blocks.at(1));
        final thirdRect = tester.getRect(blocks.at(2));

        expect(firstRect.width, 310);
        expect(secondRect.width, 620);
        expect(thirdRect.width, 310);
        expect(firstRect.left, sectionRect.left);
        expect(secondRect.left, sectionRect.left + 330);
        expect(thirdRect.left, sectionRect.left + 970);
      });

      testWidgets('oversized spacing clamps children inside the section', (
        tester,
      ) async {
        _setSlideViewport(tester);
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'oversized-spacing',
            sections: [
              SectionBlock([
                ContentBlock('One'),
                ContentBlock('Two'),
                ContentBlock('Three'),
              ], spacing: 1000),
            ],
          ),
        );

        final sectionRect = tester.getRect(find.byType(SectionWidget));
        final blocks = find.byType(BlockWidget);
        final rects = [
          tester.getRect(blocks.at(0)),
          tester.getRect(blocks.at(1)),
          tester.getRect(blocks.at(2)),
        ];

        for (final rect in rects) {
          expect(rect.width.isFinite, isTrue);
          expect(rect.width, greaterThanOrEqualTo(0));
          expect(rect.left, greaterThanOrEqualTo(sectionRect.left));
          expect(rect.right, lessThanOrEqualTo(sectionRect.right));
        }
        expect(rects.map((rect) => rect.left - sectionRect.left), [
          0,
          640,
          1280,
        ]);
      });

      testWidgets('two blocks with equal flex have equal widths', (
        tester,
      ) async {
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

      testWidgets('two blocks with 1:2 flex have correct width ratio', (
        tester,
      ) async {
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
        await SlideTestHarness.pumpSlide(tester, SlideFixtures.singleColumn());

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
          SlideFixtures.contentAndWidget(),
        );

        tester.expectBlockCount(2);
        expect(find.byType(BlockWidget), findsOneWidget);
        expect(find.byType(CustomBlockWidget), findsOneWidget);
        expect(find.textContaining('Error building widget'), findsNothing);
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

void _setSlideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
