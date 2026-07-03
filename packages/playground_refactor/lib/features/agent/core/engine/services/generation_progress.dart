/// Phases of deck generation for progress tracking.
enum GenerationPhase {
  /// No generation in progress.
  idle,

  /// Phase 1: Generating presentation outline (structure + image requirements).
  generatingOutline,

  /// Phase 2: Generating illustrations for slides with image requirements.
  generatingImages,

  /// Phase 3: Generating final deck with available images context.
  generatingFinalDeck,

  /// Writing final JSON and cleaning up assets.
  finalizing,

  /// Generating thumbnail previews from the finalized deck.
  generatingThumbnails,
}

/// Progress information for image generation phase.
class ImageGenerationProgress {
  /// Number of images successfully generated.
  final int completed;

  /// Total number of images to generate.
  final int total;

  /// Number of images that failed to generate.
  final int failed;

  const ImageGenerationProgress({
    required this.completed,
    required this.total,
    this.failed = 0,
  });

  /// Remaining images to process.
  int get remaining => total - completed - failed;

  /// Whether all images have been processed (success or failure).
  bool get isComplete => completed + failed >= total;

  /// Progress as a fraction (0.0 to 1.0).
  double get fraction => total > 0 ? (completed + failed) / total : 0.0;
}

/// Callback for generation progress updates.
typedef GenerationProgressCallback =
    void Function(
      GenerationPhase phase,
      ImageGenerationProgress? imageProgress,
    );

/// Human-readable label for each [GenerationPhase].
extension GenerationPhaseLabel on GenerationPhase {
  String get label => switch (this) {
    GenerationPhase.generatingOutline => 'Planning the outline…',
    GenerationPhase.generatingImages => 'Generating images…',
    GenerationPhase.generatingFinalDeck => 'Writing the slides…',
    GenerationPhase.finalizing => 'Finalizing…',
    GenerationPhase.generatingThumbnails => 'Rendering thumbnails…',
    GenerationPhase.idle => 'Working…',
  };
}
