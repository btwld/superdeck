import 'package:collection/collection.dart';

import '../deck_configuration.dart';
import 'slide_model.dart';

class Deck {
  const Deck({
    required this.slides,
    required this.configuration,
  });

  final List<Slide> slides;
  final DeckConfiguration configuration;

  Deck copyWith({
    List<Slide>? slides,
    DeckConfiguration? configuration,
  }) {
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
      slides: (map['slides'] as List<dynamic>?)
              ?.map((e) => Slide.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      configuration: DeckConfiguration.fromMap(
          map['configuration'] as Map<String, dynamic>? ?? {}),
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
