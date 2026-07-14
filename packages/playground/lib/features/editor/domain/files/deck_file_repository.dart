import '../../../../core/result.dart';
import '../../../../core/domain/generated_image_asset.dart';
import 'deck_file.dart';
import 'deck_image_manifest.dart';

/// Owns editable deck-file persistence and macOS security-scoped access.
///
/// A successful loaded or picked snapshot keeps its bookmark active until the
/// caller invokes [releaseDeck]. Picker cancellation is an `Ok(null)` result.
abstract interface class DeckFileRepository {
  /// Restores the last opened deck, or creates/loads the selected-folder default.
  Future<Result<DeckFileSnapshot>> loadInitialDeck({
    required String starterMarkdown,
  });

  /// Opens the native picker and loads the selected deck.
  Future<Result<DeckFileSnapshot?>> pickDeck();

  /// Creates a deck in the user-selected SuperDeck folder with [markdown].
  Future<Result<DeckFileSnapshot>> createDeck({
    required String name,
    required String markdown,
  });

  /// Creates a uniquely named Wizard deck and its generated-image sidecar.
  Future<Result<DeckFileSnapshot>> createGeneratedDeck({
    required String name,
    required String markdown,
    required List<GeneratedImageAsset> images,
  });

  /// Loads generated-image retry metadata for [reference], if it exists.
  Future<Result<DeckImageManifest?>> loadImageManifest(
    DeckFileReference reference,
  );

  /// Persists one manual retry outcome and updates its manifest entry.
  Future<Result<void>> updateGeneratedImage(
    DeckFileReference reference,
    GeneratedImageAsset image,
  );

  /// Writes [markdown] to the currently active [reference].
  Future<Result<void>> writeDeck(DeckFileReference reference, String markdown);

  /// Emits content changes or an unavailable event for [reference].
  Stream<DeckFileEvent> watchDeck(DeckFileReference reference);

  /// Best-effort cleanup for a reference retained by a successful load/pick.
  Future<Result<void>> releaseDeck(DeckFileReference reference);

  /// Releases repository-owned resources such as the decks-directory bookmark.
  void dispose();
}
