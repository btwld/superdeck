// ignore_for_file: avoid-duplicate-cascades

import 'package:superdeck_core/superdeck_core.dart';

import 'logger.dart';

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
