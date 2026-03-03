import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/ui/panels/comments_panel.dart';
import 'package:superdeck/src/ui/panels/thumbnail_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommentsPanel', () {
    testWidgets('renders without errors when empty', (tester) async {
      await tester.pumpWidget(
        MixScope(
          child: MaterialApp(
            home: Scaffold(body: CommentsPanel(comments: const [])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CommentsPanel), findsOneWidget);
    });

    testWidgets('displays single comment', (tester) async {
      await tester.pumpWidget(
        MixScope(
          child: MaterialApp(
            home: Scaffold(
              body: CommentsPanel(comments: const ['Test comment']),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test comment'), findsOneWidget);
    });

    testWidgets('displays multiple comments', (tester) async {
      await tester.pumpWidget(
        MixScope(
          child: MaterialApp(
            home: Scaffold(
              body: CommentsPanel(
                comments: const ['Comment 1', 'Comment 2', 'Comment 3'],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comment 1'), findsOneWidget);
      expect(find.text('Comment 2'), findsOneWidget);
      expect(find.text('Comment 3'), findsOneWidget);
    });

    testWidgets('handles long text', (tester) async {
      final longText = 'A' * 500;
      await tester.pumpWidget(
        MixScope(
          child: MaterialApp(
            home: Scaffold(body: CommentsPanel(comments: [longText])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('handles special characters', (tester) async {
      await tester.pumpWidget(
        MixScope(
          child: MaterialApp(
            home: Scaffold(
              body: CommentsPanel(
                comments: const ['Hello! 😀 こんにちは', 'Test & <test>'],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello! 😀 こんにちは'), findsOneWidget);
      expect(find.text('Test & <test>'), findsOneWidget);
    });
  });

  group('Panel Configuration', () {
    test('CommentsPanel accepts empty list', () {
      const panel = CommentsPanel(comments: []);
      expect(panel.comments, isEmpty);
    });

    test('CommentsPanel stores provided comments', () {
      const comments = ['a', 'b', 'c'];
      const panel = CommentsPanel(comments: comments);
      expect(panel.comments, equals(comments));
    });
  });

  group('ThumbnailPanel', () {
    testWidgets('pointer tap triggers onItemTap exactly once', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThumbnailPanel(
              itemBuilder: (index, selected) => SizedBox(
                key: ValueKey<String>('thumb-$index'),
                height: 48,
                width: 120,
                child: const ExcludeSemantics(
                  child: ColoredBox(color: Colors.white),
                ),
              ),
              itemCount: 1,
              activeIndex: 0,
              onItemTap: (_) => tapCount++,
              scrollDirection: Axis.vertical,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('thumb-0')));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    testWidgets('semantic tap action triggers onItemTap exactly once', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThumbnailPanel(
              itemBuilder: (index, selected) => SizedBox(
                key: ValueKey<String>('thumb-$index'),
                height: 48,
                width: 120,
                child: const ExcludeSemantics(
                  child: ColoredBox(color: Colors.white),
                ),
              ),
              itemCount: 1,
              activeIndex: 0,
              onItemTap: (_) => tapCount++,
              scrollDirection: Axis.vertical,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester.semantics.tap(find.semantics.byLabel('Slide thumbnail 1'));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
      semanticsHandle.dispose();
    });

    testWidgets('semantic label and selected state are exposed', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThumbnailPanel(
              itemBuilder: (index, selected) => SizedBox(
                key: ValueKey<String>('thumb-$index'),
                height: 48,
                width: 120,
                child: const ExcludeSemantics(
                  child: ColoredBox(color: Colors.white),
                ),
              ),
              itemCount: 2,
              activeIndex: 1,
              onItemTap: (_) {},
              scrollDirection: Axis.vertical,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(
        find.bySemanticsLabel('Slide thumbnail 2'),
      );
      expect(
        node,
        matchesSemantics(
          label: 'Slide thumbnail 2',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );

      semanticsHandle.dispose();
    });
  });
}
