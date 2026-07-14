import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_quality_report.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_trace.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  test('reports deck invariants, design distributions, and timings', () {
    final report = GenerationQualityReport.evaluate(
      request: const DeckGenerationRequest(
        userIntent: 'Explain the decision.',
        slideCount: 3,
      ),
      plan: _plan(),
      slides: _slides(),
      traces: _traces(),
      replayedSlideCount: 3,
      capturedSlideCount: 3,
      resolvedFontFamilies: const {'Playfair Display', 'Inter'},
      captureElapsed: const Duration(milliseconds: 640),
    );

    expect(report.passed, isTrue);
    expect(report.issues, isEmpty);
    expect(report.counts, {
      'requested': 3,
      'planned': 3,
      'generated': 3,
      'replayed': 3,
      'captured': 3,
    });
    expect(report.compositionDistribution, {
      'title': 1,
      'table': 1,
      'quote': 1,
    });
    expect(report.treatmentDistribution, {'hero': 1, 'data': 1, 'closing': 1});
    expect(report.densityDistribution, {'spacious': 2, 'balanced': 1});
    expect(report.modelRequests, {
      'total': 4,
      'outline': 1,
      'slides': 3,
      'outlineRepairs': 0,
      'slideRepairs': 0,
      'repairs': 0,
    });
    expect(report.toJson()['timings'], {
      'generationElapsedMs': 80,
      'captureElapsedMs': 640,
    });
    expect(report.toJson()['theme'], {
      'id': 'editorial-midnight',
      'version': 1,
      'density': 'spacious',
      'resolved': true,
    });
  });

  test('identifies the exact slide or rule for quality failures', () {
    final slides = _slides();
    final denseSlide = Slide(
      key: slides[1].key,
      options: slides[1].options,
      sections: [SectionBlock.text(List.filled(800, 'x').join())],
    );
    final report = GenerationQualityReport.evaluate(
      request: const DeckGenerationRequest(
        userIntent: 'Explain the decision.',
        slideCount: 3,
      ),
      plan: _plan(),
      slides: [slides[0], denseSlide, slides[2]],
      traces: _traces(),
      replayedSlideCount: 2,
      capturedSlideCount: 1,
      resolvedFontFamilies: const {'Inter'},
    );

    expect(report.passed, isFalse);
    expect(
      report.issues.map((issue) => issue.rule),
      containsAll({
        'count.replayed',
        'count.captured',
        'font.headline',
        'slide.content_density',
      }),
    );
    expect(
      report.issues
          .where((issue) => issue.rule == 'slide.content_density')
          .single
          .slideKey,
      'evidence',
    );
  });

  test('separates outline and slide repair requests', () {
    final report = GenerationQualityReport.evaluate(
      request: const DeckGenerationRequest(
        userIntent: 'Explain the decision.',
        slideCount: 3,
      ),
      plan: _plan(),
      slides: _slides(),
      traces: [
        ..._traces(),
        const GenerationTraceEvent(
          kind: GenerationTraceKind.request,
          phase: GenerationTracePhase.outline,
          attempt: 2,
          elapsed: Duration(milliseconds: 90),
        ),
        const GenerationTraceEvent(
          kind: GenerationTraceKind.request,
          phase: GenerationTracePhase.slide,
          attempt: 2,
          elapsed: Duration(milliseconds: 100),
        ),
      ],
      replayedSlideCount: 3,
      capturedSlideCount: 3,
      resolvedFontFamilies: const {'Playfair Display', 'Inter'},
    );

    expect(report.modelRequests, {
      'total': 6,
      'outline': 2,
      'slides': 4,
      'outlineRepairs': 1,
      'slideRepairs': 1,
      'repairs': 2,
    });
  });
}

DeckPlanType _plan() => DeckPlanType.parse({
  'topic': 'Decision quality',
  'story': 'Move from context to evidence to a clear choice.',
  'theme': {'id': 'editorial-midnight', 'version': 1, 'density': 'spacious'},
  'sections': [
    {
      'key': 'decision',
      'title': 'Decision',
      'purpose': 'Frame and resolve the decision.',
      'transition': 'Land on the recommendation.',
      'slideKeys': ['opening', 'evidence', 'close'],
    },
  ],
  'slides': [
    _planSlide(
      key: 'opening',
      composition: 'title',
      treatment: 'hero',
      density: 'spacious',
    ),
    _planSlide(
      key: 'evidence',
      composition: 'table',
      treatment: 'data',
      density: 'balanced',
    ),
    _planSlide(
      key: 'close',
      composition: 'quote',
      treatment: 'closing',
      density: 'spacious',
    ),
  ],
});

Map<String, Object?> _planSlide({
  required String key,
  required String composition,
  required String treatment,
  required String density,
}) => {
  'key': key,
  'title': key,
  'purpose': 'Advance $key.',
  'sectionKey': 'decision',
  'assertion': '$key matters.',
  'contentUnits': ['$key evidence'],
  'narrativeRole': key == 'opening'
      ? 'opening'
      : key == 'close'
      ? 'closing'
      : 'evidence',
  'contentBrief': 'Use concrete $key content.',
  'continuity': 'Connect the decision story.',
  'composition': composition,
  'treatment': treatment,
  'density': density,
};

List<Slide> _slides() => [
  Slide(
    key: 'opening',
    options: SlideOptions(style: 'hero'),
    sections: [SectionBlock.text('# The choice in front of us')],
  ),
  Slide(
    key: 'evidence',
    options: SlideOptions(style: 'data'),
    sections: [
      SectionBlock.text(
        '## Evidence\n\n| Option | Score |\n| --- | ---: |\n| A | 84 |',
      ),
    ],
  ),
  Slide(
    key: 'close',
    options: SlideOptions(style: 'closing'),
    sections: [SectionBlock.text('> Choose the path that compounds learning.')],
  ),
];

List<GenerationTraceEvent> _traces() => [
  const GenerationTraceEvent(
    kind: GenerationTraceKind.request,
    phase: GenerationTracePhase.outline,
    elapsed: Duration(milliseconds: 10),
  ),
  for (var index = 1; index <= 3; index++)
    GenerationTraceEvent(
      kind: GenerationTraceKind.request,
      phase: GenerationTracePhase.slide,
      slideIndex: index,
      elapsed: Duration(milliseconds: index * 20),
    ),
  const GenerationTraceEvent(
    kind: GenerationTraceKind.phaseDone,
    phase: GenerationTracePhase.finalize,
    elapsed: Duration(milliseconds: 80),
  ),
];
