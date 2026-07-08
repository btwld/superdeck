import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:playground/core/data/data_sources/app_settings_store.dart';
import 'package:playground/core/data/data_sources/deck_file_store.dart';

/// In-memory [DeckFileStore] with a controllable watcher, so tests can simulate
/// external edits and deletions without touching the filesystem.
class FakeDeckFileStore extends DeckFileStore {
  final Map<String, String> files = {};
  final Map<String, StreamController<void>> _watchers = {};
  String decksDir = '/decks';
  String? pickResult;
  int writeCount = 0;

  @override
  Future<String> decksDirectoryPath() async => decksDir;

  @override
  Future<bool> exists(String path) async => files.containsKey(path);

  @override
  Future<String> read(String path) async {
    final content = files[path];
    if (content == null) throw DeckFileReadException(path, 'missing');
    return content;
  }

  @override
  Future<void> write(String path, String content) async {
    writeCount++;
    files[path] = content;
  }

  @override
  Future<String> createDeck(String name, {required String content}) async {
    final fileName = name.endsWith('.md') ? name : '$name.md';
    final path = p.join(decksDir, fileName);
    if (files.containsKey(path)) {
      throw DeckNameCollisionException(fileName);
    }
    files[path] = content;
    return path;
  }

  @override
  Future<String?> pickDeckFile() async => pickResult;

  @override
  Stream<void> watch(String path) => _watchers
      .putIfAbsent(path, () => StreamController<void>.broadcast())
      .stream;

  /// Simulates an external tool rewriting [path], then fires the watcher.
  Future<void> externalWrite(String path, String content) async {
    files[path] = content;
    _watchers[path]?.add(null);
    await _settle();
  }

  /// Simulates the bound file being deleted/moved, then fires the watcher.
  Future<void> externalDelete(String path) async {
    files.remove(path);
    _watchers[path]?.add(null);
    await _settle();
  }

  Future<void> _settle() =>
      Future<void>.delayed(const Duration(milliseconds: 10));
}

class FakeAppSettingsStore extends AppSettingsStore {
  String? path;

  @override
  Future<String?> lastOpenedDeckPath() async => path;

  @override
  Future<void> setLastOpenedDeckPath(String value) async => path = value;
}
