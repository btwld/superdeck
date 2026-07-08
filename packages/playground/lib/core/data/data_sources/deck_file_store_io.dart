import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'deck_file_store_base.dart';

/// Native ([dart:io]) implementation of [DeckFileStore].
///
/// Decks live in `~/Documents/SuperDeck/` (via `path_provider`); `pickDeckFile`
/// can still reach any path on disk.
class NativeDeckFileStore extends DeckFileStore {
  NativeDeckFileStore();

  /// Fixed decks-folder name under the documents directory.
  static const _decksFolderName = 'SuperDeck';

  @override
  Future<String> decksDirectoryPath() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, _decksFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<String> read(String path) async {
    try {
      return await File(path).readAsString();
    } catch (error) {
      throw DeckFileReadException(path, error);
    }
  }

  @override
  Future<void> write(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  Future<String> createDeck(String name, {required String content}) async {
    final dir = await decksDirectoryPath();
    final fileName = _toMarkdownFileName(name);
    final path = p.join(dir, fileName);
    final file = File(path);
    if (await file.exists()) {
      throw DeckNameCollisionException(fileName);
    }
    await file.writeAsString(content);
    return path;
  }

  @override
  Future<String?> pickDeckFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Open deck',
      type: FileType.custom,
      allowedExtensions: const ['md'],
    );
    // Treat an empty/oddly-shaped result or a path-less entry as a cancel
    // rather than letting `.single` throw a StateError (which openDeck's
    // narrow catch would not handle) escape the Open action.
    final files = result?.files;
    if (files == null || files.isEmpty) return null;
    return files.first.path;
  }

  @override
  Stream<void> watch(String path) => FileWatcher(
    File(path),
    // Watch for edits, deletion, and moves so the controller can react to
    // external changes and to the file disappearing.
    events:
        FileSystemEvent.modify | FileSystemEvent.delete | FileSystemEvent.move,
  ).watch();

  /// Normalises a user-typed deck name into a safe bare `<name>.md` filename:
  /// strips any directory components and ensures the `.md` extension.
  String _toMarkdownFileName(String name) {
    final bare = p.basename(name.trim());
    if (bare.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Deck name must not be empty');
    }
    return p.extension(bare).toLowerCase() == '.md' ? bare : '$bare.md';
  }
}
