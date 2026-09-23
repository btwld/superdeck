import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/memory_asset_cache_store.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

const _markdown = '''
---
title: Loaded
---

A deck that already decoded.
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('reload re-emits unchanged slides before it completes', () async {
    final harness = _harness();
    harness.loader.updateMarkdown(_markdown);
    await Future<void>.delayed(Duration.zero);
    expect(harness.deck.session.isLoading.value, isFalse);
    final title =
        harness.deck.session.loadedSlides.value?.single.options?.title;
    expect(title, 'Loaded');

    final order = await _reload(harness.loader, harness.deck);

    expect(order.eventBeforeComplete, isTrue);
    expect(order.event, isA<SlidesLoadedEvent>());
    expect(harness.deck.session.isLoading.value, isFalse);
    expect(
      harness.deck.session.loadedSlides.value?.single.options?.title,
      title,
    );
    expect(harness.deck.session.error.value, isNull);
  });

  test(
    'reload re-emits a terminal error for markdown that failed to decode',
    () async {
      final harness = _harness();
      harness.loader.updateMarkdown('@column\n');
      await Future<void>.delayed(Duration.zero);
      expect(harness.deck.session.loadedSlides.value, isNull);
      expect(harness.deck.session.isLoading.value, isFalse);
      expect(harness.deck.session.error.value, isNotNull);

      final order = await _reload(harness.loader, harness.deck);

      expect(order.eventBeforeComplete, isTrue);
      expect(order.event, isA<SlidesErrorEvent>());
      expect(harness.deck.session.isLoading.value, isFalse);
      expect(harness.deck.session.loadedSlides.value, isNull);
      expect(harness.deck.session.error.value, isNotNull);
    },
  );

  test(
    'reload without markdown emits a terminal error and clears loading',
    () async {
      final harness = _harness();
      expect(harness.deck.session.loadedSlides.value, isNull);

      final order = await _reload(harness.loader, harness.deck);

      expect(order.eventBeforeComplete, isTrue);
      expect(order.event, isA<SlidesErrorEvent>());
      expect(harness.deck.session.isLoading.value, isFalse);
      expect(harness.deck.session.loadedSlides.value, isNull);
      expect(harness.deck.session.error.value, isNotNull);
    },
  );

  test('an ordinary identical update emits no new preview event', () async {
    final harness = _harness();
    harness.loader.updateMarkdown(_markdown);
    await Future<void>.delayed(Duration.zero);
    final events = <SlidesEvent>[];
    final subscription = harness.loader.load().listen(events.add);
    addTearDown(subscription.cancel);

    harness.loader.updateMarkdown(_markdown);
    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
  });
}

({MemoryDeckLoader loader, DeckController deck}) _harness() {
  final loader = MemoryDeckLoader();
  final deck = DeckController(
    deckLoader: loader,
    options: DeckOptions(),
    assetCacheStore: MemoryAssetCacheStore(),
  );
  addTearDown(deck.dispose);

  return (loader: loader, deck: deck);
}

Future<({bool eventBeforeComplete, SlidesEvent? event})> _reload(
  MemoryDeckLoader loader,
  DeckController deck,
) async {
  var completed = false;
  SlidesEvent? event;
  var eventBeforeComplete = false;
  final subscription = loader.load().listen((next) {
    event = next;
    eventBeforeComplete = !completed;
  });
  addTearDown(subscription.cancel);

  await deck.session.reload().whenComplete(() => completed = true);

  return (eventBeforeComplete: eventBeforeComplete, event: event);
}
