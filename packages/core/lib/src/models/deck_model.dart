import 'package:ack/ack.dart';
import 'package:collection/collection.dart';

import '../deck_workspace.dart';
import 'slide_model.dart';

class Deck {
  final List<Slide> slides;
  final DeckWorkspace configuration;

  const Deck({required this.slides, required this.configuration});

  Deck copyWith({List<Slide>? slides, DeckWorkspace? configuration}) {
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
    final configurationValue = map['configuration'];
    return Deck(
      slides: (map['slides'] as List<dynamic>? ?? const [])
          .map(
            (slide) => Slide.fromMap(Map<String, Object?>.from(slide as Map)),
          )
          .toList(),
      configuration: configurationValue is Map
          ? DeckWorkspace.fromMap(
              Map<String, Object?>.from(configurationValue),
            )
          : DeckWorkspace(),
    );
  }

  /// Ack schema for validating complete deck/presentation JSON.
  static final schema = Ack.object({
    'slides': Ack.list(Slide.schema),
    'configuration': DeckWorkspace.schema.optional(),
  });

  static Deck parse(Map<String, Object?> map) {
    final payload = schema.parse(map) as Map<String, Object?>;
    return fromMap(payload);
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
