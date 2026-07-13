import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';

void main() {
  test('exposes its initial Markdown', () {
    final store = DeckDocumentStore(markdown: '# Initial');
    addTearDown(store.dispose);

    expect(store.markdown, '# Initial');
  });

  test('notifies once for each real replacement', () {
    final store = DeckDocumentStore(markdown: '# Initial');
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications++);

    store.replaceMarkdown('# Updated');

    expect(store.markdown, '# Updated');
    expect(notifications, 1);
  });

  test('does not notify when replacement text is identical', () {
    final store = DeckDocumentStore(markdown: '# Initial');
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications++);

    store.replaceMarkdown('# Initial');

    expect(notifications, 0);
  });
}
