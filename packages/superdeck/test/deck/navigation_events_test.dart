import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/navigation_events.dart';

void main() {
  group('NavigationEvent classes', () {
    test('NextSlideEvent is a NavigationEvent', () {
      final event = NextSlideEvent();
      expect(event, isA<NavigationEvent>());
    });

    test('PreviousSlideEvent is a NavigationEvent', () {
      final event = PreviousSlideEvent();
      expect(event, isA<NavigationEvent>());
    });

    test('GoToSlideEvent stores index', () {
      final event = GoToSlideEvent(5);
      expect(event, isA<NavigationEvent>());
      expect(event.index, 5);
    });

    test('GoToSlideEvent stores zero index', () {
      final event = GoToSlideEvent(0);
      expect(event.index, 0);
    });
  });

  group('KeyboardNavigationHandler', () {
    late KeyboardNavigationHandler handler;

    setUp(() {
      handler = KeyboardNavigationHandler();
    });

    testWidgets('Meta + ArrowRight returns NextSlideEvent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Focus(
            autofocus: true,
            child: Builder(
              builder: (context) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Simulate Meta key press
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);

      // Create key down event for arrow right
      final event = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );

      final result = handler.handleKey(event);
      expect(result, isA<NextSlideEvent>());

      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    });

    testWidgets('Meta + ArrowDown returns NextSlideEvent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);

      final event = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
      );

      final result = handler.handleKey(event);
      expect(result, isA<NextSlideEvent>());

      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    });

    testWidgets('Meta + ArrowLeft returns PreviousSlideEvent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);

      final event = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowLeft,
        logicalKey: LogicalKeyboardKey.arrowLeft,
        timeStamp: Duration.zero,
      );

      final result = handler.handleKey(event);
      expect(result, isA<PreviousSlideEvent>());

      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    });

    testWidgets('Meta + ArrowUp returns PreviousSlideEvent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);

      final event = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowUp,
        logicalKey: LogicalKeyboardKey.arrowUp,
        timeStamp: Duration.zero,
      );

      final result = handler.handleKey(event);
      expect(result, isA<PreviousSlideEvent>());

      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    });

    test('KeyUpEvent returns null (only KeyDownEvent processed)', () {
      final event = KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );

      final result = handler.handleKey(event);
      expect(result, isNull);
    });

    testWidgets('Arrow key without Meta returns null', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      // Do NOT press meta key
      final event = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );

      final result = handler.handleKey(event);
      expect(result, isNull);
    });

    testWidgets('Non-arrow key with Meta returns null', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);

      final event = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration.zero,
      );

      final result = handler.handleKey(event);
      expect(result, isNull);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    });

    testWidgets('Letter key with Meta returns null', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);

      final event = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
      );

      final result = handler.handleKey(event);
      expect(result, isNull);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    });
  });

  group('GestureNavigationHandler', () {
    late GestureNavigationHandler handler;

    setUp(() {
      handler = GestureNavigationHandler();
    });

    group('handleTap', () {
      test('touch tap on right half returns NextSlideEvent', () {
        final details = TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: const Offset(600, 300), // Right of center
          globalPosition: const Offset(600, 300),
        );

        final result = handler.handleTap(details, const Size(800, 600));
        expect(result, isA<NextSlideEvent>());
      });

      test('touch tap on left half returns PreviousSlideEvent', () {
        final details = TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: const Offset(200, 300), // Left of center
          globalPosition: const Offset(200, 300),
        );

        final result = handler.handleTap(details, const Size(800, 600));
        expect(result, isA<PreviousSlideEvent>());
      });

      test('touch tap at exact midpoint returns PreviousSlideEvent', () {
        final details = TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: const Offset(400, 300), // Exactly at center
          globalPosition: const Offset(400, 300),
        );

        final result = handler.handleTap(details, const Size(800, 600));
        // At midpoint (not > width/2), returns PreviousSlideEvent
        expect(result, isA<PreviousSlideEvent>());
      });

      test('touch tap just past midpoint returns NextSlideEvent', () {
        final details = TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: const Offset(400.1, 300), // Just past center
          globalPosition: const Offset(400.1, 300),
        );

        final result = handler.handleTap(details, const Size(800, 600));
        expect(result, isA<NextSlideEvent>());
      });

      test('mouse tap returns null (filtered)', () {
        final details = TapUpDetails(
          kind: PointerDeviceKind.mouse,
          localPosition: const Offset(600, 300),
          globalPosition: const Offset(600, 300),
        );

        final result = handler.handleTap(details, const Size(800, 600));
        expect(result, isNull);
      });

      test('stylus tap is processed', () {
        final details = TapUpDetails(
          kind: PointerDeviceKind.stylus,
          localPosition: const Offset(600, 300),
          globalPosition: const Offset(600, 300),
        );

        final result = handler.handleTap(details, const Size(800, 600));
        expect(result, isA<NextSlideEvent>());
      });
    });

    group('handleSwipe', () {
      test('swipe left (negative velocity) returns NextSlideEvent', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-600, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isA<NextSlideEvent>());
      });

      test('swipe right (positive velocity) returns PreviousSlideEvent', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(600, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isA<PreviousSlideEvent>());
      });

      test('swipe left at threshold (-500) returns NextSlideEvent', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-500, 0)),
        );

        final result = handler.handleSwipe(details);
        // At exactly -500 abs, it's NOT < minSwipeVelocity, so it navigates
        expect(result, isA<NextSlideEvent>());
      });

      test('swipe right at threshold (+500) returns PreviousSlideEvent', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(500, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isA<PreviousSlideEvent>());
      });

      test('slow swipe left (-499) returns null', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-499, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isNull);
      });

      test('slow swipe right (+499) returns null', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(499, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isNull);
      });

      test('zero velocity returns null (below threshold)', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(0, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isNull);
      });

      test('very fast swipe left works', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-5000, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isA<NextSlideEvent>());
      });

      test('very fast swipe right works', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(5000, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isA<PreviousSlideEvent>());
      });

      test('mouse drag returns null (filtered)', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.mouse),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-600, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isNull);
      });

      test('stylus drag is processed', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.stylus),
        );

        final details = DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-600, 0)),
        );

        final result = handler.handleSwipe(details);
        expect(result, isA<NextSlideEvent>());
      });

      test('drag device kind is reset after swipe', () {
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );

        handler.handleSwipe(
          DragEndDetails(
            velocity: const Velocity(pixelsPerSecond: Offset(-600, 0)),
          ),
        );

        // Second swipe without handleDragStart should work
        // because _dragDeviceKind is null (not mouse)
        final result = handler.handleSwipe(
          DragEndDetails(
            velocity: const Velocity(pixelsPerSecond: Offset(-600, 0)),
          ),
        );
        expect(result, isA<NextSlideEvent>());
      });

      test('multiple swipes in sequence work correctly', () {
        // First swipe
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );
        final result1 = handler.handleSwipe(
          DragEndDetails(
            velocity: const Velocity(pixelsPerSecond: Offset(-600, 0)),
          ),
        );
        expect(result1, isA<NextSlideEvent>());

        // Second swipe
        handler.handleDragStart(
          DragStartDetails(kind: PointerDeviceKind.touch),
        );
        final result2 = handler.handleSwipe(
          DragEndDetails(
            velocity: const Velocity(pixelsPerSecond: Offset(600, 0)),
          ),
        );
        expect(result2, isA<PreviousSlideEvent>());
      });
    });

    group('minSwipeVelocity constant', () {
      test('has expected value of 500.0', () {
        expect(GestureNavigationHandler.minSwipeVelocity, 500.0);
      });
    });
  });
}
