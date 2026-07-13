import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:playground/core/data/data_sources/app_settings_store.dart';
import 'package:playground/core/data/data_sources/deck_file_store.dart';

/// In-memory [DeckFileStore] with a controllable watcher, so tests can simulate
/// external edits and deletions without touching the filesystem.
class FakeDeckFileStore extends DeckFileStore {
  final Map<String, String> files = {};
  final Map<String, StreamController<void>> _watchers = {};
  final Map<DeckFileReference, DeckFileReference> accessResults = {};
  final List<DeckFileReference> accessStarts = [];
  final List<DeckFileReference> accessStops = [];
  final Map<String, Completer<void>> readGates = {};
  final Map<String, Completer<void>> readStarted = {};
  final Map<String, Completer<void>> writeGates = {};
  final Map<String, Completer<void>> writeStarted = {};
  final Set<String> failReads = {};
  String decksDir = '/decks';
  DeckFileReference? pickResult;
  Object? pickError;
  Object? accessError;
  int watchCount = 0;
  int writeCount = 0;

  /// When true, [write] throws without touching [files] — simulates a disk
  /// write that fails after the file already exists (permissions, full disk).
  bool failWrites = false;

  @override
  Future<String> decksDirectoryPath() async => decksDir;

  @override
  Future<bool> exists(String path) async => files.containsKey(path);

  @override
  Future<String> read(String path) async {
    readStarted.remove(path)?.complete();
    await readGates[path]?.future;
    if (failReads.contains(path)) {
      throw DeckFileReadException(path, 'read failed');
    }
    final content = files[path];
    if (content == null) throw DeckFileReadException(path, 'missing');
    return content;
  }

  @override
  Future<void> write(String path, String content) async {
    writeStarted.remove(path)?.complete();
    await writeGates[path]?.future;
    if (failWrites) throw Exception('write failed');
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
  Future<DeckFileReference?> pickDeckFile() async {
    final error = pickError;
    if (error != null) throw error;
    return pickResult;
  }

  @override
  Future<DeckFileReference> startAccessing(DeckFileReference reference) async {
    accessStarts.add(reference);
    final error = accessError;
    if (error != null) {
      throw DeckFileAccessException(reference.path, error);
    }
    return accessResults[reference] ?? reference;
  }

  @override
  Future<void> stopAccessing(DeckFileReference reference) async {
    accessStops.add(reference);
  }

  @override
  Stream<void> watch(String path) {
    watchCount++;
    return _watchers
        .putIfAbsent(path, () => StreamController<void>.broadcast())
        .stream;
  }

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
  DeckFileReference? deck;
  Completer<void>? readGate;
  Completer<void>? readStarted;
  bool failWrites = false;

  String? get path => deck?.path;

  set path(String? value) {
    deck = value == null ? null : DeckFileReference(path: value);
  }

  @override
  Future<DeckFileReference?> lastOpenedDeck() async {
    readStarted?.complete();
    await readGate?.future;
    return deck;
  }

  @override
  Future<void> setLastOpenedDeck(DeckFileReference value) async {
    if (failWrites) throw Exception('settings write failed');
    deck = value;
  }
}
