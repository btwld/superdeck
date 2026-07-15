part of 'deck_generator_service.dart';

void _logPipelineConfig(DeckGeneratorService owner, {required String prompt}) {
  debugLog.section('Deck Generation Pipeline');
  debugLog.log(
    'DECK_GEN',
    'Config: outlineModel=${owner.outlineModelName}, '
        'outlineRepairModel=${owner.outlineRepairModelName}, '
        'slideModel=${owner.modelName}, thinkingBudget=0',
  );
  debugLog.log('DECK_GEN', 'Prompt (${prompt.length} chars):\n$prompt');
}

int _defaultRepairBudget(int slideCount) {
  final proportionalBudget = (slideCount * 15) ~/ 100;
  return proportionalBudget < 3 ? 3 : proportionalBudget;
}

Future<DeckPlanType?> _runOutlinePhase(
  DeckGeneratorService owner, {
  required GenerationModelCallExecutor executor,
  required String prompt,
  required DeckGenerationRequest request,
  required List<PresentationThemeDescriptor> themeCandidates,
  required GenerationProgressCallback? onProgress,
  required GenerationTraceEmitter trace,
}) async {
  debugLog.section('Phase 1: Generate Outline');
  trace.emit(
    kind: GenerationTraceKind.phaseStarted,
    phase: GenerationTracePhase.outline,
  );
  onProgress?.call(const GenerationProgress(GenerationPhase.generatingOutline));
  final outlineStart = DateTime.now();
  final outline = await owner._generateOutline(
    executor,
    prompt,
    trace,
    request,
    themeCandidates,
  );
  final outlineMs = DateTime.now().difference(outlineStart).inMilliseconds;

  if (outline == null) {
    debugLog.error(
      'DECK_GEN',
      'Phase 1 FAILED after ${outlineMs}ms - no outline returned',
    );
    return null;
  }

  final outlineSlides = outline.slides.length;
  debugLog.log(
    'DECK_GEN',
    'Phase 1 COMPLETE in ${outlineMs}ms - '
        'topic: "${outline.topic}", slides: $outlineSlides',
  );
  trace.emit(
    kind: GenerationTraceKind.phaseDone,
    phase: GenerationTracePhase.outline,
  );
  return outline;
}

Future<_SlideCompositionResult?> _runSlideCompositionPhase(
  DeckGeneratorService owner, {
  required GenerationModelCallExecutor executor,
  required String prompt,
  required DeckGenerationRequest request,
  required DeckPlanType outline,
  required GenerationProgressCallback? onProgress,
  required GenerationTraceEmitter trace,
  required bool Function()? isCancelled,
}) async {
  debugLog.section('Phase 2: Compose Slides');
  trace.emit(
    kind: GenerationTraceKind.phaseStarted,
    phase: GenerationTracePhase.composition,
  );
  onProgress?.call(const GenerationProgress(GenerationPhase.composingSlides));
  final deckStart = DateTime.now();
  final composition = await owner._composeSlides(
    executor,
    prompt,
    outline,
    request,
    trace,
    onProgress,
    isCancelled,
  );
  final deckMs = DateTime.now().difference(deckStart).inMilliseconds;

  if (composition == null) {
    debugLog.error(
      'DECK_GEN',
      'Phase 2 FAILED after ${deckMs}ms - no deck JSON returned',
    );
    return null;
  }

  final deckSlides = composition.slides.length;
  debugLog.log(
    'DECK_GEN',
    'Phase 2 COMPLETE in ${deckMs}ms - $deckSlides accepted, '
        '${composition.failures.length} failed',
  );
  trace.emit(
    kind: GenerationTraceKind.phaseDone,
    phase: GenerationTracePhase.composition,
  );
  return composition;
}

