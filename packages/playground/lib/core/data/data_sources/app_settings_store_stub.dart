import 'app_settings_store_base.dart';

/// Web/unsupported stub for [AppSettingsStore]. Desktop-only today; nothing is
/// persisted.
class NativeAppSettingsStore extends AppSettingsStore {
  NativeAppSettingsStore();

  @override
  Future<String?> lastOpenedDeckPath() async => null;

  @override
  Future<void> setLastOpenedDeckPath(String path) async {}
}
