import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:superdeck_core/superdeck_core.dart' show AssetCacheStore;

import '../../../core/data/data_sources/deck_file.dart';
import '../../../core/data/data_sources/security_scoped_file_access.dart';
import '../../../core/domain/generated_image_asset.dart';
import '../../../core/result.dart';
import '../domain/deck_library.dart';
import '../domain/saved_deck.dart';

/// macOS [DeckLibrary], backed by a user-selected SuperDeck folder.
///
/// The folder is chosen once and remembered as a security-scoped bookmark, so
/// every deck saved into it is reachable on the next launch without asking
/// again. Decks created inside it inherit that access and need no bookmark of
/// their own.
class MacOsDeckLibrary implements DeckLibrary {
  static const _decksFolderName = 'SuperDeck';
  static const _settingsFolder = 'superdeck_playground';
  static const _settingsFileName = 'settings.json';
  static const _decksDirectoryKey = 'decksDirectory';
  static const _temporarySuffix = '.superdeck-partial';

  final SecurityScopedFileAccess _fileAccess;

  SecurityScopedDirectoryReference? _activeDecksDirectory;
  Future<Directory>? _decksDirectoryRequest;
  bool _disposed = false;

  MacOsDeckLibrary({
    SecurityScopedFileAccess fileAccess = const SecurityScopedFileAccess(),
  }) : _fileAccess = fileAccess;

  /// Splits `<name>.md` into the stem its siblings are named after.
  static String deckStem(String markdownPath) {
    final name = p.basename(markdownPath);
    final extension = p.extension(name);

    return extension.isEmpty
        ? name
        : name.substring(0, name.length - extension.length);
  }

  /// The directory holding the artwork of the deck at [markdownPath].
  static String assetsDirectoryPath(String markdownPath) => p.join(
    p.dirname(markdownPath),
    '${deckStem(markdownPath)}$kDeckAssetsSuffix',
  );

  /// The manifest beside the deck at [markdownPath].
  static String manifestPath(String markdownPath) => p.join(
    p.dirname(markdownPath),
    '${deckStem(markdownPath)}$kDeckManifestSuffix',
  );

