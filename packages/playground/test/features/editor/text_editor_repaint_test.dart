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
  testWidgets('loadMarkdown updates the RENDERED paragraph components', (
    tester,
  ) async {
    Provider.debugCheckInvalidValueType = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
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

    await tester.tap(find.byType(SuperEditor));
    await tester.pumpAndSettle();

    controller.loadMarkdown('---\n# Generated Title\n## Generated Sub\n---');
    await tester.pumpAndSettle();

    final rendered = _renderedText(tester);
    debugDefaultTargetPlatformOverride = null;

    expect(rendered, contains('Generated Title'), reason: 'rendered: $rendered');
    expect(rendered, isNot(contains('Subtitle')));
    expect(tester.takeException(), isNull);
  });
}

String _renderedText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final element in find.byType(TextComponent).evaluate()) {
    final widget = element.widget as TextComponent;
    buffer.writeln(widget.text.toPlainText());
  }
  return buffer.toString();
}
