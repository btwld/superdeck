import 'package:ack/ack.dart';
import 'package:collection/collection.dart';

import '../deck_configuration.dart';
import 'slide_model.dart';

class Deck {
  final List<Slide> slides;
  final DeckConfiguration configuration;

  const Deck({required this.slides, required this.configuration});

  Deck copyWith({List<Slide>? slides, DeckConfiguration? configuration}) {
    return Deck(
      slides: slides ?? this.slides,
      configuration: configuration ?? this.configuration,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'slides': slides.map((s) => s.toMap()).toList(),
      'configuration': configuration.toMap(),
    };
  }

  static Deck fromMap(Map<String, Object?> map) {
    final payload = schema.parse(map) as Map<String, Object?>;

    return _fromPayload(payload);
  }

  /// Ack schema for validating complete deck/presentation JSON.
  static final schema = Ack.object({
    'slides': Ack.list(Slide.schema),
    'configuration': DeckConfiguration.schema.optional(),
  });

  /// Alias for [fromMap].
  static Deck parse(Map<String, Object?> map) => fromMap(map);

  static Deck _fromPayload(Map<String, Object?> payload) {
    final configurationValue = payload['configuration'];
    return Deck(
      slides: (payload['slides'] as List<dynamic>)
          .map(
            (slide) =>
                Slide.fromValidatedMap(Map<String, Object?>.from(slide as Map)),
          )
          .toList(),
      configuration: configurationValue == null
          ? DeckConfiguration()
          : DeckConfiguration.parse(
              Map<String, Object?>.from(configurationValue as Map),
            ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Deck &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(slides, other.slides) &&
          configuration == other.configuration;

  @override
  int get hashCode =>
      Object.hash(const DeepCollectionEquality().hash(slides), configuration);
}
