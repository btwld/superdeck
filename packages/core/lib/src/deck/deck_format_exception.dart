/// Custom exception for deck format-related errors.
class DeckFormatException extends FormatException {
  const DeckFormatException(super.message, super.source, super.offset);
}
