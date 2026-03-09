import '../parsers/raw_slide_schema.dart';

/// Represents the context for processing a slide during the build process.
/// It holds the raw slide data and manages associated assets.
class TaskContext {
  /// The index of the slide in the original list.
  final int slideIndex;

  /// The raw slide being processed.
  RawSlideMarkdown slide;

  TaskContext(this.slideIndex, this.slide);
}
