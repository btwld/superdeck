/// A persistent reference to a deck file.
///
/// [bookmark] is opaque macOS security-scoped bookmark data. Files created in
/// the selected SuperDeck directory inherit its active access scope and do not
/// need individual bookmarks.
final class DeckFileReference {
  /// Last resolved absolute path of the deck.
  final String path;

  /// Opaque persistent access data, or `null` when directory access covers it.
  final String? bookmark;

  const DeckFileReference({required this.path, this.bookmark});

  @override
  bool operator ==(Object other) {
    return other is DeckFileReference &&
        other.path == path &&
        other.bookmark == bookmark;
  }

  @override
  String toString() =>
      'DeckFileReference(path: $path, bookmark: ${bookmark != null})';

  @override
  int get hashCode => Object.hash(path, bookmark);
}

/// Thrown when a new deck's normalised filename already exists.
final class DeckNameCollisionException implements Exception {
  /// The `<name>.md` filename that collided.
  final String fileName;

  const DeckNameCollisionException(this.fileName);

  @override
  String toString() => 'A deck named "$fileName" already exists.';
}

/// Thrown when a deck cannot be read.
final class DeckFileReadException implements Exception {
  final String path;
  final Object cause;

  const DeckFileReadException(this.path, this.cause);

  @override
  String toString() => 'Could not read deck file "$path": $cause';
}

/// Thrown when a deck cannot be written.
final class DeckFileWriteException implements Exception {
  final String path;
  final Object cause;

  const DeckFileWriteException(this.path, this.cause);

  @override
  String toString() => 'Could not write deck file "$path": $cause';
}

/// Thrown when persistent security-scoped access cannot be created or used.
final class DeckFileAccessException implements Exception {
  final String path;
  final Object cause;

  const DeckFileAccessException(this.path, this.cause);

  @override
  String toString() => 'Could not access deck file "$path": $cause';
}
