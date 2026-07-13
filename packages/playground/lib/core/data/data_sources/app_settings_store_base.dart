import 'deck_file_store_base.dart';

/// Persists the playground's single app-managed setting: the last-opened deck
/// reference, so the editor can reopen it on the next launch.
///
/// Kept behind an interface (native impl + web stub) to match the storage
/// pattern used elsewhere in the app.
abstract class AppSettingsStore {
  const AppSettingsStore();

  /// The last-opened deck, or `null` if none is remembered (first run) or the
  /// setting could not be read.
  Future<DeckFileReference?> lastOpenedDeck();

  /// Remembers [deck] as the last-opened deck.
  Future<void> setLastOpenedDeck(DeckFileReference deck);
}
