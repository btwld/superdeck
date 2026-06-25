abstract final class DeckToolErrorCode {
  static const deckFileNotFound = 'deck_file_not_found';
  static const deckJsonInvalid = 'deck_json_invalid';
  static const deckWriteFailed = 'deck_write_failed';
  static const deckSchemaInvalid = 'deck_schema_invalid';
  static const slideIndexOutOfRange = 'slide_index_out_of_range';
  static const slideInsertIndexInvalid = 'slide_insert_index_invalid';
  static const styleInvalid = 'style_invalid';
  static const contextUnavailable = 'context_unavailable';
  static const slideKeyConflict = 'slide_key_conflict';
  static const slideKeyInvalid = 'slide_key_invalid';
}

class DeckToolException implements Exception {
  const DeckToolException(this.code, this.message);

  final String code;
  final String message;

  factory DeckToolException.deckFileNotFound(String path) {
    return DeckToolException(
      DeckToolErrorCode.deckFileNotFound,
      'Deck file not found at $path',
    );
  }

  factory DeckToolException.deckJsonInvalid(String details) {
    return DeckToolException(
      DeckToolErrorCode.deckJsonInvalid,
      'Deck JSON is invalid: $details',
    );
  }

  factory DeckToolException.deckWriteFailed({
    required String path,
    required String details,
  }) {
    return DeckToolException(
      DeckToolErrorCode.deckWriteFailed,
      'Failed to write deck file at $path: $details',
    );
  }

  factory DeckToolException.deckSchemaInvalid(String details) {
    return DeckToolException(
      DeckToolErrorCode.deckSchemaInvalid,
      'Deck schema is invalid: $details',
    );
  }

  factory DeckToolException.slideIndexOutOfRange({
    required int index,
    required int slideCount,
  }) {
    return DeckToolException(
      DeckToolErrorCode.slideIndexOutOfRange,
      'Slide index $index is out of range for deck with $slideCount slides',
    );
  }

  factory DeckToolException.slideInsertIndexInvalid({
    required int index,
    required int slideCount,
  }) {
    return DeckToolException(
      DeckToolErrorCode.slideInsertIndexInvalid,
      'Insert index $index is invalid for deck with $slideCount slides',
    );
  }

  factory DeckToolException.styleInvalid(String details) {
    return DeckToolException(
      DeckToolErrorCode.styleInvalid,
      'Style payload is invalid: $details',
    );
  }

  factory DeckToolException.contextUnavailable() {
    return const DeckToolException(
      DeckToolErrorCode.contextUnavailable,
      'A mounted BuildContext is required for slide rendering',
    );
  }

  factory DeckToolException.slideKeyConflict(String key) {
    return DeckToolException(
      DeckToolErrorCode.slideKeyConflict,
      'Slide key "$key" already exists in the deck',
    );
  }

  factory DeckToolException.slideKeyInvalid(String key) {
    return DeckToolException(
      DeckToolErrorCode.slideKeyInvalid,
      'Slide key "$key" is invalid. Use only letters, numbers, hyphens, and underscores.',
    );
  }

  @override
  String toString() => 'DeckToolException($code): $message';
}
