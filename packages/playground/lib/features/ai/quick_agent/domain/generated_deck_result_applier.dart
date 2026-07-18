import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../editor/domain/stores/deck_document_store.dart';
import '../core/engine/services/deck_generator_service.dart';
import 'generated_deck_style_mapper.dart';

/// Applies generated decks for one host and evicts artwork from the deck it
/// replaces only after the replacement has been published successfully.
final class GeneratedDeckResultApplier {
  final DeckDocumentStore _documentStore;

  final MemoryDeckLoader? _deckLoader;
  final AssetCacheStore? _assetCacheStore;
  final DeckCustomizationStore _customizationStore;
  Set<String> _appliedAssetKeys = const {};
  GeneratedDeckResultApplier({
    required DeckDocumentStore documentStore,
    MemoryDeckLoader? deckLoader,
    AssetCacheStore? assetCacheStore,
    required DeckCustomizationStore customizationStore,
  }) : _documentStore = documentStore,
       _deckLoader = deckLoader,
       _assetCacheStore = assetCacheStore,
       _customizationStore = customizationStore;

  Future<void> apply(DeckGenerationResult result) async {
    final nextAssetKeys = <String>{};
    for (final asset in result.generatedImages) {
      final bytes = asset.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      final cache = _assetCacheStore;
      if (cache == null) {
        throw StateError(
          'Generated artwork cannot be loaded without an asset cache.',
        );
      }
      await cache.write(asset.assetKey, bytes);
      nextAssetKeys.add(asset.assetKey);
    }

    final markdown = const SlideSerializer().serialize(result.slides);
    _documentStore.replaceMarkdown(markdown);
    _deckLoader?.updateMarkdown(markdown);
    if (result.theme case final theme?) {
      _customizationStore.applyGeneratedStyle(theme.toGeneratedDeckStyle());
    }

    final cache = _assetCacheStore;
    if (cache != null) {
      for (final assetKey in _appliedAssetKeys.difference(nextAssetKeys)) {
        await cache.delete(assetKey);
      }
    }
    _appliedAssetKeys = Set.unmodifiable(nextAssetKeys);
  }
}
