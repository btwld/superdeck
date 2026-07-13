import 'app_settings_store_base.dart';
import 'deck_file_store_base.dart';

/// Web/unsupported stub for [AppSettingsStore]. Desktop-only today; nothing is
/// persisted.
class NativeAppSettingsStore extends AppSettingsStore {
  const NativeAppSettingsStore();

  @override
  Future<DeckFileReference?> lastOpenedDeck() async => null;

  @override
  Future<void> setLastOpenedDeck(DeckFileReference deck) async {}
}
