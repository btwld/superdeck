import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

/// Layout assertion helpers for SuperDeck widget tests.
extension LayoutAssertions on WidgetTester {
  // ---------- Flex distribution ----------

  void expectFlexRatio(
    Finder finder1,
    Finder finder2,
    int flex1,
    int flex2, {
    Axis axis = Axis.horizontal,
    double tolerance = 0.05, // 5% tolerance on ratio
  }) {
    final size1 = getSize(finder1);
    final size2 = getSize(finder2);

    final dimension1 = axis == Axis.horizontal ? size1.width : size1.height;
    final dimension2 = axis == Axis.horizontal ? size2.width : size2.height;

    final expectedRatio = flex1 / flex2;
    final actualRatio = dimension1 / dimension2;

    expect(
      actualRatio,
      closeTo(expectedRatio, tolerance),
      reason: 'Flex ratio should be $flex1:$flex2 ($expectedRatio), got $actualRatio',
    );
  }

  void expectFlexDistribution(
    List<Finder> finders,
    List<int> flexValues, {
    Axis axis = Axis.horizontal,
    double tolerance = 1.0,
  }) {
    assert(finders.length == flexValues.length);

    final totalFlex = flexValues.fold(0, (sum, flex) => sum + flex);
    final sizes = finders.map((f) => getSize(f)).toList();

    final totalDimension = sizes.fold(
      0.0,
      (sum, size) => sum + (axis == Axis.horizontal ? size.width : size.height),
    );

    for (int i = 0; i < finders.length; i++) {
      final expectedDimension = totalDimension * (flexValues[i] / totalFlex);
      final actualDimension = axis == Axis.horizontal
          ? sizes[i].width
          : sizes[i].height;

      expect(
        actualDimension,
        closeTo(expectedDimension, tolerance),
        reason: 'Widget $i should have dimension $expectedDimension, got $actualDimension',
      );
    }
  }

  // ---------- Scrollable ----------

  void expectScrollable(Finder finder) {
    final scrollView = find.descendant(
      of: finder,
      matching: find.byType(SingleChildScrollView),
    );
    expect(scrollView, findsOneWidget, reason: 'Expected scrollable content');
  }

  void expectNotScrollable(Finder finder) {
    final scrollView = find.descendant(
      of: finder,
      matching: find.byType(SingleChildScrollView),
    );
    expect(scrollView, findsNothing, reason: 'Expected non-scrollable content');
  }

  // ---------- Structure ----------

  void expectSectionCount(int count) {
    expect(
      find.byType(SectionWidget),
      findsNWidgets(count),
      reason: 'Expected $count sections',
    );
  }

  void expectBlockCount(int count) {
    final contentBlocks = find.byType(BlockWidget);
    final customBlocks = find.byType(CustomBlockWidget);
    expect(
      contentBlocks.evaluate().length + customBlocks.evaluate().length,
      count,
      reason: 'Expected $count blocks',
    );
  }
}
