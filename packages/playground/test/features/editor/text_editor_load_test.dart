import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/features/editor/text_editor.dart';
import 'package:playground/stores/editor_state.dart';
import 'package:playground/utils/memory_deck_loader.dart';
import 'package:playground/utils/text_editor_controller.dart';
import 'package:provider/provider.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  // Runs on Android + macOS: Android's touch interactor is the one that
  // dereferences a null selection rect on document change, which is how a
  // dangling selection into a deleted node silently breaks the editor repaint.
  for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
    testWidgets(
      'loadMarkdown replaces document text with caret inside doc ($platform)',
      (tester) async {
        Provider.debugCheckInvalidValueType = null;
        debugDefaultTargetPlatformOverride = platform;
        final controller = TextEditorController();
        final deckLoader = MemoryDeckLoader();
        final editorState = EditorState();
        addTearDown(controller.dispose);
        addTearDown(deckLoader.dispose);
        addTearDown(editorState.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<TextEditorController>.value(value: controller),
              Provider<MemoryDeckLoader>.value(value: deckLoader),
              Provider<EditorState>.value(value: editorState),
            ],
            child: HeroTheme(
              data: HeroThemeData.light(),
              child: const MaterialApp(home: Scaffold(body: TextEditor())),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Put the caret inside the existing document, mirroring a user who has
        // clicked into the editor before triggering AI generation.
        await tester.tap(find.byType(SuperEditor));
        await tester.pumpAndSettle();

        controller.loadMarkdown(
          '---\n# Generated Title\n## Generated Sub\n---',
        );
        await tester.pumpAndSettle();

        final doc = _firstDocument(tester);
        final text = _documentText(doc);
        debugDefaultTargetPlatformOverride = null;
        expect(text, contains('Generated Title'));
        expect(text, isNot(contains('# Title\n## Subtitle')));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Document _firstDocument(WidgetTester tester) {
  final superEditor = tester.widget<SuperEditor>(find.byType(SuperEditor));
  return superEditor.editor.document;
}

String _documentText(Document doc) {
  final buffer = StringBuffer();
  for (final node in doc) {
    if (node is TextNode) buffer.writeln(node.text.toPlainText());
  }
  return buffer.toString();
}
