import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/ui/panels/comments_panel.dart';

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
}
