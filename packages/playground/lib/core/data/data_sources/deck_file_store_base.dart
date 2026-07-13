/// A persistent reference to a deck file.
///
/// [bookmark] is opaque security-scoped bookmark data on macOS. App-owned
/// files inside the sandbox do not need one.
class DeckFileReference {
  const DeckFileReference({required this.path, this.bookmark});

  /// Last resolved absolute path of the deck.
  final String path;

  /// Opaque platform access token, or `null` for app-owned files.
  final String? bookmark;

  @override
  int get hashCode => Object.hash(path, bookmark);

  @override
  bool operator ==(Object other) {
    return other is DeckFileReference &&
        other.path == path &&
        other.bookmark == bookmark;
  }

  @override
  String toString() =>
      'DeckFileReference(path: $path, bookmark: ${bookmark != null})';
}

/// Storage contract for deck `.md` files owned by the playground editor.
///
/// Mirrors the `DeckLoader` / `AssetCacheStore` interface + native-impl pattern:
/// the editor talks only to this abstraction, and the concrete implementation is
/// selected per platform through a conditional export (`deck_file_store.dart`).
/// Only the native macOS (`dart:io` + `path_provider` + method channel)
/// implementation is built today; the web stub throws.
abstract class DeckFileStore {
  const DeckFileStore();

  /// Absolute path of the fixed decks folder in the app's Documents container,
  /// creating it if it does not yet exist.
  Future<String> decksDirectoryPath();

  /// Whether a file exists at [path].
  Future<bool> exists(String path);

  /// Reads the file at [path] as UTF-8 text.
  ///
  /// Throws [DeckFileReadException] if the file cannot be read.
  Future<String> read(String path);

  /// Writes [content] to the file at [path] as UTF-8 text.
  Future<void> write(String path, String content);

  /// Creates `<name>.md` in the decks folder seeded with [content] and returns
  /// its absolute path.
  ///
  /// Throws [DeckNameCollisionException] if a file with that name already
  /// exists — callers re-prompt rather than overwrite.
  Future<String> createDeck(String name, {required String content});

  /// Opens a native file picker filtered to `.md` and returns a persistent
  /// reference to the chosen file, or `null` if the user cancelled.
  Future<DeckFileReference?> pickDeckFile();

  /// Activates any persistent access represented by [reference].
  ///
  /// The returned reference contains the resolved path and refreshed bookmark
  /// when a macOS bookmark became stale. This is a no-op for app-owned files.
  Future<DeckFileReference> startAccessing(DeckFileReference reference);

  /// Releases access previously started for [reference].
  Future<void> stopAccessing(DeckFileReference reference);

  /// Emits an event whenever the file at [path] changes on disk (external edit,
  /// deletion, or move). Backed by the shared `FileWatcher` (FS events +
  /// polling fallback).
  Stream<void> watch(String path);
}

/// Thrown by [DeckFileStore.createDeck] when the target name already exists.
class DeckNameCollisionException implements Exception {
  const DeckNameCollisionException(this.fileName);

  /// The `<name>.md` filename that collided.
  final String fileName;

  @override
  String toString() => 'A deck named "$fileName" already exists.';
}

/// Thrown by [DeckFileStore.read] when a file cannot be read (missing,
/// permissions, invalid encoding).
class DeckFileReadException implements Exception {
  const DeckFileReadException(this.path, this.cause);

  /// The path that failed to read.
  final String path;

  /// The underlying error.
  final Object cause;

  @override
  String toString() => 'Could not read deck file "$path": $cause';
}

/// Thrown when persistent platform access to a deck cannot be created or used.
class DeckFileAccessException implements Exception {
  const DeckFileAccessException(this.path, this.cause);

  /// Path whose persistent access failed.
  final String path;

  /// The underlying platform error.
  final Object cause;

  @override
  String toString() => 'Could not access deck file "$path": $cause';
}
