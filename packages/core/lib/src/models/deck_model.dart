import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

import '../deck_workspace.dart';
import 'slide_model.dart';

part 'deck_model.mapper.dart';

@MappableClass()
class Deck with DeckMappable {
  final List<Slide> slides;
  final DeckWorkspace configuration;

  const Deck({required this.slides, required this.configuration});

  factory Deck.fromMap(Map<String, Object?> map) {
    final configurationValue = map['configuration'];
    return DeckMapper.fromMap({
      'slides': (map['slides'] as List<dynamic>? ?? const [])
          .map(
            (slide) => Slide.fromMap(Map<String, Object?>.from(slide as Map)),
          )
          .toList(),
      'configuration': configurationValue is Map
          ? DeckWorkspace.fromMap(Map<String, Object?>.from(configurationValue))
          : DeckWorkspace(),
    });
  }

  /// Ack schema for validating complete deck/presentation JSON.
  static final schema = Ack.object({
    'slides': Ack.list(Slide.schema),
    'configuration': DeckWorkspace.schema.optional(),
  });
}
