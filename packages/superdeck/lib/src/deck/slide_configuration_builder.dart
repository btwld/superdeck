import 'package:superdeck_core/superdeck_core.dart';

import '../builtins/widgets.dart';
import 'deck_options.dart';
import 'slide_configuration.dart';
import 'template_resolver.dart';
import 'widget_definition.dart';

/// Builds [SlideConfiguration] view models from [Slide]s and [DeckOptions].
class SlideConfigurationBuilder {
  const SlideConfigurationBuilder();

  /// Builds [SlideConfiguration]s for [slides] using [options].
  List<SlideConfiguration> buildConfigurations(
    List<Slide> slides,
    DeckOptions options,
  ) {
    if (slides.isEmpty) {
      return [];
    }

    final resolver = TemplateResolver(options);

    return slides.asMap().entries.map((entry) {
      return _buildConfiguration(entry.key, entry.value, options, resolver);
    }).toList();
  }

  SlideConfiguration _buildConfiguration(
    int index,
    Slide slide,
    DeckOptions options,
    TemplateResolver resolver,
  ) {
    final widgets = Map<String, WidgetDefinition>.from(builtInWidgets);

    final usedWidgetNames = slide.sections
        .expand((section) => section.blocks)
        .whereType<WidgetBlock>()
        .map((block) => block.name)
        .toSet();

    for (final name in usedWidgetNames) {
      final userWidget = options.widgets[name];
      if (userWidget != null) {
        widgets[name] = userWidget;
      }
    }

    final resolution = resolver.resolve(slide.options);

    return SlideConfiguration(
      slideIndex: index,
      style: resolution.style,
      slide: slide,
      widgets: widgets,
      thumbnailKey: buildThumbnailKey(slide.key),
      parts: resolution.parts,
      debug: options.debug,
    );
  }
}
