import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_settings_store_base.dart';

/// Native [AppSettingsStore] backed by a small JSON file in the app-support
/// directory (`.../superdeck_playground/settings.json`).
///
/// Deliberately dependency-free (no `shared_preferences`) — one file, one key.
class NativeAppSettingsStore extends AppSettingsStore {
  NativeAppSettingsStore();

  static const _settingsFolder = 'superdeck_playground';
  static const _settingsFileName = 'settings.json';
  static const _lastOpenedKey = 'lastOpenedDeckPath';

  Future<File> _settingsFile() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, _settingsFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, _settingsFileName));
  }

  Future<Map<String, dynamic>> _read() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      // Corrupt/unreadable settings are non-fatal: treat as empty.
      return {};
    }
  }

  @override
  Future<String?> lastOpenedDeckPath() async {
    final value = (await _read())[_lastOpenedKey];
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  Future<void> setLastOpenedDeckPath(String path) async {
    final settings = await _read();
    settings[_lastOpenedKey] = path;
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(settings));
  }
}
