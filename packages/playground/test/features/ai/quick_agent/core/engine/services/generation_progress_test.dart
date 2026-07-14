import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_progress.dart';

void main() {
  group('GenerationPhaseLabel', () {
    test('every phase has a non-empty label', () {
      for (final phase in GenerationPhase.values) {
        expect(phase.label, isNotEmpty);
      }
    });

    test('maps each phase to its human-readable label', () {
      expect(GenerationPhase.generatingOutline.label, 'Planning the outline…');
      expect(GenerationPhase.composingSlides.label, 'Composing the slides…');
      expect(GenerationPhase.finalizing.label, 'Finalizing…');
      expect(
        GenerationPhase.generatingThumbnails.label,
        'Rendering thumbnails…',
      );
      expect(GenerationPhase.idle.label, 'Working…');
    });
  });

  test('describes slide composition and repair progress', () {
    expect(
      const GenerationProgress(
        GenerationPhase.composingSlides,
        slideIndex: 2,
        slideCount: 5,
      ).label,
      'Composing slide 2 of 5…',
    );
    expect(
      const GenerationProgress(
        GenerationPhase.composingSlides,
        slideIndex: 2,
        slideCount: 5,
        isRepairing: true,
      ).label,
      'Repairing slide 2 of 5…',
    );
  });
}
