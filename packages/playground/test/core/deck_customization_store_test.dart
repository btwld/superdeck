import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
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

  test('applies a generated deck style atomically', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);

    final seeded = controller.options.value;
    var notifications = 0;
    store.addListener(() => notifications++);

    store.applyGeneratedStyle(
      background: const Color(0xFF101820),
      heading: const Color(0xFFFEE715),
      body: const Color(0xFFF5F5F5),
      headlineFamily: 'Montserrat',
      bodyFamily: 'Lato',
    );

    expect(store.background, const Color(0xFF101820));
    for (final level in TextLevel.values.where(
      (level) => level != TextLevel.p,
    )) {
      expect(store.level(level).color, const Color(0xFFFEE715));
      expect(store.level(level).family, 'Montserrat');
    }
    expect(store.level(TextLevel.p).color, const Color(0xFFF5F5F5));
    expect(store.level(TextLevel.p).family, 'Lato');
    expect(notifications, 1);
    expect(identical(controller.options.value, seeded), isFalse);
  });
}
