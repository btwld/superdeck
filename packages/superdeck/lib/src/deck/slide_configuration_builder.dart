import 'package:superdeck_core/superdeck_core.dart';

import '../builtins/widgets.dart';
import 'deck_options.dart';
import 'slide_configuration.dart';
import 'template_resolver.dart';
import 'widget_definition.dart';

/// Service responsible for transforming raw Slide domain entities
/// into SlideConfiguration view models ready for rendering.
///
/// This class encapsulates the business logic of:
/// - Style merging (default → base → slide-specific)
/// - Widget builder collection
/// - Thumbnail path generation
class SlideConfigurationBuilder {
  final DeckConfiguration configuration;

  const SlideConfigurationBuilder({required this.configuration});

  /// Builds a list of SlideConfigurations from raw slides and options.
  List<SlideConfiguration> buildConfigurations(
    List<Slide> rawSlides,
    DeckOptions options,
  ) {
    if (rawSlides.isEmpty) {
      return [];
    }

    final resolver = TemplateResolver(options);

    return rawSlides.asMap().entries.map((entry) {
      return _buildConfiguration(entry.key, entry.value, options, resolver);
    }).toList();
  }

  /// Builds a single SlideConfiguration from a Slide and options.
  SlideConfiguration _buildConfiguration(
    int index,
    Slide slide,
    DeckOptions options,
    TemplateResolver resolver,
  ) {
    // Start with built-in widgets, then add user widgets that are actually used
    final widgets = Map<String, WidgetDefinition>.from(builtInWidgets);

    // Collect widget names used in this slide
    final usedWidgetNames = slide.sections
        .expand((section) => section.blocks)
        .whereType<WidgetBlock>()
        .map((block) => block.name)
        .toSet();

    // Add user widgets that are used (overriding built-ins if necessary)
    for (final name in usedWidgetNames) {
      final userWidget = options.widgets[name];
      if (userWidget != null) {
        widgets[name] = userWidget;
      }
    }

    // Generate thumbnail asset key using slide key.
    final thumbnailAsset = GeneratedAsset.thumbnail(slide.key);

    // Resolve template, style, and parts
    final resolution = resolver.resolve(slide.options);

    return SlideConfiguration(
      slideIndex: index,
      style: resolution.style,
      slide: slide,
      widgets: widgets,
      thumbnailFile: thumbnailAsset.fileName,
      parts: resolution.parts,
      debug: options.debug,
    );
  }
}
