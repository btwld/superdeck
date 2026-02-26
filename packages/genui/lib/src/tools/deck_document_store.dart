import 'dart:convert';
import 'dart:io';

import 'package:superdeck/superdeck.dart';
import '../ai/schemas/deck_schemas.dart';
import '../ai/services/style_json_serializer.dart';
import './errors.dart';

class DeckDocument {
  const DeckDocument({required this.slides, required this.style});

  final List<Slide> slides;
  final DeckStyleType? style;
}

class DeckDocumentStore {
  DeckDocumentStore({DeckConfiguration? configuration})
    : configuration = configuration ?? DeckConfiguration();

  final DeckConfiguration configuration;

  Future<DeckDocument> readRequired() async {
    final file = configuration.deckJson;
    if (!await file.exists()) {
      throw DeckToolException.deckFileNotFound(file.path);
    }

    final content = await file.readAsString();

    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (error) {
      throw DeckToolException.deckJsonInvalid(error.message);
    }

    if (decoded is! Map) {
      throw DeckToolException.deckSchemaInvalid('Root must be a JSON object');
    }

    final map = Map<String, dynamic>.from(decoded);
    final rawSlides = map['slides'];
    if (rawSlides is! List) {
      throw DeckToolException.deckSchemaInvalid(
        'Expected "slides" as a JSON array',
      );
    }

    final slides = <Slide>[];
    for (var index = 0; index < rawSlides.length; index++) {
      final rawSlide = rawSlides[index];
      if (rawSlide is! Map) {
        throw DeckToolException.deckSchemaInvalid(
          'Slide at index $index must be a JSON object',
        );
      }

      try {
        final slideMap = Map<String, dynamic>.from(rawSlide);
        slides.add(Slide.parse(slideMap));
      } catch (error) {
        throw DeckToolException.deckSchemaInvalid(
          'Invalid slide at index $index: $error',
        );
      }
    }

    DeckStyleType? style;
    if (map.containsKey('style') && map['style'] != null) {
      final rawStyle = map['style'];
      style = DeckStyleType.safeParse(rawStyle).getOrNull();
      if (style == null) {
        String styleDetails;
        try {
          styleDetails = jsonEncode(rawStyle);
        } catch (_) {
          styleDetails = rawStyle.toString();
        }
        throw DeckToolException.deckSchemaInvalid(
          'Invalid "style" object: failed to parse value $styleDetails',
        );
      }
    }

    return DeckDocument(slides: slides, style: style);
  }

  Future<void> writeCanonical({
    required List<Slide> slides,
    DeckStyleType? style,
  }) async {
    final file = configuration.deckJson;
    final payload = {
      'slides': slides.map((slide) => slide.toMap()).toList(),
      if (style != null) 'style': serializeDeckStyleForJson(style),
    };

    final encoded = const JsonEncoder.withIndent('  ').convert(payload);

    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(encoded);
    } on FileSystemException catch (error) {
      throw DeckToolException.deckWriteFailed(
        path: file.path,
        details: error.message,
      );
    }
  }
}
