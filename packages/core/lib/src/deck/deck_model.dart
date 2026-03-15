import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

import 'deck_configuration.dart';
import 'slide_model.dart';

part 'deck_model.mapper.dart';

@MappableClass()
class Deck with DeckMappable {
  final List<Slide> slides;
  final DeckConfiguration configuration;

  Deck({required List<Slide> slides, DeckConfiguration? configuration})
    : slides = List.unmodifiable(slides),
      configuration = configuration ?? DeckConfiguration();

  static final fromMap = DeckMapper.fromMap;

  /// Ack schema for validating complete deck/presentation JSON.
  static final schema = Ack.object({
    'slides': Ack.list(Slide.schema),
    'configuration': DeckConfiguration.schema.optional(),
  });

  static Deck parse(Map<String, Object?> map) => fromMap(schema.parse(map)!);
}
