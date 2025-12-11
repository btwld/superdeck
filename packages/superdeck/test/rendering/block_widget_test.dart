import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

import '../fixtures/slide_fixtures.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/slide_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BlockWidget', () {
    group('basic rendering', () {
      testWidgets('renders markdown content', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.singleColumn(content: '# Hello World'),
        );

        expect(find.byType(BlockWidget), findsOneWidget);
        expect(find.textContaining('Hello World'), findsOneWidget);
      });

      testWidgets('renders with debug flag without errors', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.singleColumn(),
          debug: true,
        );
        expect(find.byType(BlockWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('alignment', () {
      for (final alignment in ContentAlignment.values) {
        testWidgets('content aligned to $alignment', (tester) async {
          await SlideTestHarness.pumpSlide(
            tester,
            SlideFixtures.withAlignment(alignment),
          );

          final alignWidget = find.byType(Align).first;
          final align = tester.widget<Align>(alignWidget);
          expect(align.alignment, _toAlignment(alignment));
        });
      }

      testWidgets('all 9 alignments render in grid', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.allAlignments(),
        );
        tester.expectBlockCount(9);
        expect(tester.takeException(), isNull);
      });
    });

    group('scrollable behavior', () {
      testWidgets('scrollable block wraps content in ScrollView', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.scrollableBlock(lineCount: 80),
        );
        tester.expectScrollable(find.byType(BlockWidget));
      });

      testWidgets('non-scrollable block clips overflow', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.nonScrollableBlock(lineCount: 80),
        );
        tester.expectNotScrollable(find.byType(BlockWidget));
      });

      testWidgets('scrollable block is NOT scrollable when exporting', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.scrollableBlock(lineCount: 80),
          isExporting: true,
        );
        tester.expectNotScrollable(find.byType(BlockWidget));
      });
    });

    group('error handling', () {
      testWidgets('CustomBlockWidget shows error for unknown widget', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.withCustomWidget(widgetName: 'nonexistent_widget_xyz'),
        );
        expect(find.textContaining('Widget not found'), findsOneWidget);
      });
    });

    group('size constraints', () {
      testWidgets('block fills section width', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.singleColumn(),
        );

        final block = find.byType(BlockWidget);
        final size = tester.getSize(block);
        expect(size.width, greaterThan(700)); // viewport may be smaller than kResolution
        expect(size.height, greaterThan(300)); // header/footer reduce height
      });
    });

    group('markdown content types', () {
      testWidgets('renders headings and lists', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.mixedMarkdown(),
        );

        expect(find.textContaining('Title'), findsOneWidget);
        expect(find.textContaining('Item 1'), findsOneWidget);
      });

      testWidgets('renders code block', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.withCodeBlock(),
        );
        expect(find.byType(BlockWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

Alignment _toAlignment(ContentAlignment alignment) {
  return switch (alignment) {
    ContentAlignment.topLeft => Alignment.topLeft,
    ContentAlignment.topCenter => Alignment.topCenter,
    ContentAlignment.topRight => Alignment.topRight,
    ContentAlignment.centerLeft => Alignment.centerLeft,
    ContentAlignment.center => Alignment.center,
    ContentAlignment.centerRight => Alignment.centerRight,
    ContentAlignment.bottomLeft => Alignment.bottomLeft,
    ContentAlignment.bottomCenter => Alignment.bottomCenter,
    ContentAlignment.bottomRight => Alignment.bottomRight,
  };
}
