import 'dart:convert';

import 'package:superdeck_core/superdeck_core.dart';

SlidesLoadedEvent decodeSlidesEvent(String content, String sourceLabel) {
  final decoded = jsonDecode(content);
  if (decoded is! List) {
    throw Exception(
      'Expected JSON array in $sourceLabel, got ${decoded.runtimeType}',
    );
  }
  return SlidesLoadedEvent(parseSlidesContract(decoded));
}

SlidesErrorEvent wrapReferenceError(
  Object error, {
  String message = 'Superdeck reference error',
}) {
  return SlidesErrorEvent(
    message,
    error: error is Exception ? error : Exception(error.toString()),
  );
}
