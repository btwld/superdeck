import 'package:superdeck_core/superdeck_core.dart';

import '../presentation/deck_theme.dart';
import '../presentation/template_resolver.dart';
import '../presentation/widget_definition.dart';
import '../widgets/widgets.dart';
import 'slide_data.dart';

/// Service responsible for transforming raw Slide domain entities
/// into SlideData view models ready for rendering.
///
/// This class encapsulates the business logic of:
/// - Style merging (default → base → slide-specific)
/// - Widget builder collection
/// - Thumbnail path generation
class SlideDataBuilder {
  final DeckWorkspace configuration;

  const SlideDataBuilder({required this.configuration});

  /// Builds a list of SlideData objects from raw slides and theme options.
  List<SlideData> buildSlides(
    List<Slide> rawSlides,
    DeckTheme theme,
  ) {
    final resolver = TemplateResolver(theme);

    return rawSlides.asMap().entries.map((entry) {
      return _buildSlideData(
        entry.key,
        entry.value,
        theme,
        resolver,
      );
    }).toList();
  }

  /// Builds a single SlideData from a Slide and theme options.
  SlideData _buildSlideData(
    int index,
    Slide slide,
    DeckTheme theme,
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
      final userWidget = theme.widgets[name];
      if (userWidget != null) {
        widgets[name] = userWidget;
      }
    }

    // Resolve template, style, and frame
    final resolution = resolver.resolve(slide.options);
    final renderSignature = GeneratedAsset.buildKey(
      [
        slide.hashCode,
        resolution.style.hashCode,
        resolution.frame.hashCode,
        theme.debug.hashCode,
        usedWidgetNames.toList()..sort(),
      ].join('|'),
    );
    final thumbnailAsset = GeneratedAsset.thumbnail(
      slide.key,
      renderSignature: renderSignature,
    );

    return SlideData(
      slideIndex: index,
      style: resolution.style,
      slide: slide,
      widgets: widgets,
      thumbnailFile: thumbnailAsset.fileName,
      frame: resolution.frame,
      debug: theme.debug,
    );
  }
}
