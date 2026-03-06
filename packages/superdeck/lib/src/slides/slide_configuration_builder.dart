import 'package:superdeck_core/superdeck_core.dart';

import '../presentation/deck_presentation.dart';
import '../presentation/template_resolver.dart';
import '../presentation/widget_definition.dart';
import '../widgets/widgets.dart';
import 'slide_configuration.dart';

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
    DeckPresentation presentation,
  ) {
    final resolver = TemplateResolver(presentation);

    return rawSlides.asMap().entries.map((entry) {
      return _buildConfiguration(
        entry.key,
        entry.value,
        presentation,
        resolver,
      );
    }).toList();
  }

  /// Builds a single SlideConfiguration from a Slide and options.
  SlideConfiguration _buildConfiguration(
    int index,
    Slide slide,
    DeckPresentation presentation,
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
      final userWidget = presentation.widgets[name];
      if (userWidget != null) {
        widgets[name] = userWidget;
      }
    }

    // Resolve template, style, and parts
    final resolution = resolver.resolve(slide.options);
    final renderSignature = GeneratedAsset.buildKey(
      [
        slide.hashCode,
        resolution.style.hashCode,
        resolution.parts.hashCode,
        presentation.debug.hashCode,
        usedWidgetNames.toList()..sort(),
      ].join('|'),
    );
    final thumbnailAsset = GeneratedAsset.thumbnail(
      slide.key,
      renderSignature: renderSignature,
    );

    return SlideConfiguration(
      slideIndex: index,
      style: resolution.style,
      slide: slide,
      widgets: widgets,
      thumbnailFile: thumbnailAsset.fileName,
      parts: resolution.parts,
      debug: presentation.debug,
    );
  }
}
