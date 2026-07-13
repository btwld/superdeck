import '../../../../core/result.dart';
import 'deck_file.dart';

/// Owns editable deck-file persistence and macOS security-scoped access.
///
/// A successful loaded or picked snapshot keeps its bookmark active until the
/// caller invokes [releaseDeck]. Picker cancellation is an `Ok(null)` result.
abstract interface class DeckFileRepository {
  /// Restores the last opened deck, or creates/loads the app-owned default.
  Future<Result<DeckFileSnapshot>> loadInitialDeck({
    required String starterMarkdown,
  });

  /// Opens the native picker and loads the selected deck.
  Future<Result<DeckFileSnapshot?>> pickDeck();

  /// Creates a new app-owned deck seeded with [markdown].
  Future<Result<DeckFileSnapshot>> createDeck({
    required String name,
    required String markdown,
  });

  /// Writes [markdown] to the currently active [reference].
  Future<Result<void>> writeDeck(DeckFileReference reference, String markdown);

  /// Emits content changes or an unavailable event for [reference].
  Stream<DeckFileEvent> watchDeck(DeckFileReference reference);

  /// Best-effort cleanup for a reference retained by a successful load/pick.
  Future<Result<void>> releaseDeck(DeckFileReference reference);
}
