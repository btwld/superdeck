import 'package:superdeck_core/superdeck_core.dart' show AssetCacheStore;

import '../../result.dart';
import '../../../features/library/domain/deck_library.dart';
import '../../../features/library/domain/saved_deck.dart';

/// Resolves artwork for whichever deck the app is showing.
///
/// Two lifetimes meet here and stay separate. Artwork the Wizard just
/// generated lives in [fallback] for the rest of the run, because a generated
/// deck is not saved until the reader says so. Artwork of a deck opened from
/// the library lives beside that deck on disk and outlives the run.
///
/// The store object itself is stable — `DeckController` takes its store once —
/// while what it resolves follows the open deck.
class DeckLibraryAssetStore implements AssetCacheStore {
  final DeckLibrary _library;
  final AssetCacheStore _fallback;

  SavedDeckRef? _openDeck;

  DeckLibraryAssetStore({
    required DeckLibrary library,
    required AssetCacheStore fallback,
  }) : _library = library,
       _fallback = fallback;

  /// Follows [ref] for later reads, or nothing when a generated deck is shown.
  void bindTo(SavedDeckRef? ref) {
    _openDeck = ref;
  }

  @override
  Future<Uri?> resolve(String assetKey) async {
    final key = AssetCacheStore.validateAssetKey(assetKey);
    final deck = _openDeck;
    if (deck != null) {
      final resolved = await _library.resolveAsset(deck, key);
      if (resolved case Ok(value: final uri?)) return uri;
    }

    return _fallback.resolve(key);
  }

  /// Keeps generated artwork in memory for this run.
  ///
  /// Writing a deck to disk is an explicit save through [DeckLibrary], never a
  /// side effect of rendering one.
  @override
  Future<Uri?> write(String assetKey, List<int> bytes) =>
      _fallback.write(AssetCacheStore.validateAssetKey(assetKey), bytes);

  @override
  Future<void> delete(String assetKey) =>
      _fallback.delete(AssetCacheStore.validateAssetKey(assetKey));
}
