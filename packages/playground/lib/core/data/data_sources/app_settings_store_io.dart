import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_settings_store_base.dart';
import 'deck_file_store_base.dart';

/// Native [AppSettingsStore] backed by a small JSON file in the app-support
/// directory (`.../superdeck_playground/settings.json`).
///
/// Deliberately dependency-free (no `shared_preferences`) — one file, one key.
class NativeAppSettingsStore extends AppSettingsStore {
  const NativeAppSettingsStore();

  static const _settingsFolder = 'superdeck_playground';
  static const _settingsFileName = 'settings.json';
  static const _lastOpenedKey = 'lastOpenedDeck';
  static const _legacyLastOpenedPathKey = 'lastOpenedDeckPath';

  Future<File> _settingsFile() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, _settingsFolder));
    await dir.create(recursive: true);
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
  Future<DeckFileReference?> lastOpenedDeck() async {
    final settings = await _read();
    final value = settings[_lastOpenedKey];
    if (value is Map) {
      final deck = Map<String, dynamic>.from(value);
      final path = deck['path'];
      final bookmark = deck['bookmark'];
      if (path is String && path.isNotEmpty) {
        return DeckFileReference(
          path: path,
          bookmark: bookmark is String && bookmark.isNotEmpty ? bookmark : null,
        );
      }
    }

    // Migrate settings written before persistent file references were added.
    final legacyPath = settings[_legacyLastOpenedPathKey];
    return legacyPath is String && legacyPath.isNotEmpty
        ? DeckFileReference(path: legacyPath)
        : null;
  }

  @override
  Future<void> setLastOpenedDeck(DeckFileReference deck) async {
    final settings = await _read();
    settings[_lastOpenedKey] = {
      'path': deck.path,
      if (deck.bookmark != null) 'bookmark': deck.bookmark,
    };
    settings.remove(_legacyLastOpenedPathKey);
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(settings));
  }
}
