import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'deck_reference.mapper.dart';

@MappableClass()
class DeckReference with DeckReferenceMappable {
  const DeckReference({
    required this.slides,
    required this.config,
  });

  final List<Slide> slides;
  final DeckConfiguration config;
}
