import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

import '../fixtures/slide_fixtures.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/slide_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alignment Behavior', () {
    group('all 9 alignments', () {
      final alignmentTests = {
        ContentAlignment.topLeft: Alignment.topLeft,
        ContentAlignment.topCenter: Alignment.topCenter,
        ContentAlignment.topRight: Alignment.topRight,
        ContentAlignment.centerLeft: Alignment.centerLeft,
        ContentAlignment.center: Alignment.center,
        ContentAlignment.centerRight: Alignment.centerRight,
        ContentAlignment.bottomLeft: Alignment.bottomLeft,
        ContentAlignment.bottomCenter: Alignment.bottomCenter,
        ContentAlignment.bottomRight: Alignment.bottomRight,
      };

      alignmentTests.forEach((contentAlign, expected) {
        testWidgets('$contentAlign aligns content', (tester) async {
          await SlideTestHarness.pumpSlide(
            tester,
            SlideFixtures.withAlignment(contentAlign),
          );

          final alignFinder = find.byType(Align).first;
          final alignWidget = tester.widget<Align>(alignFinder);
          expect(alignWidget.alignment, expected);
        });
      });
    });

    group('alignment grid', () {
      testWidgets('renders all 9 in 3x3 grid', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.allAlignments(),
        );
        tester.expectBlockCount(9);
        tester.expectSectionCount(3);
        expect(tester.takeException(), isNull);
      });

      testWidgets('grid blocks do not overlap meaningfully', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.allAlignments(),
        );
        final blocks = find.byType(BlockWidget);
        final rects = List.generate(9, (i) => tester.getRect(blocks.at(i)));
        for (int i = 0; i < rects.length; i++) {
          for (int j = i + 1; j < rects.length; j++) {
            final intersection = rects[i].intersect(rects[j]);
            expect(
              intersection.isEmpty || intersection.width < 5 || intersection.height < 5,
              true,
            );
          }
        }
      });
    });

    group('content size variations', () {
      testWidgets('small content centers correctly', (tester) async {
        final slide = Slide(
          key: 'small-centered',
          sections: [
            SectionBlock([
              ContentBlock('Hi', align: ContentAlignment.center),
            ]),
          ],
        );
        await SlideTestHarness.pumpSlide(tester, slide);

        final block = find.byType(BlockWidget);
        final blockRect = tester.getRect(block);
        final text = find.textContaining('Hi');
        final textRect = tester.getRect(text);
        expect((blockRect.center.dx - textRect.center.dx).abs(), lessThan(50));
      });

      testWidgets('large scrollable content respects alignment', (tester) async {
        final slide = Slide(
          key: 'large-top-left',
          sections: [
            SectionBlock([
              ContentBlock(
                '# Large Heading\n\n${'Line\n' * 20}',
                align: ContentAlignment.topLeft,
                scrollable: true,
              ),
            ]),
          ],
        );
        await SlideTestHarness.pumpSlide(tester, slide);
        final alignWidget = tester.widget<Align>(find.byType(Align).first);
        expect(alignWidget.alignment, Alignment.topLeft);
      });
    });

    group('alignment in columns', () {
      testWidgets('different alignments per column', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.allAlignments(),
        );
        tester.expectBlockCount(9);
        expect(tester.takeException(), isNull);
      });
    });

    group('alignment in sections', () {
      testWidgets('different alignments per section', (tester) async {
        final slide = Slide(
          key: 'section-alignments',
          sections: [
            SectionBlock([ContentBlock('Top', align: ContentAlignment.topCenter)]),
            SectionBlock([ContentBlock('Bottom', align: ContentAlignment.bottomCenter)]),
          ],
        );

        await SlideTestHarness.pumpSlide(tester, slide);
        tester.expectSectionCount(2);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
