abstract final class DeckToolErrorCode {
  static const captureFailed = 'capture_failed';
  static const contextUnavailable = 'context_unavailable';
  static const deckWriteFailed = 'deck_write_failed';
  static const invalidArgument = 'invalid_argument';
  static const slideIndexOutOfRange = 'slide_index_out_of_range';
}

class DeckToolException implements Exception {
  const DeckToolException(this.code, this.message);

  final String code;
  final String message;

  factory DeckToolException.captureFailed([Object? details]) {
    return DeckToolException(
      DeckToolErrorCode.captureFailed,
      details == null
          ? 'Failed to capture slide thumbnail'
          : 'Failed to capture slide thumbnail: $details',
    );
  }

  factory DeckToolException.contextUnavailable() {
    return const DeckToolException(
      DeckToolErrorCode.contextUnavailable,
      'The AI deck-edit session is no longer available',
    );
  }

  factory DeckToolException.deckWriteFailed(String details) {
    return DeckToolException(
      DeckToolErrorCode.deckWriteFailed,
      'Failed to write deck markdown: $details',
    );
  }

  factory DeckToolException.invalidArgument(String details) {
    return DeckToolException(
      DeckToolErrorCode.invalidArgument,
      'Invalid deck tool argument: $details',
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

  @override
  String toString() => 'DeckToolException($code): $message';
}
