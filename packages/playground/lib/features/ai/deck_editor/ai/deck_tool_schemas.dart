import 'dart:convert';

import 'package:superdeck_core/superdeck_core.dart';

/// Strict slide contract exposed to the model. Runtime-only keys are forbidden.
final keylessSlideSchema = Ack.object({
  'options': SlideOptionsSchema.wireSchema.optional(),
  'comments': Ack.list(Ack.string()).optional(),
  'sections': Ack.list(SectionBlockSchema.wireSchema),
}, additionalProperties: false);

final getDeckArgumentsSchema = Ack.object({}, additionalProperties: false);

final createSlideArgumentsSchema = Ack.object({
  'slide': keylessSlideSchema,
  'atIndex': Ack.integer().optional(),
}, additionalProperties: false);

final updateSlideArgumentsSchema = Ack.object({
  'index': Ack.integer(),
  'slide': keylessSlideSchema,
}, additionalProperties: false);

final deleteSlideArgumentsSchema = Ack.object({
  'index': Ack.integer(),
}, additionalProperties: false);

final moveSlideArgumentsSchema = Ack.object({
  'fromIndex': Ack.integer(),
  'toIndex': Ack.integer(),
}, additionalProperties: false);

final readSlideArgumentsSchema = Ack.object({
  'index': Ack.integer(),
}, additionalProperties: false);

/// Validates and constructs a core slide with a private transient key.
Slide parseKeylessSlide(Object? value) {
  final map = keylessSlideSchema.parse(value)!;

  return Slide.fromJson({
    'key': 'tool_${generateValueHash(jsonEncode(map))}',
    ...map,
  });
}

/// Serializes [slide] without exposing its runtime key.
Map<String, Object?> slideToKeylessMap(Slide slide) {
  return slide.toJson()..remove('key');
}

/// Returns the style-free, key-free deck summary used in tool results.
Map<String, Object?> deckSnapshot(List<Slide> slides) {
  return {
    'totalSlides': slides.length,
    'slides': [
      for (final (index, slide) in slides.indexed)
        {'index': index, 'title': ?slide.options?.title},
    ],
  };
}
