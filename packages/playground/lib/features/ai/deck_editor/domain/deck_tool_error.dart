/// Stable failure codes returned by the deck editing tool boundary.
enum DeckToolErrorCode {
  validationFailed('validation_failed'),
  slideIndexOutOfRange('slide_index_out_of_range'),
  deckParseFailed('deck_parse_failed'),
  deckWriteFailed('deck_write_failed'),
  captureFailed('capture_failed'),
  contextUnavailable('context_unavailable'),
  internalError('internal_error');

  const DeckToolErrorCode(this.wireName);

  final String wireName;
}

/// Typed internal error translated to structured JSON by the AI adapter.
final class DeckToolError implements Exception {
  final DeckToolErrorCode code;

  final String message;
  final Object? cause;
  const DeckToolError(this.code, this.message, {this.cause});

  @override
  String toString() => '${code.wireName}: $message';
}
