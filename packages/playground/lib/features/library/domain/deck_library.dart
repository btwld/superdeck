import '../../../core/domain/generated_image_asset.dart';
import '../../../core/result.dart';
import 'saved_deck.dart';

/// Reads and writes complete decks in the SuperDeck folder.
///
/// A saved deck is three things that travel together: `<name>.md`,
/// `<name>.assets/` holding the artwork the Markdown refers to by bare
/// filename, and `<name>.deck.json` describing both. Saving never replaces an
/// earlier deck: each save creates a new, uniquely named copy.
///
/// Decks open read-only. The playground presents saved decks; it does not
/// edit them.
abstract interface class DeckLibrary {
  /// Whether this platform can store decks at all.
  ///
  /// Callers ask before offering to save, rather than inferring support from
  /// the platform. A library that answers `false` still presents generated
  /// decks for the rest of the run.
  bool get canSave;

  /// Writes [markdown], the readable images among [images], and a manifest as
  /// a new deck named after [name].
  ///
  /// The name is normalised and made unique, so two saves of "My talk" become
  /// two decks. Artwork whose bytes are missing is skipped and named in the
  /// result rather than silently dropped. A failure removes what this save
  /// created; decks saved earlier are never touched.
  Future<Result<DeckSaveOutcome>> save({
    required String name,
    required String markdown,
    List<GeneratedImageAsset> images,
    SavedDeckTheme? theme,
  });

  /// Saved decks, newest first.
  Future<Result<List<SavedDeckRef>>> list();

  /// Reads [ref] back for presentation.
  Future<Result<SavedDeck>> open(SavedDeckRef ref);

  /// The URI of [assetKey] beside the deck at [ref], or `null` when the deck
  /// does not have it.
  Future<Result<Uri?>> resolveAsset(SavedDeckRef ref, String assetKey);

  void dispose();
}

/// What one save wrote.
final class DeckSaveOutcome {
  final SavedDeckRef ref;

  /// Artwork written beside the deck.
  final List<String> savedAssetKeys;

  /// Artwork the deck refers to that had no bytes to write.
  ///
  /// The deck is still saved and still presentable; these images will not
  /// render. Never reported as a complete save.
  final List<String> missingAssetKeys;

  const DeckSaveOutcome({
    required this.ref,
    required this.savedAssetKeys,
    required this.missingAssetKeys,
  });

  /// Whether every referenced image came along.
  bool get isComplete => missingAssetKeys.isEmpty;
}
