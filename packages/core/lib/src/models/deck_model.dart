import 'package:ack/ack.dart';
import 'package:collection/collection.dart';

import '../deck_configuration.dart';
import 'slide_model.dart';

class Deck {
  const Deck({required this.slides, required this.configuration});

  final List<Slide> slides;
  final DeckConfiguration configuration;

  /// Validation schema for deck data.
  static final schema = Ack.object(
    {
      'slides': Ack.list(Slide.schema).description(
        'List of slides in the presentation, ordered by display sequence',
      ),
      'configuration': DeckConfiguration.schema.nullable().optional()
          .description('Deck configuration for paths and settings'),
    },
  ).description(
    'A complete deck/presentation containing slides and configuration. '
    'This is the root structure of a superdeck.json file.',
  );

  /// Parses a deck from a JSON map with validation.
  static Deck parse(Map<String, dynamic> map) {
    schema.parse(map);
    return fromMap(map);
  }

  /// Safely parses a deck from a JSON map, returning a result.
  static SchemaResult<Deck> safeParse(Map<String, dynamic> map) {
    final result = schema.safeParse(map);
    return result.match(
      onOk: (_) => SchemaResult.ok(fromMap(map)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

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
