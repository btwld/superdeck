import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

import 'slide_model.dart';

part 'deck_model.mapper.dart';

@MappableClass()
class Deck with DeckMappable {
  final List<Slide> slides;

  Deck({required List<Slide> slides}) : slides = List.unmodifiable(slides);

  static final fromMap = DeckMapper.fromMap;

  /// Ack schema for validating complete deck/presentation JSON.
  static final schema = Ack.object({
    'slides': Ack.list(Slide.schema),
    // Legacy deck payloads may still contain configuration. Runtime ignores it.
    'configuration': Ack.object({}).passthrough().optional(),
  });

  static Deck parse(Map<String, Object?> map) {
    final validated = Map<String, dynamic>.from(schema.parse(map)!);
    validated.remove('configuration');
    return fromMap(validated);
  }
}
