import 'package:superdeck_builder/src/parsers/raw_slide_schema.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Represents the context for processing a slide during the build process.
/// It holds the raw slide data and manages associated assets.
class SlideContext {
  /// The index of the slide in the original list.
  final int slideIndex;
  final DeckService dataStore;

  /// The raw slide being processed.
  RawSlideMarkdownType slide;

  SlideContext(this.slideIndex, this.slide, this.dataStore);
}
