import 'dart:async';

import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../../core/domain/stores/deck_document_store.dart';
import '../core/engine/services/deck_generator_service.dart';
import '../../../../core/domain/design/generated_deck_style_mapper.dart';

/// Reports whether the generation that produced a result is still the one the
/// host wants published.
///
/// The applier calls it before it stages artwork, and again after that
/// asynchronous work, immediately before it publishes the deck.
typedef GeneratedDeckApplicationGuard = bool Function();

/// Outcome of one [GeneratedDeckResultApplier.apply] call.
final class GeneratedDeckApplication {
  /// Whether the document, preview, and theme received this result.
  final bool published;

  /// Failure raised while removing artwork that the published deck replaced.
  ///
  /// The deck is published when this is set. Hosts report it separately from a
  /// generation failure.
  final Object? cleanupError;

  const GeneratedDeckApplication({required this.published, this.cleanupError});
}

/// Applies generated decks for one host and evicts artwork from the deck it
/// replaces only after the replacement has been published successfully.
final class GeneratedDeckResultApplier {
  final DeckDocumentStore _documentStore;

  final MemoryDeckLoader? _deckLoader;
  final AssetCacheStore? _assetCacheStore;
  final DeckCustomizationStore _customizationStore;
  Set<String> _appliedAssetKeys = const {};

  /// Serializes application, so two results for one host cannot interleave
  /// their artwork writes and their document publication.
  Future<void> _queue = Future<void>.value();
  GeneratedDeckResultApplier({
    required DeckDocumentStore documentStore,
    MemoryDeckLoader? deckLoader,
    AssetCacheStore? assetCacheStore,
    required DeckCustomizationStore customizationStore,
  }) : _documentStore = documentStore,
       _deckLoader = deckLoader,
       _assetCacheStore = assetCacheStore,
       _customizationStore = customizationStore;

  /// Deletes only the artwork this attempt staged, and keeps every asset key
  /// that an earlier attempt already committed.
  Future<void> _discardStagedAssets(Set<String> stagedAssetKeys) async {
    final cache = _assetCacheStore;
    if (cache == null || stagedAssetKeys.isEmpty) return;
    for (final assetKey in stagedAssetKeys) {
      try {
        await cache.delete(assetKey);
      } catch (_) {
        // An abandoned asset that cannot be deleted must not mask the reason
        // the application stopped.
      }
    }
  }

  Future<GeneratedDeckApplication> _apply(
    DeckGenerationResult result,
    GeneratedDeckApplicationGuard isValid, {
    void Function()? onAccepted,
  }) async {
    const abandoned = GeneratedDeckApplication(published: false);
    if (!isValid()) return abandoned;

    final cache = _assetCacheStore;
    final nextAssetKeys = <String>{};
    final stagedAssetKeys = <String>{};

    try {
      for (final asset in result.generatedImages) {
        final bytes = asset.bytes;
        if (bytes == null || bytes.isEmpty) continue;
        if (cache == null) {
          throw StateError(
            'Generated artwork cannot be loaded without an asset cache.',
          );
        }
        await cache.write(asset.assetKey, bytes);
        nextAssetKeys.add(asset.assetKey);
        if (!_appliedAssetKeys.contains(asset.assetKey)) {
          stagedAssetKeys.add(asset.assetKey);
        }
      }
    } catch (_) {
      await _discardStagedAssets(stagedAssetKeys);
      rethrow;
    }

    // The asset writes above are asynchronous, so the host can cancel or
    // supersede this generation while they run.
    if (!isValid()) {
      await _discardStagedAssets(stagedAssetKeys);

      return abandoned;
    }

    // The saved-deck binding changes only once this attempt is accepted.
    // A rejection, an abandoned write, or a throw leaves the previous deck
    // answering for its own artwork.
    onAccepted?.call();

    final markdown = const SlideSerializer().serialize(result.slides);
    _documentStore.replaceMarkdown(markdown);
    _deckLoader?.updateMarkdown(markdown);
    if (result.theme case final theme?) {
      _customizationStore.applyGeneratedStyle(theme.toGeneratedDeckStyle());
    }

    return GeneratedDeckApplication(
      published: true,
      cleanupError: await _removeObsoleteAssets(nextAssetKeys),
    );
  }

  /// Deletes the artwork the newly published deck no longer references.
  ///
  /// Returns the first deletion failure, which the host reports separately
  /// from a generation failure because the deck is already published.
  Future<Object?> _removeObsoleteAssets(Set<String> nextAssetKeys) async {
    final cache = _assetCacheStore;
    final obsoleteAssetKeys = _appliedAssetKeys.difference(nextAssetKeys);
    _appliedAssetKeys = Set.unmodifiable(nextAssetKeys);
    if (cache == null) return null;

    Object? cleanupError;
    for (final assetKey in obsoleteAssetKeys) {
      try {
        await cache.delete(assetKey);
      } catch (error) {
        cleanupError ??= error;
      }
    }

    return cleanupError;
  }

  /// Publishes [result] unless [isValid] reports that newer work replaced it.
  ///
  /// Returns whether the deck reached the document, the preview, and the
  /// theme. Artwork staged by an abandoned attempt is removed again.
  Future<GeneratedDeckApplication> apply(
    DeckGenerationResult result, {
    required GeneratedDeckApplicationGuard isValid,
    void Function()? onAccepted,
  }) {
    final application = Completer<GeneratedDeckApplication>();
    // The queue only sequences the work. Failures reach the caller through
    // the completer, so one failed application cannot block the next one.
    _queue = _queue.then((_) async {
      try {
        application.complete(
          await _apply(result, isValid, onAccepted: onAccepted),
        );
      } catch (error, stackTrace) {
        application.completeError(error, stackTrace);
      }
    });

    return application.future;
  }
}

/// Publishes [result] and releases the open saved deck only if that
/// publication is accepted.
Future<GeneratedDeckApplication> applyGeneratedDeckResult({
  required GeneratedDeckResultApplier applier,
  required DeckGenerationResult result,
  required GeneratedDeckApplicationGuard isValid,
  required void Function() releaseSavedDeck,
}) {
  return applier.apply(result, isValid: isValid, onAccepted: releaseSavedDeck);
}
