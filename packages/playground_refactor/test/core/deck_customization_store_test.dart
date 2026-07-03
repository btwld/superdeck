import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground_refactor/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground_refactor/core/domain/stores/deck_customization_store.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Avoid runtime font fetching in tests — _resolveFamily then returns a plain
  // TextStyle without hitting the network.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  DeckController newController() =>
      DeckController(deckLoader: MemoryDeckLoader(), options: DeckOptions());

  test('seeds DeckOptions on construction', () {
    final controller = newController();
    addTearDown(controller.dispose);

    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);

    expect(controller.options.value.baseStyle, isNotNull);
  });

  test('mutations push new options and notify once', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);

    final seeded = controller.options.value;
    var notifications = 0;
    store.addListener(() => notifications++);

    store.setSize(TextLevel.h1, 64);

    expect(store.level(TextLevel.h1).size, 64);
    expect(notifications, 1);
    expect(identical(controller.options.value, seeded), isFalse);
  });

  test('no-op mutation does not notify', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);

    final current = store.level(TextLevel.h1).size;
    var notifications = 0;
    store.addListener(() => notifications++);

    store.setSize(TextLevel.h1, current);

    expect(notifications, 0);
  });
}
