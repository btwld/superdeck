// ignore_for_file: avoid-duplicate-cascades

import 'package:source_span/source_span.dart';

import 'logger.dart';

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

class DeckFormatException extends SourceSpanFormatException {
  DeckFormatException(super.message, super.span, [super.source]);
}

void printException(Exception e) {
  if (e is DeckTaskException) {
    logger
      ..err('slide: ${e.slideIndex}')
      ..err('Task error: ${e.taskName}');

    printException(e.exception);
  } else if (e is DeckFormatException) {
    logger.formatError(e);
  } else {
    logger.err(e.toString());
  }
}
