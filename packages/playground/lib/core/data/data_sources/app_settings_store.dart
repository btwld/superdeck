/// Entry point for the app settings store: re-exports the interface plus the
/// platform-selected [NativeAppSettingsStore] via conditional import.
library;

export 'app_settings_store_base.dart';
export 'app_settings_store_stub.dart'
    if (dart.library.io) 'app_settings_store_io.dart';
