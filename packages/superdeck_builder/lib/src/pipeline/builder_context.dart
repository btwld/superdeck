import 'package:superdeck_core/superdeck_core.dart';

import '../parsers/markdown_parser.dart';

/// Represents the context in which a slide is processed.
/// It holds the raw slide data and manages associated assets.
class BuilderContext {
  /// The index of the slide in the original list.
  final int slideIndex;

  /// The data store for accessing files and resources.
  final FileSystemPresentationRepository dataStore;

  /// The raw slide being processed.
  final RawSlideMarkdown slide;

  /// Creates a new builder context.
  BuilderContext(this.slideIndex, this.slide, this.dataStore);
}
