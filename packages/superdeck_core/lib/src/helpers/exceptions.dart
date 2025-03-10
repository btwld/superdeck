// ignore_for_file: avoid-duplicate-cascades

class DeckTaskException implements Exception {
  final int slideIndex;
  final String taskName;

  final Exception exception;

  const DeckTaskException(this.taskName, this.exception, this.slideIndex);

  String get message {
    return 'Error running task on slide $slideIndex';
  }

  @override
  String toString() => message;
}

class DeckFormatException extends FormatException {
  const DeckFormatException(super.message, super.source, super.offset);
}
