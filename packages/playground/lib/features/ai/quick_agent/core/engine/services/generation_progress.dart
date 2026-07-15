/// Phases of deck generation for progress tracking.
enum GenerationPhase {
  /// No generation in progress.
  idle,

  /// Phase 1: Generating presentation outline (structure + layout hints).
  generatingOutline,

  /// Phase 2: Generating the bounded set of planned slide artwork.
  generatingImages,

  /// Phase 3: Composing and validating slides from the deck plan.
  composingSlides,

  /// Writing final JSON and cleaning up.
  finalizing,

  /// Generating thumbnail previews from the finalized deck.
  generatingThumbnails,
}

/// Detailed progress for a generation run.
final class GenerationProgress {
  final GenerationPhase phase;

  final int? slideIndex;
  final int? slideCount;
  final int? sectionIndex;
  final int? sectionCount;
  final int? completedItems;
  final int? totalItems;
  final bool isRepairing;
  const GenerationProgress(
    this.phase, {
    this.slideIndex,
    this.slideCount,
    this.sectionIndex,
    this.sectionCount,
    this.completedItems,
    this.totalItems,
    this.isRepairing = false,
  });

  String get label {
    final completed = completedItems;
    final total = totalItems;
    if (phase == .generatingImages && completed != null && total != null) {
      if (total == 0) return 'Preparing slide artwork…';

      return 'Creating slide artwork $completed of $total…';
    }
    final currentSection = sectionIndex;
    final totalSections = sectionCount;
    if (phase == GenerationPhase.composingSlides &&
        currentSection != null &&
        totalSections != null) {
      return 'Composed section $currentSection of $totalSections…';
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
    .generatingImages => 'Creating slide artwork…',
    GenerationPhase.composingSlides => 'Composing the slides…',
    GenerationPhase.finalizing => 'Finalizing…',
    GenerationPhase.generatingThumbnails => 'Rendering thumbnails…',
    GenerationPhase.idle => 'Working…',
  };
}
