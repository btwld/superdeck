// ignore_for_file: avoid-duplicate-cascades

import 'package:superdeck_builder/superdeck_builder.dart';

import 'logger.dart';

void printException(Exception e) {
  if (e is SDTaskException) {
    logger
      ..err('slide: ${e.slideIndex}')
      ..err('Task error: ${e.taskName}');

    printException(e.originalException);
  } else {
    logger.err(e.toString());
  }
}
