import 'package:superdeck_core/superdeck_core.dart';

import '../parsers/raw_slide_schema.dart';

/// Represents the context for processing a slide during the build process.
/// It holds the raw slide data and manages associated assets.
class SlideContext {
  /// The index of the slide in the original list.
  final int slideIndex;
  final DeckService dataStore;

  /// The raw slide being processed.
  RawSlideMarkdown slide;

  SlideContext(this.slideIndex, this.slide, this.dataStore);
}
