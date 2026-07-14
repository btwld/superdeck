part of 'deck_generator_service.dart';

extension _DeckGeneratorPipeline on DeckGeneratorService {
  // ===========================================================================
  // PHASE 1: Generate Outline
  // ===========================================================================

  /// Generates a lightweight presentation outline.
  ///
  /// Returns the outline JSON or null on failure.
  Future<DeckPlanType?> _generateOutline(
    GenerationModelCallExecutor executor,
    String prompt,
    GenerationTraceEmitter trace,
    DeckGenerationRequest request,
    List<PresentationThemeDescriptor> themeCandidates,
  ) async {
    final draftSchema = buildDeckPlanDraftSchema(
      themeCandidates.map((candidate) => candidate.id).toList(growable: false),
    );
    final adapter = GoogleSchemaAdapter();
    final adaptResult = adapter.adapt(draftSchema.toJsonSchemaBuilder());

    if (adaptResult.schema == null) {
      debugLog.error(
        'DECK_GEN',
        'Failed to adapt outline schema: ${adaptResult.errors}',
      );
      return null;
    }

    var validationIssues = <GenerationValidationIssue>[];
    final repairConstraints = <GenerationValidationIssue>[];
    Map<String, dynamic>? invalidPlan;
    for (
      var repairAttempt = 1;
      repairAttempt <= maxOutlineValidationAttempts;
      repairAttempt++
    ) {
      final systemPrompt = _promptProvider.buildOutlinePrompt(
        themeCandidates: themeCandidates,
        validationIssues: repairConstraints,
        invalidPlan: invalidPlan,
      );
      debugLog.log(
        'DECK_GEN',
        'Outline system prompt (${systemPrompt.length} chars)',
      );
      final modelRequest = google_ai.GenerateContentRequest(
        model: outlineModelName,
        contents: [
          google_ai.Content(
            role: 'user',
            parts: [google_ai.Part(text: prompt)],
          ),
        ],
        generationConfig: google_ai.GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: adaptResult.schema,
        ),
        systemInstruction: google_ai.Content(
          parts: [google_ai.Part(text: systemPrompt)],
        ),
      );

      debugLog.log(
        'DECK_GEN',
        repairAttempt == 1
            ? 'Sending outline request to $outlineModelName...'
            : 'Repairing outline with $outlineModelName...',
      );
      final response = await executor.execute(
        request: modelRequest,
        phase: GenerationTracePhase.outline,
        model: outlineModelName,
        prompt: systemPrompt,
        semanticAttempt: repairAttempt,
        isRepair: repairAttempt > 1,
        timeoutMessage: 'Outline generation timed out',
      );
      debugLog.log(
        'DECK_GEN',
        'Outline response: ${response.candidates.length} candidates',
      );
      final json = _parseJsonResponse(response, 'outline');
      if (json == null) {
        validationIssues = const [
          GenerationValidationIssue(
            code: GenerationValidationCode.invalidResponse,
            category: GenerationValidationCategory.schema,
            severity: GenerationValidationSeverity.blocking,
            location: GenerationValidationLocation.deck,
            message: 'Model response was not a JSON deck-plan object.',
          ),
        ];
        invalidPlan = null;
      } else {
        invalidPlan = json;
        try {
          final plan = resolveDeckPlanDraft(
            draft: json,
            candidates: themeCandidates,
            request: request,
            themeCatalog: themeCatalog,
            typographyCatalog: typographyCatalog,
          );
          invalidPlan = Map<String, dynamic>.from(
            serializeDeckPlanDraftForRepair(plan),
          );
          validationIssues = validateDeckPlanIssues(
            plan,
            typographyCatalog: typographyCatalog,
            themeCatalog: themeCatalog,
            request: request,
          );
          if (_onlySlideScopedPlanIssues(validationIssues)) {
            final repairedPlan = await _repairInvalidOutlineSlides(
              executor: executor,
              originalPrompt: prompt,
              plan: plan,
              request: request,
            );
            validationIssues = validateDeckPlanIssues(
              repairedPlan,
              typographyCatalog: typographyCatalog,
              themeCatalog: themeCatalog,
              request: request,
            );
            invalidPlan = Map<String, dynamic>.from(
              serializeDeckPlanDraftForRepair(repairedPlan),
            );
            if (validationIssues.blockingIssues.isEmpty) {
              trace.emit(
                kind: GenerationTraceKind.validation,
                phase: GenerationTracePhase.outline,
                attempt: repairAttempt,
              );
              return repairedPlan;
            }
          }
          if (validationIssues.blockingIssues.isEmpty) {
            trace.emit(
              kind: GenerationTraceKind.validation,
              phase: GenerationTracePhase.outline,
              attempt: repairAttempt,
            );
            return plan;
          }
        } catch (error) {
          validationIssues = [
            GenerationValidationIssue(
              code: GenerationValidationCode.invalidSchema,
              category: GenerationValidationCategory.schema,
              severity: GenerationValidationSeverity.blocking,
              location: GenerationValidationLocation.deck,
              message: 'Deck plan schema was invalid: $error',
            ),
          ];
        }
      }
      debugLog.error(
        'DECK_GEN',
        'Invalid deck plan: ${validationIssues.messages.join(' ')}',
      );
      _appendUniqueIssues(repairConstraints, validationIssues.blockingIssues);
      trace.emit(
        kind: GenerationTraceKind.validation,
        phase: GenerationTracePhase.outline,
        attempt: repairAttempt,
        validationErrors: validationIssues.messages,
        validationIssues: validationIssues,
      );
    }
    return null;
  }

  // ===========================================================================
  // PHASE 2: Compose Slides Sequentially
  // ===========================================================================

  Future<Map<String, dynamic>?> _composeSlides(
    GenerationModelCallExecutor executor,
    String prompt,
    DeckPlanType plan,
    DeckGenerationRequest request,
    GenerationTraceEmitter trace,
    GenerationProgressCallback? onProgress,
    bool Function()? isCancelled,
  ) async {
    final slides = <Map<String, dynamic>>[];
    trace.emit(
      kind: GenerationTraceKind.phaseStarted,
      phase: GenerationTracePhase.slide,
      slideCount: plan.slides.length,
    );

    for (var index = 0; index < plan.slides.length; index++) {
      if (isCancelled?.call() ?? false) return null;
      final current = plan.slides[index];
      final next = index + 1 < plan.slides.length
          ? plan.slides[index + 1]
          : null;
      Map<String, dynamic>? composed;
      var validationIssues = <GenerationValidationIssue>[];
      final repairConstraints = <GenerationValidationIssue>[];

      for (
        var repairAttempt = 1;
        repairAttempt <= maxSlideValidationAttempts;
        repairAttempt++
      ) {
        onProgress?.call(
          GenerationProgress(
            GenerationPhase.composingSlides,
            slideIndex: index + 1,
            slideCount: plan.slides.length,
            isRepairing: repairAttempt > 1,
          ),
        );
        composed = await _generateSingleSlide(
          executor: executor,
          originalPrompt: prompt,
          plan: plan,
          current: current,
          previousSlide: slides.lastOrNull,
          next: next,
          validationIssues: repairConstraints,
          invalidSlide: composed,
          repairAttempt: repairAttempt,
          slideIndex: index + 1,
          slideCount: plan.slides.length,
        );
        if (composed == null) {
          validationIssues = const [
            GenerationValidationIssue(
              code: GenerationValidationCode.invalidResponse,
              category: GenerationValidationCategory.schema,
              severity: GenerationValidationSeverity.blocking,
              location: GenerationValidationLocation.visibleContent,
              message: 'Model response was not a JSON slide object.',
            ),
          ];
        } else {
          composed = hydrateGeneratedElementSources(
            slide: composed,
            planSlide: current,
            elementCatalog: elementCatalog,
          );
          composed = normalizeGeneratedSlideForPlan(
            rawSlide: composed,
            planSlide: current,
          );
          validationIssues = validateGeneratedSlideIssues(
            expectedKey: current.key,
            rawSlide: composed,
            planSlide: current,
            elementCatalog: elementCatalog,
            request: request,
          );
          final commentSafeSlide = removeInvalidOptionalSpeakerComments(
            rawSlide: composed,
            validationIssues: validationIssues,
          );
          if (!identical(commentSafeSlide, composed)) {
            composed = commentSafeSlide;
            validationIssues = validateGeneratedSlideIssues(
              expectedKey: current.key,
              rawSlide: composed,
              planSlide: current,
              elementCatalog: elementCatalog,
              request: request,
            );
          }
        }
        trace.emit(
          kind: GenerationTraceKind.validation,
          phase: GenerationTracePhase.slide,
          attempt: repairAttempt,
          slideIndex: index + 1,
          slideCount: plan.slides.length,
          validationErrors: validationIssues.messages,
          validationIssues: validationIssues,
        );
        if (validationIssues.blockingIssues.isEmpty) break;
        _appendUniqueIssues(repairConstraints, validationIssues.blockingIssues);
      }

      if (composed == null || validationIssues.blockingIssues.isNotEmpty) {
        debugLog.error(
          'DECK_GEN',
          'Slide ${index + 1} failed validation: '
              '${validationIssues.messages.join(' ')}',
        );
        return null;
      }
      final canonicalSlide = sanitizeGeneratedSlides([composed]).singleOrNull;
      if (canonicalSlide == null) {
        debugLog.error(
          'DECK_GEN',
          'Slide ${index + 1} could not be normalized after validation.',
        );
        return null;
      }
      slides.add(canonicalSlide);
    }

    trace.emit(
      kind: GenerationTraceKind.phaseDone,
      phase: GenerationTracePhase.slide,
      slideCount: plan.slides.length,
    );
    return {'slides': slides};
  }

  Future<Map<String, dynamic>?> _generateSingleSlide({
    required GenerationModelCallExecutor executor,
    required String originalPrompt,
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required Map<String, Object?>? previousSlide,
    // The final slide intentionally has no next-slide context.
    // ignore: avoid-unnecessary-nullable-parameters
    required DeckPlanSlideType? next,
    required List<GenerationValidationIssue> validationIssues,
    required Map<String, Object?>? invalidSlide,
    required int repairAttempt,
    required int slideIndex,
    required int slideCount,
  }) async {
    // Live Gemini probes confirm that array bounds are supported on the
    // smaller outline schema but push this complete nested slide schema past
    // the provider's structured-output complexity limit. Dart validation
    // enforces the same section/block cardinality after every response.
    final adapter = GoogleSchemaAdapter(forwardArrayBounds: false);
    final adaptResult = adapter.adapt(
      buildAiSlideSchema(
        widgetArgumentProperties: elementCatalog.argumentProperties,
        nestWidgetArguments: true,
        requirePresentationOptions: true,
      ).toJsonSchemaBuilder(),
    );

    if (adaptResult.schema == null) {
      debugLog.error(
        'DECK_GEN',
        'Failed to adapt slide schema: ${adaptResult.errors}',
      );
      return null;
    }

    final systemPrompt = _promptProvider.buildSlidePrompt(
      plan: plan,
      current: current,
      previousSlide: previousSlide,
      next: next,
      elementCatalog: elementCatalog,
      validationIssues: validationIssues,
      invalidSlide: invalidSlide,
    );
    debugLog.log(
      'DECK_GEN',
      'Slide $slideIndex/$slideCount prompt (${systemPrompt.length} chars)',
    );
    debugLog.log('DECK_GEN', 'Thinking budget disabled for fast composition');

    final request = google_ai.GenerateContentRequest(
      model: modelName,
      contents: [
        google_ai.Content(
          role: 'user',
          parts: [google_ai.Part(text: originalPrompt)],
        ),
      ],
      generationConfig: google_ai.GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: adaptResult.schema,
      ),
      systemInstruction: google_ai.Content(
        parts: [google_ai.Part(text: systemPrompt)],
      ),
    );

    debugLog.log('DECK_GEN', 'Composing slide $slideIndex/$slideCount...');
    final response = await executor.execute(
      request: request,
      phase: GenerationTracePhase.slide,
      model: modelName,
      prompt: systemPrompt,
      semanticAttempt: repairAttempt,
      isRepair: repairAttempt > 1,
      timeoutMessage: 'Slide generation timed out',
      slideIndex: slideIndex,
      slideCount: slideCount,
    );
    debugLog.log(
      'DECK_GEN',
      'Slide response: ${response.candidates.length} candidates',
    );
    return _parseJsonResponse(response, 'slide $slideIndex');
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Parses JSON from a Gemini response.
  Map<String, dynamic>? _parseJsonResponse(
    google_ai.GenerateContentResponse response,
    String context,
  ) {
    if (response.candidates.isEmpty) {
      debugLog.error('DECK_GEN', 'No candidates in $context response');
      return null;
    }

    final jsonText = generationResponseText(response);
    if (jsonText == null || jsonText.isEmpty) {
      debugLog.error('DECK_GEN', 'No text content in $context response');
      return null;
    }

    try {
      return jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (e) {
      debugLog.error('DECK_GEN', 'JSON parse failed for $context: $e');
      return null;
    }
  }
}
