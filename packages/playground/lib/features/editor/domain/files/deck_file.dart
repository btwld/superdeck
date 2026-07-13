/// A persistent reference to a deck file.
///
/// [bookmark] is opaque macOS security-scoped bookmark data. App-owned files
/// in the playground's documents directory do not need one.
final class DeckFileReference {
  const DeckFileReference({required this.path, this.bookmark});

  /// Last resolved absolute path of the deck.
  final String path;

  /// Opaque persistent access data, or `null` for app-owned files.
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

/// The Markdown loaded from a deck file together with its active reference.
final class DeckFileSnapshot {
  const DeckFileSnapshot({required this.reference, required this.markdown});

  final DeckFileReference reference;
  final String markdown;

  @override
  int get hashCode => Object.hash(reference, markdown);

  @override
  bool operator ==(Object other) {
    return other is DeckFileSnapshot &&
        other.reference == reference &&
        other.markdown == markdown;
  }
}

/// A change observed for an actively bound deck file.
sealed class DeckFileEvent {
  const DeckFileEvent();
}

/// The bound file is still available and now contains [markdown].
final class DeckFileChanged extends DeckFileEvent {
  const DeckFileChanged(this.markdown);

  final String markdown;
}

/// The bound file was deleted, moved, or can no longer be read.
final class DeckFileUnavailable extends DeckFileEvent {
  const DeckFileUnavailable();
}

/// Thrown when a new deck's normalised filename already exists.
final class DeckNameCollisionException implements Exception {
  const DeckNameCollisionException(this.fileName);

  /// The `<name>.md` filename that collided.
  final String fileName;

  @override
  String toString() => 'A deck named "$fileName" already exists.';
}

/// Thrown when a deck cannot be read.
final class DeckFileReadException implements Exception {
  const DeckFileReadException(this.path, this.cause);

  final String path;
  final Object cause;

  @override
  String toString() => 'Could not read deck file "$path": $cause';
}

/// Thrown when a deck cannot be written.
final class DeckFileWriteException implements Exception {
  const DeckFileWriteException(this.path, this.cause);

  final String path;
  final Object cause;

  @override
  String toString() => 'Could not write deck file "$path": $cause';
}

/// Thrown when persistent security-scoped access cannot be created or used.
final class DeckFileAccessException implements Exception {
  const DeckFileAccessException(this.path, this.cause);

  final String path;
  final Object cause;

  @override
  String toString() => 'Could not access deck file "$path": $cause';
}
