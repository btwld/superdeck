import 'package:flutter/material.dart';
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

  test('captureSnapshot is a deep immutable copy', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);
    final snapshot = store.captureSnapshot();
    final capturedH1 = snapshot.level(TextLevel.h1);

    store
      ..background = const Color(0xFF123456)
      ..setColor(TextLevel.h1, const Color(0xFFABCDEF))
      ..setSize(TextLevel.h1, 99)
      ..setWeight(TextLevel.h1, 400)
      ..setFamily(TextLevel.h1, 'Roboto');

    expect(snapshot.background, const Color(0xFF000000));
    expect(capturedH1.color, const Color(0xFFFFFFFF));
    expect(capturedH1.size, 40);
    expect(capturedH1.weight, 700);
    expect(capturedH1.family, 'Inter');
  });

  test('restoreSnapshot restores every field and notifies once', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);
    final snapshot = store.captureSnapshot();
    store
      ..background = const Color(0xFF123456)
      ..setColor(TextLevel.h3, const Color(0xFFABCDEF))
      ..setSize(TextLevel.h3, 77)
      ..setWeight(TextLevel.h3, 400)
      ..setFamily(TextLevel.h3, 'Roboto');
    var notifications = 0;
    store.addListener(() => notifications++);

    store.restoreSnapshot(snapshot);

    expect(store.background, snapshot.background);
    for (final level in TextLevel.values) {
      final actual = store.level(level);
      final expected = snapshot.level(level);
      expect(actual.color, expected.color);
      expect(actual.size, expected.size);
      expect(actual.weight, expected.weight);
      expect(actual.family, expected.family);
    }
    expect(notifications, 1);
  });
}
