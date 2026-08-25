import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/memory_asset_cache_store.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/domain/generated_deck_result_applier.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
    'caches generated artwork before publishing the rendered deck',
    () async {
      const assetKey = 'wizard-test-slide-01-opening.png';
      final cache = MemoryAssetCacheStore();
      final loader = MemoryDeckLoader();
      final documentStore = DeckDocumentStore(markdown: '');
      final deckController = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
        assetCacheStore: cache,
      );
      final customizationStore = DeckCustomizationStore(deckController);
      addTearDown(customizationStore.dispose);
      addTearDown(deckController.dispose);
      addTearDown(loader.dispose);
      addTearDown(documentStore.dispose);

      final published = loader.load().first.then(
        (_) => cache.resolve(assetKey),
      );
      final applier = GeneratedDeckResultApplier(
        documentStore: documentStore,
        deckLoader: loader,
        assetCacheStore: cache,
        customizationStore: customizationStore,
      );
      await applier.apply(
        DeckGenerationResult.success(
          slides: [_generatedSlide(assetKey)],
          plan: _plan(assetKey),
          theme: _resolvedTheme(),
          generatedImages: [
            GeneratedImageAsset.success(assetKey: assetKey, bytes: [1, 2, 3]),
          ],
        ),
      );

      expect(await published, isNotNull);
      expect(documentStore.markdown, contains(assetKey));
    },
  );

  test('evicts artwork from the deck replaced by the current result', () async {
    const oldAssetKey = 'wizard-old-slide-01-opening.png';
    const nextAssetKey = 'wizard-next-slide-01-opening.png';
    final cache = MemoryAssetCacheStore();
    final loader = MemoryDeckLoader();
    final documentStore = DeckDocumentStore(markdown: '');
    final deckController = DeckController(
      deckLoader: loader,
      options: DeckOptions(),
      assetCacheStore: cache,
    );
    final customizationStore = DeckCustomizationStore(deckController);
    final applier = GeneratedDeckResultApplier(
      documentStore: documentStore,
      deckLoader: loader,
      assetCacheStore: cache,
      customizationStore: customizationStore,
    );
    addTearDown(customizationStore.dispose);
    addTearDown(deckController.dispose);
    addTearDown(loader.dispose);
    addTearDown(documentStore.dispose);

    await applier.apply(_result(oldAssetKey));
    expect(await cache.resolve(oldAssetKey), isNotNull);

    await applier.apply(_result(nextAssetKey));
    expect(await cache.resolve(oldAssetKey), isNull);
    expect(await cache.resolve(nextAssetKey), isNotNull);
  });
}

DeckGenerationResult _result(String assetKey) => DeckGenerationResult.success(
  slides: [_generatedSlide(assetKey)],
  plan: _plan(assetKey),
  theme: _resolvedTheme(),
  generatedImages: [
    GeneratedImageAsset.success(assetKey: assetKey, bytes: [1, 2, 3]),
  ],
);

Slide _generatedSlide(String assetKey) => Slide.parse({
  'key': 'opening',
  'options': {'title': 'Opening', 'style': 'visual'},
  'sections': [
    {
      'type': 'section',
      'blocks': [
        {
          'type': 'widget',
          'name': 'image',
          'args': {'src': assetKey, 'fit': 'cover'},
        },
      ],
    },
  ],
});

DeckPlan _plan(String assetKey) => DeckPlan.parse({
  'topic': 'Generated artwork',
  'story': 'One image supports one clear point.',
  'theme': {'id': 'technical-paper', 'version': 1, 'density': 'balanced'},
  'sections': [
    {
      'key': 'main',
      'title': 'Main',
      'purpose': 'Introduce the idea.',
      'transition': 'Close clearly.',
      'slideKeys': ['opening'],
    },
  ],
  'slides': [
    {
      'key': 'opening',
      'title': 'Opening',
      'purpose': 'Introduce the idea.',
      'sectionKey': 'main',
      'assertion': 'The visual makes the idea tangible.',
      'contentUnits': ['One focused supporting statement.'],
      'narrativeRole': 'opening',
      'contentBrief': 'Open with one clear idea.',
      'continuity': 'Lead into the story.',
      'composition': 'imageFullBleed',
      'treatment': 'visual',
      'density': 'balanced',
      'elements': [
        {'type': 'image', 'purpose': 'Anchor the story.', 'source': assetKey},
      ],
    },
  ],
});

ResolvedPresentationTheme _resolvedTheme() =>
    PresentationThemeCatalog.withDefaults().resolve(
      id: 'technical-paper',
      version: 1,
      density: 'balanced',
      typographyCatalog: PresentationTypographyCatalog.withDefaults(),
    );
