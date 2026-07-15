part of 'deck_generator_service.dart';

const _maxTargetedOutlineSlidesPerPass = 2;

bool _onlySlideScopedPlanIssues(List<GenerationValidationIssue> issues) {
  final blocking = issues.blockingIssues;
  final affectedSlideKeys = {for (final issue in blocking) ?issue.slideKey};
  return blocking.isNotEmpty &&
      affectedSlideKeys.length <= _maxTargetedOutlineSlidesPerPass &&
      blocking.every(
        (issue) => issue.locallyRepairable && issue.slideKey != null,
      );
}

extension _DeckPlanRepair on DeckGeneratorService {
  Future<DeckPlanType> _repairInvalidOutlineSlides({
    required GenerationModelCallExecutor executor,
    required String originalPrompt,
    required DeckPlanType plan,
    required DeckGenerationRequest request,
  }) async {
    var repairedPlan = plan;
    final errorsByKey = _groupSlidePlanIssues(
      validateDeckPlanIssues(
        repairedPlan,
        typographyCatalog: typographyCatalog,
        themeCatalog: themeCatalog,
        request: request,
      ),
    );

    for (final entry in errorsByKey.entries) {
      final index = repairedPlan.slides.indexWhere(
        (candidate) => candidate.key == entry.key,
      );
      if (index < 0) continue;
      final original = repairedPlan.slides[index];
      var repairBase = Map<String, Object?>.of(original);
      var constraints = List<GenerationValidationIssue>.of(entry.value);

      for (
        var localAttempt = 1;
        localAttempt <= maxOutlineSlideValidationAttempts;
        localAttempt++
      ) {
        if (!executor.hasRepairCapacity) {
          debugLog.log(
            'DECK_GEN',
            'Outline slide repair skipped: run repair budget exhausted.',
          );
          break;
        }
        final candidate = await _generateOutlineSlideRepair(
          executor: executor,
          originalPrompt: originalPrompt,
          plan: repairedPlan,
          current: original,
          validationIssues: constraints,
          invalidSlide: repairBase,
          localAttempt: localAttempt,
          slideIndex: index,
        );
        if (candidate == null) continue;
        repairBase = Map<String, Object?>.of(candidate);

        final invariantErrors = _outlineSlideInvariantErrors(
          original: original,
          candidate: candidate,
        );
        if (invariantErrors.isNotEmpty) {
          _appendUniqueIssues(constraints, [
            for (final message in invariantErrors)
              GenerationValidationIssue(
                code: GenerationValidationCode.planStructure,
                category: GenerationValidationCategory.structure,
                severity: GenerationValidationSeverity.blocking,
                location: GenerationValidationLocation.planSlide,
                slideKey: entry.key,
                locallyRepairable: true,
                message: message,
              ),
          ]);
          continue;
        }

        final candidatePlan = _replacePlanSlide(
          repairedPlan,
          index: index,
          slide: candidate,
        );
        final candidateIssues = validateDeckPlanIssues(
          candidatePlan,
          typographyCatalog: typographyCatalog,
          themeCatalog: themeCatalog,
          request: request,
        );
        final localIssues = candidateIssues
            .where((issue) => issue.isBlocking && issue.slideKey == entry.key)
            .toList();
        if (localIssues.isEmpty) {
          repairedPlan = candidatePlan;
          break;
        }
        _appendUniqueIssues(constraints, localIssues);
      }
    }
    return repairedPlan;
  }

  Future<DeckPlanSlideType?> _generateOutlineSlideRepair({
    required GenerationModelCallExecutor executor,
    required String originalPrompt,
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required List<GenerationValidationIssue> validationIssues,
    required Map<String, Object?> invalidSlide,
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
      validationIssues: validationIssues,
      invalidSlide: invalidSlide,
    );
    final modelRequest = google_ai.GenerateContentRequest(
      model: outlineRepairModelName,
      contents: [
        google_ai.Content(
          role: 'user',
          parts: [google_ai.Part(text: originalPrompt)],
        ),
      ],
      generationConfig: google_ai.GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: adapted.schema,
        thinkingConfig: google_ai.ThinkingConfig(thinkingBudget: 0),
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
    final response = await executor.execute(
      request: modelRequest,
      phase: GenerationTracePhase.outline,
      model: outlineRepairModelName,
      prompt: systemPrompt,
      semanticAttempt: localAttempt,
      isRepair: true,
      timeoutMessage: 'Outline slide repair timed out',
      slideIndex: slideIndex + 1,
      slideCount: plan.slides.length,
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

Map<String, List<GenerationValidationIssue>> _groupSlidePlanIssues(
  List<GenerationValidationIssue> issues,
) {
  final grouped = <String, List<GenerationValidationIssue>>{};
  for (final issue in issues.blockingIssues) {
    final key = issue.slideKey;
    if (key != null && issue.locallyRepairable) {
      grouped.putIfAbsent(key, () => []).add(issue);
    }
  }
  return grouped;
}

void _appendUniqueIssues(
  List<GenerationValidationIssue> target,
  Iterable<GenerationValidationIssue> additions,
) {
  for (final addition in additions) {
    final exists = target.any(
      (issue) =>
          issue.code == addition.code &&
          issue.location == addition.location &&
          issue.slideKey == addition.slideKey &&
          issue.message == addition.message,
    );
    if (!exists) target.add(addition);
  }
}

List<String> _outlineSlideInvariantErrors({
  required DeckPlanSlideType original,
  required DeckPlanSlideType candidate,
}) {
  final errors = <String>[];
  void requireSame(String field, Object before, Object after) {
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
  requireSame(
    'elements',
    original.elements ?? const <DeckPlanElementType>[],
    candidate.elements ?? const <DeckPlanElementType>[],
  );
  return errors;
}

DeckPlanType _replacePlanSlide(
  DeckPlanType plan, {
  required int index,
  required DeckPlanSlideType slide,
}) {
  final slides = [
    for (final existing in plan.slides) Map<String, Object?>.of(existing),
  ];
  slides[index] = Map<String, Object?>.of(slide);
  final data = Map<String, Object?>.of(plan)..['slides'] = slides;
  return DeckPlanType.parse(data);
}
