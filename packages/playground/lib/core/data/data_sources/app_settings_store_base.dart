/// Persists the playground's single app-managed setting: the last-opened deck
/// path, so the editor can reopen it on the next launch.
///
/// Kept behind an interface (native impl + web stub) to match the storage
/// pattern used elsewhere in the app.
abstract class AppSettingsStore {
  const AppSettingsStore();

  /// The absolute path of the last-opened deck, or `null` if none is
  /// remembered (first run) or it could not be read.
  Future<String?> lastOpenedDeckPath();

  /// Remembers [path] as the last-opened deck.
  Future<void> setLastOpenedDeckPath(String path);
}
