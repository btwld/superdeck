// ignore_for_file: avoid-duplicate-cascades

import 'package:superdeck_builder/superdeck_builder.dart';

import 'logger.dart';

void printException(Exception e) {
  if (e is TaskException) {
    logger
      ..err('slide: ${e.slideIndex}')
      ..err('Task error: ${e.taskName}');

    printException(e.originalException);
  } else if (e is DeckFormatException) {
    logger.formatError(e);
  } else {
    logger.err(e.toString());
  }
}
