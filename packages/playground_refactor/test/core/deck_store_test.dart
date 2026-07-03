import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground_refactor/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground_refactor/core/domain/stores/deck_store.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Building slide configurations resolves the default slide style, which pulls
  // Google Fonts; disable runtime fetching so it falls back instead of failing.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('starts empty, then mirrors controller slides and notifies', () async {
    final loader = MemoryDeckLoader();
    final controller = DeckController(deckLoader: loader, options: DeckOptions());
    addTearDown(controller.dispose);

    final store = DeckStore(controller);
    addTearDown(store.dispose);

    expect(store.slides, isEmpty);

    var notifications = 0;
    store.addListener(() => notifications++);

    loader.updateMarkdown('---\n# Hello\n---\n# World\n');
    await pumpEventQueue();

    expect(store.slides.length, 2);
    expect(notifications, greaterThan(0));
  });

  test('stops notifying after dispose', () async {
    final loader = MemoryDeckLoader();
    final controller = DeckController(deckLoader: loader, options: DeckOptions());
    addTearDown(controller.dispose);

    final store = DeckStore(controller);

    var notifications = 0;
    store.addListener(() => notifications++);
    store.dispose();

    loader.updateMarkdown('---\n# Hello\n');
    await pumpEventQueue();

    expect(notifications, 0);
  });
}
