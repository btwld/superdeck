import 'package:ack/ack.dart';

import 'slide_model.dart';

/// Canonical top-level JSON contract for compiled slide payloads.
final slidesContractSchema = Ack.list(Slide.schema);

/// Parses a compiled slide payload from a raw JSON array.
List<Slide> parseSlidesContract(Object? value) {
  final validated = slidesContractSchema.parse(value)! as List<Object?>;
  return validated
      .cast<Map<String, Object?>>()
      .map((slide) => Slide.fromMap(Map<String, dynamic>.from(slide)))
      .toList(growable: false);
}
