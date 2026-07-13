import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:playground/features/editor/domain/stores/editor_store.dart';
import 'package:playground/features/editor/utils/text_editor_controller.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  String markdownIn(Editor editor) {
    final document = editor.context.find<MutableDocument>(Editor.documentKey);
    return document
        .map((node) => node is TextNode ? node.text.toPlainText() : '')
        .join('\n');
  }

  List<DocumentNode> nodesFor(String markdown) {
    final lines = markdown.isEmpty ? const [''] : markdown.split('\n');
    return [
      for (final line in lines)
        ParagraphNode(id: Editor.createNodeId(), text: AttributedText(line)),
    ];
  }

  ({
    DeckDocumentStore documentStore,
    MemoryDeckLoader loader,
    TextEditorController controller,
    List<Object?> previewEvents,
  })
  newController(String initialMarkdown) {
    final documentStore = DeckDocumentStore(markdown: initialMarkdown);
    final loader = MemoryDeckLoader();
    final previewEvents = <Object?>[];
    final previewSubscription = loader.load().listen(previewEvents.add);
    final controller = TextEditorController(
      editorStore: EditorStore(),
      deckLoader: loader,
      documentStore: documentStore,
    );
    addTearDown(() async {
      controller.dispose();
      documentStore.dispose();
      await previewSubscription.cancel();
      await loader.dispose();
    });
    return (
      documentStore: documentStore,
      loader: loader,
      controller: controller,
      previewEvents: previewEvents,
    );
  }

  test('editor edits update the document store and preview', () async {
    final scope = newController('# Initial');

    scope.controller.editor.execute([
      ReplaceDocumentRequest(nodesFor('# Edited')),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(scope.documentStore.markdown, '# Edited');
    expect(scope.previewEvents, hasLength(2));
  });

  test(
    'store changes replace the editor document and update preview',
    () async {
      final scope = newController('# Initial');

      scope.documentStore.replaceMarkdown('# From file\nsecond line');
      await Future<void>.delayed(Duration.zero);

      expect(markdownIn(scope.controller.editor), '# From file\nsecond line');
      expect(scope.previewEvents, hasLength(2));
    },
  );

  test(
    'AI-style whole-document replacement updates editor and preview once',
    () async {
      final scope = newController('# Initial');
      const generatedMarkdown = '''---

# Generated

---
''';

      scope.documentStore.replaceMarkdown(generatedMarkdown);
      await Future<void>.delayed(Duration.zero);

      expect(markdownIn(scope.controller.editor), generatedMarkdown);
      expect(scope.previewEvents, hasLength(2));
    },
  );

  test(
    'identical and echoing document changes do not form a feedback loop',
    () async {
      final scope = newController('# Initial');
      var documentNotifications = 0;
      scope.documentStore.addListener(() => documentNotifications++);

      scope.documentStore.replaceMarkdown('# External');
      scope.documentStore.replaceMarkdown('# External');
      scope.controller.editor.execute([
        ReplaceDocumentRequest(nodesFor('# External')),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(documentNotifications, 1);
      expect(scope.previewEvents, hasLength(2));
      expect(scope.documentStore.markdown, '# External');
    },
  );
}
