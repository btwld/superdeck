part of 'deck_generator_service.dart';

void _logPipelineConfig(DeckGeneratorService owner, {required String prompt}) {
  debugLog.section('Deck Generation Pipeline');
  debugLog.log(
    'DECK_GEN',
    'Config: outlineModel=${owner.outlineModelName}, '
        'slideModel=${owner.modelName}, thinking=disabled',
  );
  debugLog.log('DECK_GEN', 'Prompt (${prompt.length} chars):\n$prompt');
}

Future<DeckPlanType?> _runOutlinePhase(
  DeckGeneratorService owner, {
  required GenerationModelClient service,
  required String prompt,
  required DeckGenerationRequest request,
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
  final outline = await owner._generateOutline(service, prompt, trace, request);
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

Future<Map<String, dynamic>?> _runSlideCompositionPhase(
  DeckGeneratorService owner, {
  required GenerationModelClient service,
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
  final deckJson = await owner._composeSlides(
    service,
    prompt,
    outline,
    request,
    trace,
    onProgress,
    isCancelled,
  );
  final deckMs = DateTime.now().difference(deckStart).inMilliseconds;

  if (deckJson == null) {
    debugLog.error(
      'DECK_GEN',
      'Phase 2 FAILED after ${deckMs}ms - no deck JSON returned',
    );
    return null;
  }

  final deckSlides = (deckJson['slides'] as List?)?.length ?? 0;
  debugLog.log(
    'DECK_GEN',
    'Phase 2 COMPLETE in ${deckMs}ms - $deckSlides raw slides',
  );
  trace.emit(
    kind: GenerationTraceKind.phaseDone,
    phase: GenerationTracePhase.composition,
  );
  return deckJson;
}

Future<DeckGenerationResult> _finalizeDeck(
  DeckGeneratorService owner, {
  required Map<String, dynamic> deckJson,
  required DeckPlanType plan,
  required DateTime pipelineStart,
  required GenerationProgressCallback? onProgress,
  required bool Function()? isCancelled,
  required GenerationTraceEmitter trace,
}) async {
  debugLog.section('Finalize');
  onProgress?.call(const GenerationProgress(GenerationPhase.finalizing));

  final slides = _extractSlides(deckJson);

  debugLog.log('DECK_GEN', 'Pre-sanitize: ${slides.length} slides');
  final sanitizedSlides = sanitizeGeneratedSlides(slides);
  debugLog.log(
    'DECK_GEN',
    'Post-sanitize: ${sanitizedSlides.length} slides '
        '(${slides.length - sanitizedSlides.length} removed)',
  );

  if (sanitizedSlides.isEmpty) {
    debugLog.error('DECK_GEN', 'No slides survived sanitization');
    trace.emit(
      kind: GenerationTraceKind.validation,
      phase: GenerationTracePhase.finalize,
      validationErrors: const ['No slides generated'],
    );
    return DeckGenerationResult.failure('No slides generated');
  }

  if (sanitizedSlides.length != plan.slides.length) {
    final message =
        'Generated ${sanitizedSlides.length} usable slides; '
        'expected exactly ${plan.slides.length}.';
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

  return DeckGenerationResult.success(slides: parsedSlides, plan: plan);
}

bool _generationCancelled(bool Function()? isCancelled) =>
    isCancelled?.call() ?? false;

List<Map<String, dynamic>> _extractSlides(Map<String, dynamic> deckJson) {
  final rawSlides = deckJson['slides'];
  if (rawSlides is! List) return const <Map<String, dynamic>>[];

  final slides = <Map<String, dynamic>>[];
  for (final entry in rawSlides.asMap().entries) {
    final index = entry.key;
    final rawSlide = entry.value;
    if (rawSlide is! Map) {
      debugLog.log('DECK_GEN', 'Discarding non-object slide at index $index');
      continue;
    }
    slides.add(Map<String, dynamic>.from(rawSlide));
  }

  return slides;
}

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
