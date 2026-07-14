part of 'deck_generator_service.dart';

extension _DeckGeneratorPipeline on DeckGeneratorService {
  // ===========================================================================
  // PHASE 1: Generate Outline
  // ===========================================================================

  /// Generates a lightweight presentation outline.
  ///
  /// Returns the outline JSON or null on failure.
  Future<DeckPlanType?> _generateOutline(
    GenerationModelClient service,
    String prompt,
    GenerationTraceEmitter trace,
    DeckGenerationRequest request,
  ) async {
    final adapter = GoogleSchemaAdapter();
    final adaptResult = adapter.adapt(deckPlanSchema.toJsonSchemaBuilder());

    if (adaptResult.schema == null) {
      debugLog.error(
        'DECK_GEN',
        'Failed to adapt outline schema: ${adaptResult.errors}',
      );
      return null;
    }

    var validationErrors = <String>[];
    final repairConstraints = <String>[];
    Map<String, dynamic>? invalidPlan;
    for (
      var repairAttempt = 1;
      repairAttempt <= maxOutlineValidationAttempts;
      repairAttempt++
    ) {
      final systemPrompt = _promptProvider.buildOutlinePrompt(
        typographyCatalog: typographyCatalog,
        validationErrors: repairConstraints,
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
      final response = await retryPolicy.run(() {
        trace.emit(
          kind: GenerationTraceKind.request,
          phase: GenerationTracePhase.outline,
          model: outlineModelName,
          attempt: repairAttempt,
          prompt: systemPrompt,
        );
        return service
            .generateContent(modelRequest)
            .timeout(
              requestTimeout,
              onTimeout: () {
                throw TimeoutException('Outline generation timed out');
              },
            );
      });
      debugLog.log(
        'DECK_GEN',
        'Outline response: ${response.candidates.length} candidates',
      );
      trace.emit(
        kind: GenerationTraceKind.response,
        phase: GenerationTracePhase.outline,
        model: outlineModelName,
        attempt: repairAttempt,
        response: _responseText(response),
      );

      final json = _parseJsonResponse(response, 'outline');
      if (json == null) {
        validationErrors = const [
          'Model response was not a JSON deck-plan object.',
        ];
        invalidPlan = null;
      } else {
        invalidPlan = json;
        try {
          final plan = normalizeDeckPlanAccentContrast(
            DeckPlanType.parse(json),
          );
          invalidPlan = Map<String, dynamic>.from(plan);
          validationErrors = validateDeckPlan(
            plan,
            request: request,
            typographyCatalog: typographyCatalog,
          );
          if (_onlySlideScopedPlanErrors(validationErrors)) {
            final repairedPlan = await _repairInvalidOutlineSlides(
              service: service,
              originalPrompt: prompt,
              plan: plan,
              request: request,
              trace: trace,
              fullPlanAttempt: repairAttempt,
            );
            validationErrors = validateDeckPlan(
              repairedPlan,
              request: request,
              typographyCatalog: typographyCatalog,
            );
            invalidPlan = Map<String, dynamic>.from(repairedPlan);
            if (validationErrors.isEmpty) {
              trace.emit(
                kind: GenerationTraceKind.validation,
                phase: GenerationTracePhase.outline,
                attempt: repairAttempt,
              );
              return repairedPlan;
            }
          }
          if (validationErrors.isEmpty) {
            trace.emit(
              kind: GenerationTraceKind.validation,
              phase: GenerationTracePhase.outline,
              attempt: repairAttempt,
            );
            return plan;
          }
        } catch (error) {
          validationErrors = ['Deck plan schema was invalid: $error'];
        }
      }
      debugLog.error(
        'DECK_GEN',
        'Invalid deck plan: ${validationErrors.join(' ')}',
      );
      for (final error in validationErrors) {
        if (!repairConstraints.contains(error)) repairConstraints.add(error);
      }
      trace.emit(
        kind: GenerationTraceKind.validation,
        phase: GenerationTracePhase.outline,
        attempt: repairAttempt,
        validationErrors: validationErrors,
      );
    }
    return null;
  }

  // ===========================================================================
  // PHASE 2: Compose Slides Sequentially
  // ===========================================================================

  Future<Map<String, dynamic>?> _composeSlides(
    GenerationModelClient service,
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
      var validationErrors = <String>[];
      final repairConstraints = <String>[];

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
          service: service,
          originalPrompt: prompt,
          plan: plan,
          current: current,
          previousSlide: slides.lastOrNull,
          next: next,
          validationErrors: repairConstraints,
          invalidSlide: composed,
          repairAttempt: repairAttempt,
          slideIndex: index + 1,
          slideCount: plan.slides.length,
          trace: trace,
        );
        if (composed == null) {
          validationErrors = const [
            'Model response was not a JSON slide object.',
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
          validationErrors = validateGeneratedSlide(
            expectedKey: current.key,
            rawSlide: composed,
            planSlide: current,
            elementCatalog: elementCatalog,
            request: request,
          );
          final commentSafeSlide = removeInvalidOptionalSpeakerComments(
            rawSlide: composed,
            validationErrors: validationErrors,
          );
          if (!identical(commentSafeSlide, composed)) {
            composed = commentSafeSlide;
            validationErrors = validateGeneratedSlide(
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
          validationErrors: validationErrors,
        );
        if (validationErrors.isEmpty) break;
        for (final error in validationErrors) {
          if (!repairConstraints.contains(error)) repairConstraints.add(error);
        }
      }

      if (composed == null || validationErrors.isNotEmpty) {
        debugLog.error(
          'DECK_GEN',
          'Slide ${index + 1} failed validation: ${validationErrors.join(' ')}',
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
    required GenerationModelClient service,
    required String originalPrompt,
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required Map<String, Object?>? previousSlide,
    required DeckPlanSlideType? next,
    required List<String> validationErrors,
    required Map<String, Object?>? invalidSlide,
    required int repairAttempt,
    required int slideIndex,
    required int slideCount,
    required GenerationTraceEmitter trace,
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
      validationErrors: validationErrors,
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
    final response = await retryPolicy.run(() {
      trace.emit(
        kind: GenerationTraceKind.request,
        phase: GenerationTracePhase.slide,
        model: modelName,
        attempt: repairAttempt,
        slideIndex: slideIndex,
        slideCount: slideCount,
        prompt: systemPrompt,
      );
      return service
          .generateContent(request)
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw TimeoutException('Slide generation timed out');
            },
          );
    });
    debugLog.log(
      'DECK_GEN',
      'Slide response: ${response.candidates.length} candidates',
    );
    trace.emit(
      kind: GenerationTraceKind.response,
      phase: GenerationTracePhase.slide,
      model: modelName,
      attempt: repairAttempt,
      slideIndex: slideIndex,
      slideCount: slideCount,
      response: _responseText(response),
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

    final jsonText = _responseText(response);
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

  String? _responseText(google_ai.GenerateContentResponse response) {
    if (response.candidates.isEmpty) return null;
    final textParts = response.candidates.first.content?.parts
        .where((part) => part.text != null)
        .map((part) => part.text!)
        .toList();
    if (textParts == null || textParts.isEmpty) return null;
    return textParts.join();
  }
}
