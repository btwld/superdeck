import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

import '../styling/styles.dart';
import 'deck_options.dart';
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
    DeckOptions options,
  ) {
    if (rawSlides.isEmpty) {
      return [];
    }

    return rawSlides.asMap().entries.map((entry) {
      return _buildConfiguration(entry.key, entry.value, options);
    }).toList();
  }

  /// Builds a single SlideConfiguration from a Slide and options.
  SlideConfiguration _buildConfiguration(
    int index,
    Slide slide,
    DeckOptions options,
  ) {
    // Collect widget builders that are used in this slide
    final widgets = <String, WidgetBlockBuilder>{};
    for (final section in slide.sections) {
      for (final block in section.blocks) {
        if (block is WidgetBlock && options.widgets.containsKey(block.name)) {
          widgets[block.name] = options.widgets[block.name]!;
        }
      }
    }

    // Generate thumbnail path using slide key and assets directory
    final thumbnailAsset = GeneratedAsset.thumbnail(slide.key);
    final thumbnailPath = p.join(
      configuration.assetsDir.path,
      thumbnailAsset.fileName,
    );

    // Merge styles: default -> base -> slide-specific
    final mergedStyle = defaultSlideStyle
        .merge(options.baseStyle)
        .merge(options.styles[slide.options?.style]);

    return SlideConfiguration(
      slideIndex: index,
      style: mergedStyle,
      slide: slide,
      widgets: widgets,
      thumbnailFile: thumbnailPath,
      parts: options.parts,
      debug: options.debug,
    );
  }
}
