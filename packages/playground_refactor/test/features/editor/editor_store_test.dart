import 'package:flutter_test/flutter_test.dart';
import 'package:playground_refactor/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground_refactor/features/editor/domain/stores/editor_store.dart';

void main() {
  MemoryDeckLoader newLoader() {
    final loader = MemoryDeckLoader();
    addTearDown(loader.dispose);
    return loader;
  }

  test('seeds currentText and forwards the initial markdown to the loader',
      () async {
    final loader = newLoader();
    final events = [];
    final sub = loader.load().listen(events.add);
    addTearDown(sub.cancel);

    final store = EditorStore(loader);
    addTearDown(store.dispose);

    expect(store.currentText, starterMarkdown);
    await pumpEventQueue();
    expect(events, hasLength(1));
  });

  test('updateText records the text, forwards it, and notifies once', () async {
    final loader = newLoader();
    final store = EditorStore(loader);
    addTearDown(store.dispose);

    final events = [];
    final sub = loader.load().listen(events.add);
    addTearDown(sub.cancel);

    var notifications = 0;
    store.addListener(() => notifications++);

    store.updateText('---\n# A\n---\n# B\n');

    expect(store.currentText, '---\n# A\n---\n# B\n');
    expect(notifications, 1);
    await pumpEventQueue();
    expect(events, hasLength(1));
  });

  test('updateText no-ops when the text is unchanged', () {
    final loader = newLoader();
    final store = EditorStore(loader);
    addTearDown(store.dispose);

    var notifications = 0;
    store.addListener(() => notifications++);

    store.updateText(store.currentText);

    expect(notifications, 0);
  });

  test('activeSlideIndex notifies on change and no-ops otherwise', () {
    final loader = newLoader();
    final store = EditorStore(loader);
    addTearDown(store.dispose);

    var notifications = 0;
    store.addListener(() => notifications++);

    store.activeSlideIndex = 2;
    store.activeSlideIndex = 2;

    expect(store.activeSlideIndex, 2);
    expect(notifications, 1);
  });
}
