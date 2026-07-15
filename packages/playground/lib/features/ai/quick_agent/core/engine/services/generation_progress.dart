/// Phases of deck generation for progress tracking.
enum GenerationPhase {
  /// No generation in progress.
  idle,

  /// Phase 1: Generating presentation outline (structure + layout hints).
  generatingOutline,

  /// Phase 2: Composing and validating slides from the deck plan.
  composingSlides,

  /// Writing final JSON and cleaning up.
  finalizing,

  /// Generating thumbnail previews from the finalized deck.
  generatingThumbnails,
}

/// Detailed progress for a generation run.
final class GenerationProgress {
  const GenerationProgress(
    this.phase, {
    this.slideIndex,
    this.slideCount,
    this.sectionIndex,
    this.sectionCount,
    this.isRepairing = false,
  });

  final GenerationPhase phase;
  final int? slideIndex;
  final int? slideCount;
  final int? sectionIndex;
  final int? sectionCount;
  final bool isRepairing;

  String get label {
    final currentSection = sectionIndex;
    final totalSections = sectionCount;
    if (phase == GenerationPhase.composingSlides &&
        currentSection != null &&
        totalSections != null) {
      return 'Composing section $currentSection of $totalSections…';
    }
    final index = slideIndex;
    final count = slideCount;
    if (phase == GenerationPhase.composingSlides &&
        index != null &&
        count != null) {
      return '${isRepairing ? 'Repairing' : 'Composing'} slide $index of $count…';
    }
    return phase.label;
  }
}

/// Callback for generation progress updates.
typedef GenerationProgressCallback = void Function(GenerationProgress progress);

/// Human-readable label for each [GenerationPhase].
extension GenerationPhaseLabel on GenerationPhase {
  String get label => switch (this) {
    GenerationPhase.generatingOutline => 'Planning the outline…',
    GenerationPhase.composingSlides => 'Composing the slides…',
    GenerationPhase.finalizing => 'Finalizing…',
    GenerationPhase.generatingThumbnails => 'Rendering thumbnails…',
    GenerationPhase.idle => 'Working…',
  };
}
