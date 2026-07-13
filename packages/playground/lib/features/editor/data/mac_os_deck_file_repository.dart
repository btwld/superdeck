import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:superdeck_core/superdeck_core.dart' show FileWatcher;

import '../../../core/data/data_sources/security_scoped_file_access.dart';
import '../../../core/result.dart';
import '../domain/files/deck_file.dart';
import '../domain/files/deck_file_repository.dart';

/// macOS implementation of [DeckFileRepository].
///
/// It owns the selected decks-directory and last-opened-deck settings, file
/// I/O, security-scoped bookmarks, and file watching. File bookmarks are
/// retained only after a successful load and released best-effort on failure.
class MacOsDeckFileRepository implements DeckFileRepository {
  MacOsDeckFileRepository({
    SecurityScopedFileAccess fileAccess = const SecurityScopedFileAccess(),
  }) : _fileAccess = fileAccess;

  static const _decksFolderName = 'SuperDeck';
  static const _defaultDeckFileName = 'untitled.md';
  static const _settingsFolder = 'superdeck_playground';
  static const _settingsFileName = 'settings.json';
  static const _decksDirectoryKey = 'decksDirectory';
  static const _lastOpenedDeckKey = 'lastOpenedDeck';

  final SecurityScopedFileAccess _fileAccess;

  SecurityScopedDirectoryReference? _activeDecksDirectory;
  Future<Directory>? _decksDirectoryRequest;
  bool _disposed = false;

  @override
  Future<Result<DeckFileSnapshot>> loadInitialDeck({
    required String starterMarkdown,
  }) async {
    final remembered = await _lastOpenedDeck();
    if (remembered != null) {
      // Folder decks rely on the parent directory's bookmark for access.
      if (remembered.bookmark == null) {
        try {
          await _decksDirectory();
        } on DeckFileAccessException catch (error) {
          return Result.error(error);
        } catch (error) {
          return Result.error(DeckFileAccessException(remembered.path, error));
        }
      }
      final restored = await _loadCandidate(remembered);
      if (restored case Ok(:final value)) {
        await _remember(value.reference);
        return restored;
      }
    }

    return _loadDefaultDeck(starterMarkdown);
  }

  @override
  Future<Result<DeckFileSnapshot?>> pickDeck() async {
    DeckFileReference? picked;
    try {
      picked = await _fileAccess.pickDeckFile();
    } catch (error) {
      return Result.error(DeckFileAccessException('<selected deck>', error));
    }
    if (picked == null) return const Result.ok(null);

    final loaded = await _loadCandidate(picked);
    switch (loaded) {
      case Ok(:final value):
        await _remember(value.reference);
        return Result.ok(value);
      case Failure(:final error):
        return Result.error(error);
    }
  }

  @override
  Future<Result<DeckFileSnapshot>> createDeck({
    required String name,
    required String markdown,
  }) async {
    var fileName = name;
    try {
      fileName = _toMarkdownFileName(name);
      final directory = await _decksDirectory();
      final file = File(p.join(directory.path, fileName));
      if (await file.exists()) {
        return Result.error(DeckNameCollisionException(fileName));
      }
      await file.writeAsString(markdown);
      final snapshot = DeckFileSnapshot(
        reference: DeckFileReference(path: file.path),
        markdown: markdown,
      );
      await _remember(snapshot.reference);
      return Result.ok(snapshot);
    } on DeckFileAccessException catch (error) {
      return Result.error(error);
    } catch (error) {
      return Result.error(DeckFileWriteException(fileName, error));
    }
  }

  @override
  Future<Result<void>> writeDeck(
    DeckFileReference reference,
    String markdown,
  ) async {
    final file = File(reference.path);
    try {
      // Do not recreate a deck that disappeared between watcher events.
      if (!await file.exists()) {
        throw StateError('The deck file no longer exists.');
      }
      await file.writeAsString(markdown);
      return const Result.ok(null);
    } catch (error) {
      return Result.error(DeckFileWriteException(reference.path, error));
    }
  }

  @override
  Stream<DeckFileEvent> watchDeck(DeckFileReference reference) async* {
    try {
      await for (final _ in FileWatcher(
        File(reference.path),
        events:
            FileSystemEvent.modify |
            FileSystemEvent.delete |
            FileSystemEvent.move,
      ).watch()) {
        final file = File(reference.path);
        try {
          if (!await file.exists()) {
            yield const DeckFileUnavailable();
            return;
          }
          yield DeckFileChanged(await file.readAsString());
        } catch (_) {
          yield const DeckFileUnavailable();
          return;
        }
      }
    } catch (_) {
      yield const DeckFileUnavailable();
    }
  }

