/// Phases of deck generation for progress tracking.
enum GenerationPhase {
  /// No generation in progress.
  idle,

  /// Phase 1: Generating presentation outline (structure + layout hints).
  generatingOutline,

  /// Phase 2: Generating final deck from the outline.
  generatingFinalDeck,

  /// Writing final JSON and cleaning up.
  finalizing,

  /// Generating thumbnail previews from the finalized deck.
  generatingThumbnails,
}

/// Callback for generation progress updates.
typedef GenerationProgressCallback = void Function(GenerationPhase phase);

/// Human-readable label for each [GenerationPhase].
extension GenerationPhaseLabel on GenerationPhase {
  String get label => switch (this) {
    GenerationPhase.generatingOutline => 'Planning the outline…',
    GenerationPhase.generatingFinalDeck => 'Writing the slides…',
    GenerationPhase.finalizing => 'Finalizing…',
    GenerationPhase.generatingThumbnails => 'Rendering thumbnails…',
    GenerationPhase.idle => 'Working…',
  };
}
