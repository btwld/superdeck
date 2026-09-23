/// A persistent reference to a deck file.
///
/// Files created in the selected SuperDeck directory inherit its active
/// access scope, so this only needs to track the deck's resolved path.
final class DeckFileReference {
  /// Last resolved absolute path of the deck.
  final String path;

  const DeckFileReference({required this.path});

  @override
  bool operator ==(Object other) {
    return other is DeckFileReference && other.path == path;
  }

  @override
  String toString() => 'DeckFileReference(path: $path)';

  @override
  int get hashCode => path.hashCode;
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
