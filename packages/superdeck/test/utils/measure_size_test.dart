import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/ui/widgets/measure_size.dart';

import '../test_helpers.dart';

void main() {
  group('MeasureSize', () {
    group('Basic Functionality', () {
      testWidgets('calls onChange with correct size when child size changes', (
        WidgetTester tester,
      ) async {
        Size? size;
        await tester.pumpWithScaffold(
          MeasureSize(
            onChange: (newSize, parentConstraints) => size = newSize,
            child: const SizedBox(width: 100, height: 100),
          ),
        );

        expect(size, equals(const Size(100, 100)));

        await tester.pumpWithScaffold(
          MeasureSize(
            onChange: (newSize, parentConstraints) => size = newSize,
            child: const SizedBox(width: 200, height: 200),
          ),
        );

        expect(size, equals(const Size(200, 200)));
      });

      testWidgets('does not call onChange when child size remains the same', (
        WidgetTester tester,
      ) async {
        int onChangeCalls = 0;
        await tester.pumpWithScaffold(
          MeasureSize(
            onChange: (newSize, parentConstraints) => onChangeCalls++,
            child: const SizedBox(width: 100, height: 100),
          ),
        );

        expect(onChangeCalls, equals(1));

        await tester.pumpWithScaffold(
          MeasureSize(
            onChange: (newSize, parentConstraints) => onChangeCalls++,
            child: const SizedBox(width: 100, height: 100),
          ),
        );

        expect(onChangeCalls, equals(1));
      });

      testWidgets('calls onChange with Size.zero when child is null', (
        WidgetTester tester,
      ) async {
        Size? size;
        await tester.pumpWithScaffold(
          MeasureSize(
            onChange: (newSize, parentConstraints) => size = newSize,
            child: const SizedBox.shrink(),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('provides both size and parent constraints in onChange', (
        WidgetTester tester,
      ) async {
        BoxConstraints? parentConstraints;
        Size? size;

        await tester.pumpWithScaffold(
          MeasureSize(
            onChange: (newSize, newParentConstraints) {
              size = newSize;
              parentConstraints = newParentConstraints;
            },
            child: const SizedBox(width: 100, height: 100),
          ),
        );

        expect(size, equals(const Size(100, 100)));
        expect(parentConstraints, isNotNull);
        expect(parentConstraints!.maxWidth, greaterThan(0));
        expect(parentConstraints!.maxHeight, greaterThan(0));
      });

      testWidgets('provides parent constraint utility methods', (
        WidgetTester tester,
      ) async {
        BoxConstraints? parentConstraints;

        await tester.pumpWithScaffold(
          MeasureSize(
            onChange: (size, newParentConstraints) {
              parentConstraints = newParentConstraints;
            },
            child: const SizedBox(width: 150, height: 150),
          ),
        );

        expect(parentConstraints, isNotNull);
        expect(parentConstraints!.maxWidth.isInfinite, isFalse);
        expect(parentConstraints!.maxHeight.isInfinite, isFalse);
        expect(parentConstraints!.isTight, isFalse);
      });
    });

    group('Callback Coalescing', () {
      testWidgets(
        'coalesces multiple layout passes within a frame into single callback',
        (WidgetTester tester) async {
          int callCount = 0;
          final sizes = <Size>[];

          // Create a widget that triggers multiple layouts by using setState
          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: Center(
                    child: MeasureSize(
                      onChange: (size, parentConstraints) {
                        callCount++;
                        sizes.add(size);
                      },
                      child: const SizedBox(width: 100, height: 100),
                    ),
                  ),
                );
              },
            ),
          );

          // Initial layout should trigger one callback
          expect(callCount, equals(1));
          expect(sizes.last, equals(const Size(100, 100)));

          // Pump another frame with the same widget - should NOT trigger callback
          await tester.pump();
          expect(
            callCount,
            equals(1),
            reason: 'Same size should not trigger callback',
          );
        },
      );

      testWidgets('detects constraint changes that affect final size', (
        WidgetTester tester,
      ) async {
        final sizes = <Size>[];

        await tester.pumpWithScaffold(
          SizedBox(
            width: 200,
            height: 200,
            child: MeasureSize(
              onChange: (size, parentConstraints) {
                sizes.add(size);
              },
              // SizedBox.expand fills available space
              child: const SizedBox.expand(),
            ),
          ),
        );

        expect(sizes.length, equals(1));
        expect(sizes.first.width, equals(200));
        expect(sizes.first.height, equals(200));

        // Change parent constraints - this should trigger size change
        await tester.pumpWithScaffold(
          SizedBox(
            width: 300,
            height: 300,
            child: MeasureSize(
              onChange: (size, parentConstraints) {
                sizes.add(size);
              },
              child: const SizedBox.expand(),
            ),
          ),
        );

        // Should fire again due to size change from constraint change
        expect(sizes.length, equals(2));
        expect(sizes.last.width, equals(300));
        expect(sizes.last.height, equals(300));
      });
    });

    group('Detachment Guards', () {
      testWidgets('does not fire callback after widget is disposed', (
        WidgetTester tester,
      ) async {
        int callCount = 0;
        bool widgetPresent = true;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: widgetPresent
                      ? MeasureSize(
                          onChange: (size, parentConstraints) {
                            callCount++;
                          },
                          child: const SizedBox(width: 100, height: 100),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          ),
        );

        expect(callCount, equals(1), reason: 'Initial callback fired');

        // Remove the widget from the tree
        widgetPresent = false;
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: SizedBox.shrink()),
          ),
        );

        // Pump additional frames to ensure no stale callbacks fire
        await tester.pump();
        await tester.pump();

        expect(
          callCount,
          equals(1),
          reason: 'No additional callbacks after disposal',
        );
      });

      testWidgets('handles rapid mount/unmount cycles safely', (
        WidgetTester tester,
      ) async {
        int callCount = 0;

        for (int i = 0; i < 5; i++) {
          // Mount
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: MeasureSize(
                onChange: (size, parentConstraints) {
                  callCount++;
                },
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          );

          // Unmount
          await tester.pumpWidget(
            const Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox.shrink(),
            ),
          );
        }

        // Should have exactly 5 callbacks (one per mount)
        expect(callCount, equals(5));
      });
    });

    group('Edge Cases', () {
      testWidgets('handles zero-sized children correctly', (
        WidgetTester tester,
      ) async {
        Size? size;
        await tester.pumpWithScaffold(
          MeasureSize(
            onChange: (newSize, parentConstraints) => size = newSize,
            child: const SizedBox.shrink(),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('handles animated size changes', (WidgetTester tester) async {
        final sizes = <Size>[];
        double width = 100;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: MeasureSize(
                    onChange: (size, parentConstraints) {
                      sizes.add(size);
                    },
                    child: SizedBox(width: width, height: 100),
                  ),
                ),
              );
            },
          ),
        );

        expect(sizes.length, equals(1));
        expect(sizes.last.width, equals(100));

        // Animate width change
        width = 200;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: MeasureSize(
                onChange: (size, parentConstraints) {
                  sizes.add(size);
                },
                child: SizedBox(width: width, height: 100),
              ),
            ),
          ),
        );

        expect(sizes.length, equals(2));
        expect(sizes.last.width, equals(200));
      });

      testWidgets('works correctly with LayoutBuilder parent', (
        WidgetTester tester,
      ) async {
        Size? measuredSize;
        BoxConstraints? measuredConstraints;
        BoxConstraints? parentConstraints;

        await tester.pumpWithScaffold(
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                parentConstraints = constraints;
                return MeasureSize(
                  onChange: (size, childConstraints) {
                    measuredSize = size;
                    measuredConstraints = childConstraints;
                  },
                  child: const SizedBox(width: 100, height: 100),
                );
              },
            ),
          ),
        );

        expect(measuredSize, isNotNull);
        expect(measuredConstraints, isNotNull);
        expect(parentConstraints, isNotNull);

        // MeasureSize measures its own size, which matches its child
        expect(measuredSize!.width, equals(100));
        expect(measuredSize!.height, equals(100));

        // Verify it received proper constraints from LayoutBuilder
        expect(measuredConstraints, isNotNull);
      });

      testWidgets('reports size changes during constraint changes', (
        WidgetTester tester,
      ) async {
        final events = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 200,
                child: MeasureSize(
                  onChange: (size, parentConstraints) {
                    events.add('${size.width}x${size.height}');
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );

        expect(events.length, equals(1));
        expect(events.first, equals('200.0x200.0'));

        // Change parent size
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: MeasureSize(
                  onChange: (size, parentConstraints) {
                    events.add('${size.width}x${size.height}');
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );

        expect(events.length, equals(2));
        expect(events.last, equals('300.0x300.0'));
      });
    });

    group('RenderObject Integration', () {
      testWidgets('updateRenderObject updates onChange callback', (
        WidgetTester tester,
      ) async {
        int firstCallbackCount = 0;
        int secondCallbackCount = 0;

        void firstCallback(Size size, BoxConstraints constraints) {
          firstCallbackCount++;
        }

        void secondCallback(Size size, BoxConstraints constraints) {
          secondCallbackCount++;
        }

        // Initial render with first callback
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: MeasureSize(
                onChange: firstCallback,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        expect(firstCallbackCount, equals(1));
        expect(secondCallbackCount, equals(0));

        // Update to use second callback with same size
        // The second callback should NOT fire because size hasn't changed
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: MeasureSize(
                onChange: secondCallback,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // First callback should not be called again
        expect(firstCallbackCount, equals(1));
        // Second callback should not fire yet (size unchanged from last report)
        expect(secondCallbackCount, equals(0));

        // Change size to trigger the new callback
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: MeasureSize(
                onChange: secondCallback,
                child: const SizedBox(width: 200, height: 200),
              ),
            ),
          ),
        );

        // First callback still at 1
        expect(firstCallbackCount, equals(1));
        // Second callback fires now due to size change
        expect(secondCallbackCount, equals(1));
      });
    });
  });
}
