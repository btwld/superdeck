import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/ui/panels/notes_panel.dart';
import 'package:superdeck/src/ui/panels/thumbnail_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotesPanel', () {
    testWidgets('renders without errors when empty', (tester) async {
      await tester.pumpWidget(
        MixScope(
          child: MaterialApp(
            home: Scaffold(body: NotesPanel(notes: const [])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotesPanel), findsOneWidget);
    });

    testWidgets('displays single note', (tester) async {
      await tester.pumpWidget(
        MixScope(
          child: MaterialApp(
            home: Scaffold(body: NotesPanel(notes: const ['Test note'])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test note'), findsOneWidget);
    });

    testWidgets('displays multiple notes', (tester) async {
      await tester.pumpWidget(
        MixScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotesPanel(notes: const ['Note 1', 'Note 2', 'Note 3']),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Note 1'), findsOneWidget);
      expect(find.text('Note 2'), findsOneWidget);
      expect(find.text('Note 3'), findsOneWidget);
    });

    testWidgets('handles long text', (tester) async {
      final longText = 'A' * 500;
      await tester.pumpWidget(
        MixScope(
          child: MaterialApp(
            home: Scaffold(body: NotesPanel(notes: [longText])),
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
              body: NotesPanel(
                notes: const ['Hello! 😀 こんにちは', 'Test & <test>'],
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
    test('NotesPanel accepts empty list', () {
      const panel = NotesPanel(notes: []);
      expect(panel.notes, isEmpty);
    });

    test('NotesPanel stores provided notes', () {
      const notes = ['a', 'b', 'c'];
      const panel = NotesPanel(notes: notes);
      expect(panel.notes, equals(notes));
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
