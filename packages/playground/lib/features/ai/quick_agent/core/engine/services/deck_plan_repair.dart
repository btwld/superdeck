part of 'deck_generator_service.dart';

final _slideScopedPlanErrorPattern = RegExp(r'^Slide "([^"]+)" ');

bool _onlySlideScopedPlanErrors(List<String> errors) =>
    errors.isNotEmpty && errors.every(_slideScopedPlanErrorPattern.hasMatch);

extension _DeckPlanRepair on DeckGeneratorService {
  Future<DeckPlanType> _repairInvalidOutlineSlides({
    required GenerationModelClient service,
    required String originalPrompt,
    required DeckPlanType plan,
    required DeckGenerationRequest request,
    required GenerationTraceEmitter trace,
    required int fullPlanAttempt,
  }) async {
    var repairedPlan = plan;
    final errorsByKey = _groupSlidePlanErrors(
      validateDeckPlan(
        repairedPlan,
        request: request,
        typographyCatalog: typographyCatalog,
      ),
    );

    for (final entry in errorsByKey.entries) {
      final index = repairedPlan.slides.indexWhere(
        (candidate) => candidate.key == entry.key,
      );
      if (index < 0) continue;
      final original = repairedPlan.slides[index];
      var repairBase = Map<String, Object?>.from(original);
      var constraints = List<String>.from(entry.value);

      for (
        var localAttempt = 1;
        localAttempt <= maxOutlineSlideValidationAttempts;
        localAttempt++
      ) {
        final candidate = await _generateOutlineSlideRepair(
          service: service,
          originalPrompt: originalPrompt,
          plan: repairedPlan,
          current: original,
          validationErrors: constraints,
          invalidSlide: repairBase,
          trace: trace,
          fullPlanAttempt: fullPlanAttempt,
          localAttempt: localAttempt,
          slideIndex: index,
        );
        if (candidate == null) continue;
        repairBase = Map<String, Object?>.from(candidate);

        final invariantErrors = _outlineSlideInvariantErrors(
          original: original,
          candidate: candidate,
        );
        if (invariantErrors.isNotEmpty) {
          _appendUnique(constraints, invariantErrors);
          continue;
        }

        final candidatePlan = _replacePlanSlide(
          repairedPlan,
          index: index,
          slide: candidate,
        );
        final candidateErrors = validateDeckPlan(
          candidatePlan,
          request: request,
          typographyCatalog: typographyCatalog,
        );
        final localErrors = candidateErrors
            .where((error) => error.startsWith('Slide "${entry.key}" '))
            .toList();
        if (localErrors.isEmpty) {
          repairedPlan = candidatePlan;
          break;
        }
        _appendUnique(constraints, localErrors);
      }
    }
    return repairedPlan;
  }

  Future<DeckPlanSlideType?> _generateOutlineSlideRepair({
    required GenerationModelClient service,
    required String originalPrompt,
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required List<String> validationErrors,
    required Map<String, Object?> invalidSlide,
    required GenerationTraceEmitter trace,
    required int fullPlanAttempt,
    required int localAttempt,
    required int slideIndex,
  }) async {
    final adapted = GoogleSchemaAdapter().adapt(
      deckPlanSlideSchema.toJsonSchemaBuilder(),
    );
    if (adapted.schema == null) return null;
    final systemPrompt = _promptProvider.buildOutlineSlideRepairPrompt(
      plan: plan,
      current: current,
      validationErrors: validationErrors,
      invalidSlide: invalidSlide,
    );
    final traceAttempt = fullPlanAttempt + localAttempt;
    final modelRequest = google_ai.GenerateContentRequest(
      model: outlineModelName,
      contents: [
        google_ai.Content(
          role: 'user',
          parts: [google_ai.Part(text: originalPrompt)],
        ),
      ],
      generationConfig: google_ai.GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: adapted.schema,
      ),
      systemInstruction: google_ai.Content(
        parts: [google_ai.Part(text: systemPrompt)],
      ),
    );

    debugLog.log(
      'DECK_GEN',
      'Repairing outline slide ${slideIndex + 1}/${plan.slides.length} '
          '(${current.key}), attempt $localAttempt...',
    );
    final response = await retryPolicy.run(() {
      trace.emit(
        kind: GenerationTraceKind.request,
        phase: GenerationTracePhase.outline,
        model: outlineModelName,
        attempt: traceAttempt,
        slideIndex: slideIndex + 1,
        slideCount: plan.slides.length,
        prompt: systemPrompt,
      );
      return service
          .generateContent(modelRequest)
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw TimeoutException('Outline slide repair timed out');
            },
          );
    });
    trace.emit(
      kind: GenerationTraceKind.response,
      phase: GenerationTracePhase.outline,
      model: outlineModelName,
      attempt: traceAttempt,
      slideIndex: slideIndex + 1,
      slideCount: plan.slides.length,
      response: _responseText(response),
    );
    final json = _parseJsonResponse(response, 'outline slide ${current.key}');
    if (json == null) return null;
    try {
      return DeckPlanSlideType.parse(json);
    } catch (error) {
      debugLog.error(
        'DECK_GEN',
        'Invalid outline slide repair for ${current.key}: $error',
      );
      return null;
    }
  }
}

Map<String, List<String>> _groupSlidePlanErrors(List<String> errors) {
  final grouped = <String, List<String>>{};
  for (final error in errors) {
    final key = _slideScopedPlanErrorPattern.firstMatch(error)?.group(1);
    if (key != null) grouped.putIfAbsent(key, () => []).add(error);
  }
  return grouped;
}

void _appendUnique(List<String> target, Iterable<String> additions) {
  for (final addition in additions) {
    if (!target.contains(addition)) target.add(addition);
  }
}

List<String> _outlineSlideInvariantErrors({
  required DeckPlanSlideType original,
  required DeckPlanSlideType candidate,
}) {
  final errors = <String>[];
  void requireSame(String field, Object? before, Object? after) {
    if (jsonEncode(before) != jsonEncode(after)) {
      errors.add(
        'Repair changed immutable field `$field`; restore its exact original '
        'value.',
      );
    }
  }

  requireSame('key', original.key, candidate.key);
  requireSame('sectionKey', original.sectionKey, candidate.sectionKey);
  requireSame('narrativeRole', original.narrativeRole, candidate.narrativeRole);
  requireSame('composition', original.composition, candidate.composition);
  requireSame('treatment', original.treatment, candidate.treatment);
  requireSame('density', original.density, candidate.density);
  requireSame('elements', original.elements, candidate.elements);
  return errors;
}

DeckPlanType _replacePlanSlide(
  DeckPlanType plan, {
  required int index,
  required DeckPlanSlideType slide,
}) {
  final slides = [
    for (final existing in plan.slides) Map<String, Object?>.from(existing),
  ];
  slides[index] = Map<String, Object?>.from(slide);
  final data = Map<String, Object?>.from(plan)..['slides'] = slides;
  return DeckPlanType.parse(data);
}
