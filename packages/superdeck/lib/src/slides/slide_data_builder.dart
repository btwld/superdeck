import 'package:superdeck_core/superdeck_core.dart';

import '../presentation/block_definition.dart';
import '../presentation/deck_theme.dart';
import '../presentation/template_resolver.dart';
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
  const SlideDataBuilder();

  /// Builds a list of SlideData objects from raw slides and theme options.
  List<SlideData> buildSlides(List<Slide> rawSlides, DeckTheme theme) {
    final resolver = TemplateResolver(theme);

    return rawSlides.asMap().entries.map((entry) {
      return _buildSlideData(entry.key, entry.value, theme, resolver);
    }).toList();
  }

  /// Builds a single SlideData from a Slide and theme options.
  SlideData _buildSlideData(
    int index,
    Slide slide,
    DeckTheme theme,
    TemplateResolver resolver,
  ) {
    final widgets = Map<String, BlockDefinition>.from(builtInWidgets);

    final usedWidgetNames = slide.sections
        .expand((section) => section.blocks)
        .whereType<WidgetBlock>()
        .map((block) => block.name)
        .toSet();

    for (final name in usedWidgetNames) {
      final userWidget = theme.widgets[name];
      if (userWidget != null) {
        widgets[name] = userWidget;
      }
    }

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
