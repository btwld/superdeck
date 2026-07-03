import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground_refactor/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground_refactor/core/domain/stores/deck_customization_store.dart';
import 'package:playground_refactor/core/domain/stores/deck_store.dart';
import 'package:playground_refactor/features/editor/domain/stores/editor_store.dart';
import 'package:playground_refactor/features/editor/domain/stores/thumbnail_store.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // The merged store now needs the whole trigger graph wired up even for a
  // read-only assertion.
  ThumbnailStore newStore(DeckController controller, DeckStore deckStore) {
    final editorStore = EditorStore(MemoryDeckLoader());
    addTearDown(editorStore.dispose);
    final customization = DeckCustomizationStore(controller);
    addTearDown(customization.dispose);
    final store = ThumbnailStore(
      controller: controller,
      deckStore: deckStore,
      editorStore: editorStore,
      customization: customization,
    );
    addTearDown(store.dispose);
    return store;
  }

  test('unknown keys report idle', () {
    final controller = DeckController(
      deckLoader: MemoryDeckLoader(),
      options: DeckOptions(),
    );
    addTearDown(controller.dispose);
    final deckStore = DeckStore(controller);
    addTearDown(deckStore.dispose);

    final store = newStore(controller, deckStore);

    expect(store.statusFor('nope'), AsyncFileStatus.idle);
  });

  test('tracks slides and reports idle status until generated', () async {
    final loader = MemoryDeckLoader();
    final controller = DeckController(deckLoader: loader, options: DeckOptions());
    addTearDown(controller.dispose);
    final deckStore = DeckStore(controller);
    addTearDown(deckStore.dispose);

    final store = newStore(controller, deckStore);

    var notifications = 0;
    store.addListener(() => notifications++);

    loader.updateMarkdown('---\n# A\n---\n# B\n');
    await pumpEventQueue();

    // Slides appeared, so the status map changed from empty and notified.
    expect(notifications, greaterThan(0));
    // No capture() call was made, so every slide is still idle.
    for (final slide in deckStore.slides) {
      expect(store.statusFor(slide.key), AsyncFileStatus.idle);
    }
  });
}
