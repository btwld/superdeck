import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/modules/common/helpers/measure_size.dart';

import '../test_helpers.dart';

void main() {
  group('MeasureSize', () {
    testWidgets('calls onChange with correct size when child size changes',
        (WidgetTester tester) async {
      Size? size;
      await tester.pumpWithScaffold(
        MeasureSize(
          onChange: (newSize) => size = newSize,
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      expect(size, equals(const Size(100, 100)));

      await tester.pumpWithScaffold(
        MeasureSize(
          onChange: (newSize) => size = newSize,
          child: const SizedBox(width: 200, height: 200),
        ),
      );

      expect(size, equals(const Size(200, 200)));
    });

    testWidgets('does not call onChange when child size remains the same',
        (WidgetTester tester) async {
      int onChangeCalls = 0;
      await tester.pumpWithScaffold(
        MeasureSize(
          onChange: (newSize) => onChangeCalls++,
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      expect(onChangeCalls, equals(1));

      await tester.pumpWithScaffold(
        MeasureSize(
          onChange: (newSize) => onChangeCalls++,
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      expect(onChangeCalls, equals(1));
    });

    testWidgets('calls onChange with Size.zero when child is null',
        (WidgetTester tester) async {
      Size? size;
      await tester.pumpWithScaffold(
        MeasureSize(
          onChange: (newSize) => size = newSize,
          child: const SizedBox.shrink(),
        ),
      );

      expect(size, equals(Size.zero));
    });
  });
}
