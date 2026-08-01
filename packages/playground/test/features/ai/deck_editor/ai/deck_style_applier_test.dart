import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/features/ai/deck_editor/ai/deck_style_applier.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_store.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_tool_error.dart';
import 'package:playground/features/ai/quick_agent/core/engine/prompts/font_styles.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('playground fonts contain every AI-selectable family', () {
    final aiFamilies = {
      ...HeadlineFont.values.map((font) => font.fontFamily),
      ...BodyFont.values.map((font) => font.fontFamily),
    };

    expect(playgroundFontFamilies, containsAll(aiFamilies));
  });

  test('applies colors and actual font families while preserving metrics', () {
    final harness = _StyleHarness();
    addTearDown(harness.dispose);
    final before = harness.store.captureSnapshot();

    final result = harness.applier.update({
      'name': 'Editorial',
      'colors': {
        'background': '#102030',
        'heading': '#AABBCC',
        'body': '#DDEEFF',
      },
      'fonts': {'headline': 'playfairDisplay', 'body': 'sourceSerif4'},
    });

    expect(harness.store.background, const Color(0xFF102030));
    for (final level in TextLevel.values.where(
      (level) => level != TextLevel.p,
    )) {
      expect(harness.store.level(level).color, const Color(0xFFAABBCC));
      expect(harness.store.level(level).family, 'Playfair Display');
      expect(harness.store.level(level).size, before.level(level).size);
      expect(harness.store.level(level).weight, before.level(level).weight);
    }
    expect(harness.store.level(TextLevel.p).color, const Color(0xFFDDEEFF));
    expect(harness.store.level(TextLevel.p).family, 'Source Serif 4');
    expect(
      harness.store.level(TextLevel.p).size,
      before.level(TextLevel.p).size,
    );
    expect(
      harness.store.level(TextLevel.p).weight,
      before.level(TextLevel.p).weight,
    );
    expect(result['style'], {
      'name': 'Editorial',
      'colors': {
        'background': '#102030',
        'heading': '#AABBCC',
        'body': '#DDEEFF',
      },
      'fonts': {'headline': 'playfairDisplay', 'body': 'sourceSerif4'},
    });
    expect((result['deck'] as Map)['totalSlides'], 1);
  });

  test('rejects an invalid color without mutating customization', () {
    final harness = _StyleHarness();
    addTearDown(harness.dispose);
    final before = harness.store.captureSnapshot();

    expect(
      () => harness.applier.update({
        'name': 'Invalid',
        'colors': {
          'background': 'not-a-color',
          'heading': '#FFFFFF',
          'body': '#EEEEEE',
        },
        'fonts': {'headline': 'poppins', 'body': 'inter'},
      }),
      throwsA(
        isA<DeckToolError>().having(
          (error) => error.code,
          'code',
          DeckToolErrorCode.validationFailed,
        ),
      ),
    );
    expect(harness.store.background, before.background);
    expect(
      harness.store.level(TextLevel.h1).family,
      before.level(TextLevel.h1).family,
    );
  });
}

class _StyleHarness {
  _StyleHarness() {
    loader = MemoryDeckLoader();
    controller = DeckController(deckLoader: loader, options: DeckOptions());
    store = DeckCustomizationStore(controller);
    deckStore = _StaticDeckStore([
      Slide(key: 'one', sections: [SectionBlock.text('# One')]),
    ]);
    applier = DeckStyleApplier(customizationStore: store, deckStore: deckStore);
  }

  late final MemoryDeckLoader loader;
  late final DeckController controller;
  late final DeckCustomizationStore store;
  late final DeckStore deckStore;
  late final DeckStyleApplier applier;

  void dispose() {
    store.dispose();
    controller.dispose();
  }
}

class _StaticDeckStore implements DeckStore {
  _StaticDeckStore(this.slides);

  final List<Slide> slides;

  @override
  List<Slide> read() => slides;

  @override
  Future<List<Slide>> restore(String markdown) async => slides;

  @override
  Future<List<Slide>> synchronize() async => slides;

  @override
  Future<List<Slide>> write(List<Slide> slides) async => slides;
}
