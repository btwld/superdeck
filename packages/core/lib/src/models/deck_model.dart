import 'package:ack/ack.dart';
import 'package:collection/collection.dart';

import '../deck_configuration.dart';
import 'slide_model.dart';

/// Represents a complete presentation deck.
///
/// A deck contains a list of slides and configuration settings.
/// This is the root model that gets serialized to superdeck.json.
class Deck {
  const Deck({required this.slides, required this.configuration});

  /// The list of slides in this deck.
  final List<Slide> slides;

  /// Configuration settings for this deck.
  final DeckConfiguration configuration;

  Deck copyWith({List<Slide>? slides, DeckConfiguration? configuration}) {
    return Deck(
      slides: slides ?? this.slides,
      configuration: configuration ?? this.configuration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slides': slides.map((s) => s.toMap()).toList(),
      'configuration': configuration.toMap(),
    };
  }

  static Deck fromMap(Map<String, dynamic> map) {
    return Deck(
      slides:
          (map['slides'] as List<dynamic>?)
              ?.map((e) => Slide.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      configuration: DeckConfiguration.fromMap(
        map['configuration'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Validation schema for the complete deck structure.
  ///
  /// This schema validates the entire superdeck.json file including
  /// all slides, sections, blocks, and configuration.
  static final schema = Ack.object({
    'slides': Ack.list(Slide.schema),
    'configuration': DeckConfiguration.schema.optional(),
  }, additionalProperties: true);

  /// Parses a deck from a JSON map with validation.
  ///
  /// Validates the map against the schema before parsing.
  /// Throws an [AckException] if validation fails.
  static Deck parse(Map<String, dynamic> map) {
    schema.parse(map);
    return fromMap(map);
  }

  /// Safely parses a deck from a JSON map with validation.
  ///
  /// Returns a [SchemaResult] containing either the parsed deck
  /// or validation errors.
  static SchemaResult<Map<String, Object?>> safeParse(Map<String, dynamic> map) {
    return schema.safeParse(map);
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
