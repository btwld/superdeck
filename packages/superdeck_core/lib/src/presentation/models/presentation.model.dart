import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'presentation.model.mapper.dart';

@MappableClass()
class Presentation with PresentationMappable {
  const Presentation({
    required this.slides,
    required this.configuration,
  });

  final List<Slide> slides;
  final PresentationConfig configuration;
}
