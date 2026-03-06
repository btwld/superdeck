import 'package:superdeck_core/superdeck_core.dart';

import '../deck/slide_configuration.dart';
import '../deck/slide_configuration_builder.dart';
import 'deck_presentation.dart';

class PresentationSlideBuilder {
  final DeckConfiguration configuration;

  const PresentationSlideBuilder({required this.configuration});

  List<SlideConfiguration> buildConfigurations(
    List<Slide> slides,
    DeckPresentation presentation,
  ) {
    return SlideConfigurationBuilder(
      configuration: configuration,
    ).buildConfigurations(slides, presentation.toDeckOptions());
  }
}
