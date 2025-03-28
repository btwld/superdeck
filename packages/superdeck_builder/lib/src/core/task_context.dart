import 'package:superdeck_builder/src/parsers/markdown_parser.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Represents the context in which a slide is processed.
/// It holds the raw slide data and manages associated assets.
class TaskContext {
  /// The index of the slide in the original list.
  final int slideIndex;
  final FileSystemPresentationRepository dataStore;

  /// The raw slide being processed.
  RawSlideMarkdown slide;

  TaskContext(this.slideIndex, this.slide, this.dataStore);

  /// Creates a clone of this context with the same slide
  TaskContext clone() {
    return TaskContext(slideIndex, slide, dataStore);
  }
}