  @override
  Future<Result<void>> releaseDeck(DeckFileReference reference) async {
    try {
      await _fileAccess.stopAccessing(reference);
    } catch (_) {
      // Cleanup must not replace a useful load/create/pick result with a
      // release failure. macOS may reject a bookmark that was already lost.
    }
    return const Result.ok(null);
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

  Future<Result<DeckFileSnapshot>> _loadDefaultDeck(
    String starterMarkdown,
  ) async {
    late final String path;
    try {
      final directory = await _decksDirectory();
      path = p.join(directory.path, _defaultDeckFileName);
    } on DeckFileAccessException catch (error) {
      return Result.error(error);
    } catch (error) {
      return Result.error(DeckFileWriteException(_defaultDeckFileName, error));
    }

    final file = File(path);
    late final bool exists;
    try {
      exists = await file.exists();
    } catch (error) {
      // An existing but unreadable default is user data. Never overwrite it.
      return Result.error(DeckFileReadException(path, error));
    }

    if (exists) {
      try {
        final snapshot = DeckFileSnapshot(
          reference: DeckFileReference(path: path),
          markdown: await file.readAsString(),
        );
        await _remember(snapshot.reference);
        return Result.ok(snapshot);
      } catch (error) {
        // An existing but unreadable default is user data. Never overwrite it.
        return Result.error(DeckFileReadException(path, error));
      }
    }

    try {
      await file.writeAsString(starterMarkdown);
      final snapshot = DeckFileSnapshot(
        reference: DeckFileReference(path: path),
        markdown: starterMarkdown,
      );
      await _remember(snapshot.reference);
      return Result.ok(snapshot);
    } catch (error) {
      return Result.error(DeckFileWriteException(path, error));
    }
  }

  Future<Result<DeckFileSnapshot>> _loadCandidate(
    DeckFileReference candidate,
  ) async {
    DeckFileReference? activeReference;
    var keepAccess = false;
    try {
      try {
        activeReference = await _fileAccess.startAccessing(candidate);
      } catch (error) {
        return Result.error(DeckFileAccessException(candidate.path, error));
      }

      final file = File(activeReference.path);
      if (!await file.exists()) {
        return Result.error(
          DeckFileReadException(
            activeReference.path,
            StateError('The deck file does not exist.'),
          ),
        );
      }
      final markdown = await file.readAsString();
      keepAccess = true;
      return Result.ok(
        DeckFileSnapshot(reference: activeReference, markdown: markdown),
      );
    } catch (error) {
      return Result.error(DeckFileReadException(candidate.path, error));
    } finally {
      if (!keepAccess) {
        await releaseDeck(activeReference ?? candidate);
      }
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
    } catch (error) {
      throw DeckFileAccessException('<decks directory>', error);
    }
    if (selected == null) {
      throw DeckFileAccessException(
        '<decks directory>',
        StateError('Decks directory selection was cancelled.'),
      );
    }

    try {
      return await _activateDecksDirectory(selected);
    } catch (error) {
      throw DeckFileAccessException(selected.path, error);
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
      if (_disposed) {
        throw StateError('The deck file repository has been disposed.');
      }

      final root = Directory(active.path);
      if (!await root.exists()) {
        throw StateError('The selected decks directory no longer exists.');
      }
      final directory = Directory(p.join(root.path, _decksFolderName));
      await directory.create(recursive: true);
      if (_disposed) {
        throw StateError('The deck file repository has been disposed.');
      }

      _activeDecksDirectory = active;
      await _rememberDecksDirectory(active);
      return directory;
    } catch (_) {
      if (active != null) {
        try {
          await _fileAccess.stopAccessingDirectory(active);
        } catch (_) {
          // Failed activation must not leak an access scope.
        }
      }
      rethrow;
    }
  }

  Future<DeckFileReference?> _lastOpenedDeck() async {
    final stored = (await _readSettings())[_lastOpenedDeckKey];
    if (stored is! Map) return null;
    final path = stored['path'];
    final bookmark = stored['bookmark'];
    if (path is! String || path.isEmpty) return null;
    return DeckFileReference(
      path: path,
      bookmark: bookmark is String && bookmark.isNotEmpty ? bookmark : null,
    );
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

  Future<void> _remember(DeckFileReference reference) async {
    await _updateSettings((settings) {
      settings[_lastOpenedDeckKey] = {
        'path': reference.path,
        if (reference.bookmark != null) 'bookmark': reference.bookmark,
      };
    });
  }

  Future<void> _rememberDecksDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    await _updateSettings((settings) {
      settings[_decksDirectoryKey] = {
        'path': reference.path,
        'bookmark': reference.bookmark,
      };
    });
  }

  Future<Map<String, dynamic>> _readSettings() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      // Corrupt settings are a launch convenience failure, not an app failure.
      return {};
    }
  }

  Future<void> _updateSettings(
    void Function(Map<String, dynamic> settings) update,
  ) async {
    try {
      final settings = await _readSettings();
      update(settings);
      final file = await _settingsFile();
      await file.writeAsString(jsonEncode(settings));
    } catch (_) {
      // Remembering is best-effort and must not break the active binding.
    }
  }

  Future<File> _settingsFile() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, _settingsFolder));
    await directory.create(recursive: true);
    return File(p.join(directory.path, _settingsFileName));
  }

  String _toMarkdownFileName(String name) {
    final bareName = p.basename(name.trim());
    if (bareName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Deck name must not be empty');
    }
    return p.extension(bareName).toLowerCase() == '.md'
        ? bareName
        : '$bareName.md';
  }
}