  /// Turns a deck title into a filename stem that survives a filesystem.
  ///
  /// Path separators, leading dots and control characters are removed;
  /// everything else the user typed, including spaces and non-ASCII letters,
  /// is kept so the file is recognisable in Finder.
  static String toFileStem(String name) {
    final collapsed = name
        .replaceAll(RegExp(r'[\x00-\x1f/\\:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final trimmed = collapsed.replaceAll(RegExp(r'^\.+'), '').trim();

    return trimmed.isEmpty ? 'Untitled deck' : trimmed;
  }

  Future<Map<String, Object?>> _readSettings() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());

      return decoded is Map ? decoded.cast() : {};
    } catch (_) {
      // Corrupt settings cost the remembered folder, not the app.
      return {};
    }
  }

  /// Appends a counter until nothing in [directory] answers to the stem.
  ///
  /// Saving twice keeps both decks: "My talk", then "My talk 2".
  Future<String> _uniqueStem(Directory directory, String stem) async {
    var candidate = stem;
    var suffix = 1;
    while (await _stemTaken(directory, candidate)) {
      suffix++;
      candidate = '$stem $suffix';
    }

    return candidate;
  }

  Future<bool> _stemTaken(Directory directory, String stem) async {
    final markdown = File(p.join(directory.path, '$stem.md'));
    final assets = Directory(p.join(directory.path, '$stem$kDeckAssetsSuffix'));
    final manifest = File(
      p.join(directory.path, '$stem$kDeckManifestSuffix'),
    );

    return await markdown.exists() ||
        await assets.exists() ||
        await manifest.exists();
  }

  Future<SavedDeckManifest?> _readManifest(String markdownPath) async {
    try {
      final file = File(manifestPath(markdownPath));
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;

      return SavedDeckManifest.fromJson(decoded.cast());
    } catch (_) {
      // A deck with an unreadable manifest still presents; it just opens
      // without its theme.
      return null;
    }
  }

  /// Writes through a sibling temporary file, so an interrupted write cannot
  /// leave a half-written deck behind.
  Future<void> _writeString(File file, String contents) async {
    final temporary = File('${file.path}$_temporarySuffix');
    try {
      await temporary.writeAsString(contents, flush: true);
      await temporary.rename(file.path);
    } catch (_) {
      await _deleteQuietly(temporary);
      rethrow;
    }
  }

  Future<void> _writeBytes(File file, List<int> bytes) async {
    final temporary = File('${file.path}$_temporarySuffix');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
    } catch (_) {
      await _deleteQuietly(temporary);
      rethrow;
    }
  }

  Future<void> _deleteQuietly(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Cleanup must not replace the failure that caused it.
    }
  }

  Future<void> _deleteDirectoryQuietly(Directory? directory) async {
    if (directory == null) return;
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (_) {
      // Cleanup must not replace the failure that caused it.
    }
  }

  Future<Directory> _decksDirectory() async {
    final existingRequest = _decksDirectoryRequest;
    if (existingRequest != null) return existingRequest;

    final request = _resolveDecksDirectory();
    _decksDirectoryRequest = request;
    try {
      return await request;
    } catch (_) {
      if (identical(_decksDirectoryRequest, request)) {
        _decksDirectoryRequest = null;
      }
      rethrow;
    }
  }

  Future<Directory> _resolveDecksDirectory() async {
    final remembered = await _storedDecksDirectory();
    if (remembered != null) {
      final restored = await _tryActivateDecksDirectory(remembered);
      if (restored != null) return restored;
    }

    SecurityScopedDirectoryReference? selected;
    try {
      selected = await _fileAccess.pickDecksDirectory();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        DeckFileAccessException('<decks directory>', error),
        stackTrace,
      );
    }
    if (selected == null) {
      throw DeckFileAccessException(
        '<decks directory>',
        StateError('Choosing a folder for saved decks was cancelled.'),
      );
    }

    try {
      return await _activateDecksDirectory(selected);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        DeckFileAccessException(selected.path, error),
        stackTrace,
      );
    }
  }

  Future<Directory?> _tryActivateDecksDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    try {
      return await _activateDecksDirectory(reference);
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _activateDecksDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    SecurityScopedDirectoryReference? active;
    try {
      active = await _fileAccess.startAccessingDirectory(reference);
      if (_disposed) throw StateError('The deck library has been disposed.');

      final root = Directory(active.path);
      if (!await root.exists()) {
        throw StateError('The chosen folder no longer exists.');
      }
      final directory = Directory(p.join(root.path, _decksFolderName));
      await directory.create(recursive: true);
      if (_disposed) throw StateError('The deck library has been disposed.');

      _activeDecksDirectory = active;
      await _rememberDecksDirectory(active);

      return directory;
    } catch (_) {
      if (active != null) {
        try {
          await _fileAccess.stopAccessingDirectory(active);
        } catch (_) {
          // A failed activation must not leak an access scope.
        }
      }
      rethrow;
    }
  }

  Future<SecurityScopedDirectoryReference?> _storedDecksDirectory() async {
    final stored = (await _readSettings())[_decksDirectoryKey];
    if (stored is! Map) return null;
    final path = stored['path'];
    final bookmark = stored['bookmark'];
    if (path is! String ||
        path.isEmpty ||
        bookmark is! String ||
        bookmark.isEmpty) {
      return null;
    }

    return SecurityScopedDirectoryReference(path: path, bookmark: bookmark);
  }

  Future<void> _rememberDecksDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    try {
      final settings = await _readSettings();
      settings[_decksDirectoryKey] = {
        'path': reference.path,
        'bookmark': reference.bookmark,
      };
      await (await _settingsFile()).writeAsString(jsonEncode(settings));
    } catch (_) {
      // Remembering the folder is a convenience, not a save guarantee.
    }
  }

  Future<File> _settingsFile() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, _settingsFolder));
    await directory.create(recursive: true);

    return File(p.join(directory.path, _settingsFileName));
  }

  @override
  Future<Result<DeckSaveOutcome>> save({
    required String name,
    required String markdown,
    List<GeneratedImageAsset> images = const [],
    SavedDeckTheme? theme,
  }) async {
    Directory? assetsDirectory;
    File? markdownFile;
    File? manifestFile;
    try {
      final directory = await _decksDirectory();
      final stem = await _uniqueStem(directory, toFileStem(name));
      markdownFile = File(p.join(directory.path, '$stem.md'));
      manifestFile = File(
        p.join(directory.path, '$stem$kDeckManifestSuffix'),
      );
      assetsDirectory = Directory(
        p.join(directory.path, '$stem$kDeckAssetsSuffix'),
      );

      final saved = <String>[];
      final missing = <String>[];
      for (final image in images) {
        final key = AssetCacheStore.validateAssetKey(image.assetKey);
        final bytes = image.bytes;
        if (bytes == null || bytes.isEmpty) {
          missing.add(key);
          continue;
        }
        await assetsDirectory.create(recursive: true);
        await _writeBytes(File(p.join(assetsDirectory.path, key)), bytes);
        saved.add(key);
      }

      final savedAt = DateTime.now().toUtc();
      final manifest = SavedDeckManifest(
        formatVersion: SavedDeckManifest.currentFormatVersion,
        name: name.trim().isEmpty ? stem : name.trim(),
        savedAt: savedAt,
        markdownFileName: p.basename(markdownFile.path),
        assetsDirectoryName: p.basename(assetsDirectory.path),
        assetKeys: saved,
        theme: theme,
      );

      // Markdown first, then the manifest: a deck without a manifest still
      // opens, a manifest without a deck is meaningless.
      await _writeString(markdownFile, markdown);
      await _writeString(
        manifestFile,
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      );

      return Result.ok(
        DeckSaveOutcome(
          ref: SavedDeckRef(
            reference: DeckFileReference(path: markdownFile.path),
            name: manifest.name,
            savedAt: savedAt,
          ),
          savedAssetKeys: saved,
          missingAssetKeys: missing,
        ),
      );
    } on DeckFileAccessException catch (error) {
      return Result.error(error);
    } catch (error) {
      // This save created every path it touched, so removing them cannot take
      // a deck saved earlier with it.
      await _deleteQuietly(markdownFile);
      await _deleteQuietly(manifestFile);
      await _deleteDirectoryQuietly(assetsDirectory);

      return Result.error(
        DeckFileWriteException(markdownFile?.path ?? name, error),
      );
    }
  }

  @override
  Future<Result<List<SavedDeckRef>>> list() async {
    try {
      final directory = await _decksDirectory();
      final refs = <SavedDeckRef>[];
      await for (final entity in directory.list()) {
        if (entity is! File || p.extension(entity.path) != '.md') continue;
        final manifest = await _readManifest(entity.path);
        refs.add(
          SavedDeckRef(
            reference: DeckFileReference(path: entity.path),
            name: manifest?.name ?? deckStem(entity.path),
            savedAt: manifest?.savedAt ?? (await entity.stat()).modified,
          ),
        );
      }
      refs.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      return Result.ok(refs);
    } on DeckFileAccessException catch (error) {
      return Result.error(error);
    } catch (error) {
      return Result.error(
        DeckFileReadException('<decks directory>', error),
      );
    }
  }

  @override
  Future<Result<SavedDeck>> open(SavedDeckRef ref) async {
    try {
      final file = File(ref.reference.path);
      if (!await file.exists()) {
        throw StateError('The deck is no longer in the SuperDeck folder.');
      }

      return Result.ok(
        SavedDeck(
          ref: ref,
          markdown: await file.readAsString(),
          manifest: await _readManifest(ref.reference.path),
        ),
      );
    } catch (error) {
      return Result.error(
        DeckFileReadException(ref.reference.path, error),
      );
    }
  }

  @override
  Future<Result<Uri?>> resolveAsset(SavedDeckRef ref, String assetKey) async {
    try {
      final key = AssetCacheStore.validateAssetKey(assetKey);
      final file = File(
        p.join(assetsDirectoryPath(ref.reference.path), key),
      );

      return Result.ok(await file.exists() ? file.uri : null);
    } catch (error) {
      return Result.error(
        DeckFileReadException(ref.reference.path, error),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _decksDirectoryRequest = null;
    final directory = _activeDecksDirectory;
    _activeDecksDirectory = null;
    if (directory != null) {
      _fileAccess.stopAccessingDirectory(directory).ignore();
    }
  }

  @override
  bool get canSave => Platform.isMacOS;
}
