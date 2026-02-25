import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:collection/collection.dart';

import '../deck_configuration.dart';
import '../utils/schema_refinement_utils.dart';
import 'slide_model.dart';

part 'deck_model.g.dart';

bool _doesNotContainUnsupportedLegacyRootFields(Map<String, Object?> map) =>
    !map.containsKey('schemaVersion');

bool _doesNotSetNullForOptionalDeckFields(Map<String, Object?> map) =>
    doesNotSetExplicitNullForOptionalKeys(map, const ['style']);

@AckModel(
  additionalProperties: true,
  additionalPropertiesField: 'unknownRootFields',
)
class Deck {
  static const _knownRootFields = <String>{'slides', 'style', 'configuration'};
  final List<Slide> slides;
  final Map<String, Object?>? style;
  final DeckConfiguration configuration;
  final Map<String, Object?> unknownRootFields;

  const Deck({
    required this.slides,
    required this.configuration,
    this.style,
    this.unknownRootFields = const {},
  });

  Deck copyWith({
    List<Slide>? slides,
    Map<String, Object?>? style,
    DeckConfiguration? configuration,
    Map<String, Object?>? unknownRootFields,
  }) {
    return Deck(
      slides: slides ?? this.slides,
      style: style ?? this.style,
      configuration: configuration ?? this.configuration,
      unknownRootFields: unknownRootFields ?? this.unknownRootFields,
    );
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'slides': slides.map((s) => s.toMap()).toList(),
      'configuration': configuration.toMap(),
    };

    if (style != null) {
      map['style'] = Map<String, Object?>.from(style!);
    }

    if (unknownRootFields.isNotEmpty) {
      for (final entry in unknownRootFields.entries) {
        if (_knownRootFields.contains(entry.key)) {
          continue;
        }
        map[entry.key] = entry.value;
      }
    }

    return map;
  }

  static Deck fromMap(Map<String, Object?> map) {
    final payload = schema.parse(map) as Map<String, Object?>;

    return _fromPayload(payload);
  }

  /// Ack schema for validating complete deck/presentation JSON.
  static final schema = deckSchema
      .extend({
        'slides': Ack.list(Slide.schema),
        'configuration': DeckConfiguration.schema.optional(),
      })
      .refine(
        _doesNotContainUnsupportedLegacyRootFields,
        message:
            'Unsupported root field "schemaVersion". '
            'Deck contract is unversioned.',
      )
      .refine(
        _doesNotSetNullForOptionalDeckFields,
        message: '"style" cannot be null when provided.',
      );

  /// Alias for [fromMap].
  static Deck parse(Map<String, Object?> map) => fromMap(map);

  static Deck _fromPayload(Map<String, Object?> payload) {
    final styleValue = payload['style'];
    final configurationValue = payload['configuration'];
    return Deck(
      slides: (payload['slides'] as List<dynamic>)
          .map(
            (slide) => Slide.fromMap(Map<String, Object?>.from(slide as Map)),
          )
          .toList(),
      style: styleValue == null
          ? null
          : Map<String, Object?>.from(styleValue as Map),
      configuration: configurationValue == null
          ? DeckConfiguration()
          : DeckConfiguration.parse(
              Map<String, Object?>.from(configurationValue as Map),
            ),
      unknownRootFields: Map<String, Object?>.fromEntries(
        payload.entries.where((entry) => !_knownRootFields.contains(entry.key)),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Deck &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(slides, other.slides) &&
          const DeepCollectionEquality().equals(style, other.style) &&
          configuration == other.configuration &&
          const DeepCollectionEquality().equals(
            unknownRootFields,
            other.unknownRootFields,
          );

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(slides),
    const DeepCollectionEquality().hash(style),
    configuration,
    const DeepCollectionEquality().hash(unknownRootFields),
  );
}