DeckGenerationResult _finalizeDeck(
  DeckGeneratorService owner, {
  required _SlideCompositionResult composition,
  required DeckPlanType plan,
  required DateTime pipelineStart,
  required GenerationProgressCallback? onProgress,
  required bool Function()? isCancelled,
  required GenerationTraceEmitter trace,
}) {
  debugLog.section('Finalize');
  onProgress?.call(const GenerationProgress(GenerationPhase.finalizing));

  final slides = composition.slides;

  debugLog.log('DECK_GEN', 'Pre-sanitize: ${slides.length} slides');
  final sanitizedSlides = sanitizeGeneratedSlides(slides);
  debugLog.log(
    'DECK_GEN',
    'Post-sanitize: ${sanitizedSlides.length} slides '
        '(${slides.length - sanitizedSlides.length} removed)',
  );

  if (sanitizedSlides.isEmpty) {
    final failureSummary = composition.failures.isEmpty
        ? 'No slides generated.'
        : 'No slides could be generated; '
              '${composition.failures.length} '
              '${composition.failures.length == 1 ? 'slide failed' : 'slides failed'}.';
    debugLog.error('DECK_GEN', failureSummary);
    trace.emit(
      kind: GenerationTraceKind.validation,
      phase: GenerationTracePhase.finalize,
      validationErrors: [failureSummary],
    );
    return DeckGenerationResult.failure(failureSummary);
  }

  final expectedAcceptedCount =
      plan.slides.length - composition.failures.length;
  if (sanitizedSlides.length != expectedAcceptedCount) {
    final message =
        'Generated ${sanitizedSlides.length} usable slides; '
        'expected $expectedAcceptedCount accepted slide results.';
    debugLog.error('DECK_GEN', message);
    trace.emit(
      kind: GenerationTraceKind.validation,
      phase: GenerationTracePhase.finalize,
      validationErrors: [message],
    );
    return DeckGenerationResult.failure(message);
  }

  final parsedSlides = _parseSanitizedSlides(sanitizedSlides);
  if (parsedSlides == null) {
    trace.emit(
      kind: GenerationTraceKind.validation,
      phase: GenerationTracePhase.finalize,
      validationErrors: const ['Generated slide schema was invalid'],
    );
    return DeckGenerationResult.failure('Generated slide schema was invalid');
  }

  if (_generationCancelled(isCancelled)) {
    debugLog.log('DECK_GEN', 'Generation cancelled before finalizing');
    return DeckGenerationResult.failure('Generation cancelled.');
  }

  final totalMs = DateTime.now().difference(pipelineStart).inMilliseconds;
  debugLog.log(
    'DECK_GEN',
    'Pipeline COMPLETE in ${totalMs}ms - ${sanitizedSlides.length} slides',
  );
  trace.emit(
    kind: GenerationTraceKind.validation,
    phase: GenerationTracePhase.finalize,
  );

  final theme = resolveDeckThemeReference(
    plan.theme,
    themeCatalog: owner.themeCatalog,
    typographyCatalog: owner.typographyCatalog,
  );

  if (composition.failures.isNotEmpty) {
    return DeckGenerationResult.partial(
      slides: parsedSlides,
      slideFailures: composition.failures,
      plan: plan,
      theme: theme,
    );
  }

  return DeckGenerationResult.success(
    slides: parsedSlides,
    plan: plan,
    theme: theme,
  );
}

String _argumentMessage(Object error) => error
    .toString()
    .replaceFirst('Invalid argument(s): ', '')
    .replaceFirst('Invalid argument: ', '');

bool _generationCancelled(bool Function()? isCancelled) =>
    isCancelled?.call() ?? false;

List<Slide>? _parseSanitizedSlides(List<Map<String, dynamic>> slides) {
  final parsed = <Slide>[];
  for (var i = 0; i < slides.length; i++) {
    try {
      parsed.add(Slide.parse(Map<String, Object?>.from(slides[i])));
    } catch (error) {
      debugLog.log('DECK_GEN', 'Invalid sanitized slide $i: $error');
      return null;
    }
  }
  return parsed;
}
