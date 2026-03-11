import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

import '../deck_configuration.dart';
import 'slide_model.dart';

part 'deck_model.mapper.dart';

@MappableClass()
class Deck with DeckMappable {
  final List<Slide> slides;
  final DeckConfiguration configuration;

  Deck({required List<Slide> slides, required this.configuration})
    : slides = List.unmodifiable(slides);

  Map<String, Object?> toMap() {
    return {
      'slides': slides.map((s) => s.toMap()).toList(),
      'configuration': configuration.toMap(),
    };
  }

  static Deck fromMap(Map<String, Object?> map) {
    final configurationValue = map['configuration'];

    return Deck(
      slides: (map['slides'] as List<dynamic>)
          .map(
            (slide) => Slide.fromMap(Map<String, Object?>.from(slide as Map)),
          )
          .toList(),
      configuration: configurationValue == null
          ? DeckConfiguration()
          : DeckConfiguration.fromMap(
              Map<String, Object?>.from(configurationValue as Map),
            ),
    );
  }

  /// Ack schema for validating complete deck/presentation JSON.
  static final schema = Ack.object({
    'slides': Ack.list(Slide.schema),
    'configuration': DeckConfiguration.schema.optional(),
  });

  static Deck parse(Map<String, Object?> map) => fromMap(schema.parse(map)!);
}
