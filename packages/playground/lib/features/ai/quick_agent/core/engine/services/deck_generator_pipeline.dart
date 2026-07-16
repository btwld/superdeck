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
    final capabilities = _outlineDraftCapabilities(request);
    final draftSchema = buildDeckPlanDraftSchema(
      themeCandidates.map((candidate) => candidate.id).toList(growable: false),
      allowedCompositionIntents: capabilities.compositions,
      allowedElementTypes: capabilities.elementTypes,
      allowElementSources: capabilities.allowElementSources,
      requireImageGenerationPrompt: capabilities.requireImageGenerationPrompt,
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
      final selectedModel = repairAttempt == 1
          ? outlineModelName
          : outlineRepairModelName;
      final modelRequest = google_ai.GenerateContentRequest(
        model: selectedModel,
        systemInstruction: google_ai.Content(
          parts: [google_ai.Part(text: systemPrompt)],
        ),
        contents: [
          google_ai.Content(
            role: 'user',
            parts: [google_ai.Part(text: prompt)],
          ),
        ],
        generationConfig: google_ai.GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: adaptResult.schema,
          thinkingConfig: google_ai.ThinkingConfig(thinkingBudget: 0),
        ),
      );

      debugLog.log(
        'DECK_GEN',
        repairAttempt == 1
            ? 'Sending outline request to $selectedModel...'
            : 'Repairing outline with $selectedModel...',
      );
      final response = await executor.execute(
        request: modelRequest,
        phase: GenerationTracePhase.outline,
        model: selectedModel,
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
            imageStyleCatalog: imageStyleCatalog,
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
              imageStyleCatalog: imageStyleCatalog,
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
        } on GenerationBudgetExceededException {
          rethrow;
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
  // PHASE 2: Compose Slides
  // ===========================================================================

  Future<_SlideCompositionResult?> _composeSlides(
    GenerationModelCallExecutor executor,
    String prompt,
    DeckPlanType plan,
    DeckGenerationRequest request,
    GenerationTraceEmitter trace,
    GenerationProgressCallback? onProgress,
    bool Function()? isCancelled,
  ) {
    if (plan.slides.length >= sectionBatchThreshold) {
      return _composeSlidesBySection(
        executor,
        prompt,
        plan,
        request,
        trace,
        onProgress,
        isCancelled,
      );
    }

    return _composeSlidesSequentially(
      executor,
      prompt,
      plan,
      request,
      trace,
      onProgress,
      isCancelled,
    );
  }

  /// Composes all narrative sections concurrently and accepts valid slides
  /// independently. This is the latency-first production path for normal decks.
  Future<_SlideCompositionResult?> _composeSlidesBySection(
    GenerationModelCallExecutor executor,
    String prompt,
    DeckPlanType plan,
    DeckGenerationRequest request,
    GenerationTraceEmitter trace,
    GenerationProgressCallback? onProgress,
    bool Function()? isCancelled,
  ) async {
    if (isCancelled?.call() ?? false) return null;
    trace.emit(
      kind: GenerationTraceKind.phaseStarted,
      phase: GenerationTracePhase.slide,
      slideCount: plan.slides.length,
    );

    var completedSections = 0;
    final sectionResults = await Future.wait([
      for (final (sectionIndex, section) in plan.sections.indexed)
        () async {
          final result = await _composeSection(
            executor: executor,
            originalPrompt: prompt,
            plan: plan,
            section: section,
            sectionIndex: sectionIndex,
            request: request,
            trace: trace,
          );
          completedSections++;
          onProgress?.call(
            GenerationProgress(
              GenerationPhase.composingSlides,
              sectionIndex: completedSections,
              sectionCount: plan.sections.length,
            ),
          );

          return result;
        }(),
    ]);
    if (isCancelled?.call() ?? false) return null;

    trace.emit(
      kind: GenerationTraceKind.phaseDone,
      phase: GenerationTracePhase.slide,
      slideCount: plan.slides.length,
    );

    return _SlideCompositionResult(
      slides: List.unmodifiable([
        for (final result in sectionResults) ...result.slides,
      ]),
      failures: List.unmodifiable([
        for (final result in sectionResults) ...result.failures,
      ]),
    );
  }

  Future<_SlideCompositionResult> _composeSection({
    required GenerationModelCallExecutor executor,
    required String originalPrompt,
    required DeckPlanType plan,
    required DeckPlanSectionType section,
    required int sectionIndex,
    required DeckGenerationRequest request,
    required GenerationTraceEmitter trace,
  }) async {
    final plannedSlides = [
      for (final slide in plan.slides)
        if (slide.sectionKey == section.key) slide,
    ];
    if (plannedSlides.isEmpty) {
      return const _SlideCompositionResult(slides: [], failures: []);
    }
    final firstIndex = plan.slides.indexWhere(
      (slide) => slide.key == plannedSlides.first.key,
    );
    final lastIndex = plan.slides.indexWhere(
      (slide) => slide.key == plannedSlides.last.key,
    );
    final previous = firstIndex > 0 ? plan.slides[firstIndex - 1] : null;
    final next = lastIndex + 1 < plan.slides.length
        ? plan.slides[lastIndex + 1]
        : null;

    final systemPrompt = _promptProvider.buildSectionPrompt(
      plan: plan,
      section: section,
      slides: plannedSlides,
      previous: previous,
      next: next,
      elementCatalog: elementCatalog,
    );
    debugLog.log(
      'DECK_GEN',
      'Section ${sectionIndex + 1}/${plan.sections.length} prompt '
          '(${systemPrompt.length} chars, ${plannedSlides.length} slides)',
    );

    final adapter = GoogleSchemaAdapter(forwardArrayBounds: false);
    final adaptResult = adapter.adapt(
      Ack.object({
        'slides': Ack.list(
          buildAiSlideSchema(
            widgetArgumentProperties: elementCatalog.argumentProperties,
            nestWidgetArguments: true,
            requirePresentationOptions: true,
          ),
        ),
      }).toJsonSchemaBuilder(),
    );
    if (adaptResult.schema == null) {
      return _failedSection(
        plan: plan,
        slides: plannedSlides,
        trace: trace,
        message: 'Section response schema could not be prepared.',
      );
    }

    final modelRequest = google_ai.GenerateContentRequest(
      model: modelName,
      systemInstruction: google_ai.Content(
        parts: [google_ai.Part(text: systemPrompt)],
      ),
      contents: [
        google_ai.Content(
          role: 'user',
          parts: [google_ai.Part(text: originalPrompt)],
        ),
      ],
      generationConfig: google_ai.GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: adaptResult.schema,
        thinkingConfig: google_ai.ThinkingConfig(thinkingBudget: 0),
      ),
    );

    final google_ai.GenerateContentResponse response;
    try {
      response = await executor.execute(
        request: modelRequest,
        phase: GenerationTracePhase.slide,
        model: modelName,
        prompt: systemPrompt,
        semanticAttempt: 1,
        isRepair: false,
        timeoutMessage: 'Section generation timed out',
        slideIndex: firstIndex + 1,
        slideCount: plan.slides.length,
      );
    } on GenerationCancelledException {
      rethrow;
    } on GenerationBudgetExceededException {
      rethrow;
    } catch (error, stack) {
      final category = const ErrorClassifier().classify(error);
      if (category != .network) rethrow;
      debugLog.error(
        'DECK_GEN',
        'Section ${section.key} transport failed; preserving other sections.',
        stack,
      );

      return _failedSection(
        plan: plan,
        slides: plannedSlides,
        trace: trace,
        message: '${category.userMessage} Retry this section.',
      );
    }

    final json = _parseJsonResponse(response, 'section ${section.key}');
    final rawSlides = json?['slides'];
    if (rawSlides is! List) {
      return _failedSection(
        plan: plan,
        slides: plannedSlides,
        trace: trace,
        message: 'Model response was not a JSON section with a slides array.',
      );
    }
    final draftsByKey = <String, Map<String, dynamic>>{};
    for (final rawSlide in rawSlides) {
      if (rawSlide is! Map) continue;
      final draft = Map<String, dynamic>.from(rawSlide);
      final key = draft['key'];
      if (key is String && !draftsByKey.containsKey(key)) {
        draftsByKey[key] = draft;
      }
    }

    final accepted = <Map<String, dynamic>>[];
    final failures = <SlideGenerationFailure>[];
    for (final plannedSlide in plannedSlides) {
      final slideIndex = plan.slides.indexWhere(
        (slide) => slide.key == plannedSlide.key,
      );
      final draft = draftsByKey[plannedSlide.key];
      if (draft == null) {
        final issues = _invalidSectionSlideIssues(
          'Section response omitted slide "${plannedSlide.key}".',
        );
        failures.add(
          SlideGenerationFailure(
            slideIndex: slideIndex + 1,
            slideKey: plannedSlide.key,
            issues: issues,
          ),
        );
        _traceSectionSlideValidation(
          trace: trace,
          slideIndex: slideIndex,
          slideCount: plan.slides.length,
          issues: issues,
        );
        continue;
      }

      final validation = _validateSectionSlide(
        draft: draft,
        planSlide: plannedSlide,
        request: request,
      );
      _traceSectionSlideValidation(
        trace: trace,
        slideIndex: slideIndex,
        slideCount: plan.slides.length,
        issues: validation.issues,
      );
      if (validation.canonical == null) {
        failures.add(
          SlideGenerationFailure(
            slideIndex: slideIndex + 1,
            slideKey: plannedSlide.key,
            issues: validation.issues.blockingIssues,
          ),
        );
        continue;
      }
      accepted.add(validation.canonical!);
    }

    return _SlideCompositionResult(
      slides: List.unmodifiable(accepted),
      failures: List.unmodifiable(failures),
    );
  }

  _SlideCompositionResult _failedSection({
    required DeckPlanType plan,
    required List<DeckPlanSlideType> slides,
    required GenerationTraceEmitter trace,
    required String message,
  }) {
    final issues = _invalidSectionSlideIssues(message);
    for (final slide in slides) {
      _traceSectionSlideValidation(
        trace: trace,
        slideIndex: plan.slides.indexWhere(
          (candidate) => candidate.key == slide.key,
        ),
        slideCount: plan.slides.length,
        issues: issues,
      );
    }

    return _SlideCompositionResult(
      slides: const [],
      failures: List.unmodifiable([
        for (final slide in slides)
          SlideGenerationFailure(
            slideIndex:
                plan.slides.indexWhere(
                  (candidate) => candidate.key == slide.key,
                ) +
                1,
            slideKey: slide.key,
            issues: issues,
          ),
      ]),
    );
  }

  List<GenerationValidationIssue> _invalidSectionSlideIssues(String message) =>
      [
        GenerationValidationIssue(
          code: GenerationValidationCode.invalidResponse,
          category: GenerationValidationCategory.schema,
          severity: GenerationValidationSeverity.blocking,
          location: GenerationValidationLocation.visibleContent,
          message: message,
        ),
      ];

  ({Map<String, dynamic>? canonical, List<GenerationValidationIssue> issues})
  _validateSectionSlide({
    required Map<String, dynamic> draft,
    required DeckPlanSlideType planSlide,
    required DeckGenerationRequest request,
  }) {
    var normalized = hydrateGeneratedElementSources(
      slide: draft,
      planSlide: planSlide,
      elementCatalog: elementCatalog,
    );
    normalized = normalizeGeneratedSlideForPlan(
      rawSlide: normalized,
      planSlide: planSlide,
    );
    var issues = validateGeneratedSlideIssues(
      expectedKey: planSlide.key,
      rawSlide: normalized,
      elementCatalog: elementCatalog,
      planSlide: planSlide,
      request: request,
    );
    final commentSafeSlide = removeInvalidOptionalSpeakerComments(
      rawSlide: normalized,
      validationIssues: issues,
    );
    if (!identical(commentSafeSlide, normalized)) {
      normalized = commentSafeSlide;
      issues = validateGeneratedSlideIssues(
        expectedKey: planSlide.key,
        rawSlide: normalized,
        elementCatalog: elementCatalog,
        planSlide: planSlide,
        request: request,
      );
    }
    if (issues.blockingIssues.isNotEmpty) {
      return (canonical: null, issues: issues);
    }
    final canonical = sanitizeGeneratedSlides([normalized]).singleOrNull;
    if (canonical == null) {
      return (
        canonical: null,
        issues: const [
          GenerationValidationIssue(
            code: GenerationValidationCode.invalidSchema,
            category: GenerationValidationCategory.schema,
            severity: GenerationValidationSeverity.blocking,
            location: GenerationValidationLocation.visibleContent,
            message: 'Generated slide could not be normalized.',
          ),
        ],
      );
    }

    return (canonical: canonical, issues: issues);
  }

  void _traceSectionSlideValidation({
    required GenerationTraceEmitter trace,
    required int slideIndex,
    required int slideCount,
    required List<GenerationValidationIssue> issues,
  }) {
    trace.emit(
      kind: GenerationTraceKind.validation,
      phase: GenerationTracePhase.slide,
      attempt: 1,
      slideIndex: slideIndex + 1,
      slideCount: slideCount,
      validationErrors: issues.messages,
      validationIssues: issues,
    );
  }

  /// Retained for small, focused generation and repair diagnostics.
  Future<_SlideCompositionResult?> _composeSlidesSequentially(
    GenerationModelCallExecutor executor,
    String prompt,
    DeckPlanType plan,
    DeckGenerationRequest request,
    GenerationTraceEmitter trace,
    GenerationProgressCallback? onProgress,
    bool Function()? isCancelled, {
    // Passed by retryFailedSlides from another part of this library.
    // ignore: avoid-never-passed-parameters
    Set<String>? targetSlideKeys,
    // ignore: avoid-never-passed-parameters
    Map<String, Map<String, dynamic>> existingSlidesByKey = const {},
  }) async {
    final slides = <Map<String, dynamic>>[];
    final failures = <SlideGenerationFailure>[];
    final availableSlidesByKey = Map<String, Map<String, dynamic>>.of(
      existingSlidesByKey,
    );
    trace.emit(
      kind: GenerationTraceKind.phaseStarted,
      phase: GenerationTracePhase.slide,
      slideCount: plan.slides.length,
    );

    for (var index = 0; index < plan.slides.length; index++) {
      if (isCancelled?.call() ?? false) return null;
      final current = plan.slides[index];
      if (targetSlideKeys != null && !targetSlideKeys.contains(current.key)) {
        continue;
      }
      final next = index + 1 < plan.slides.length
          ? plan.slides[index + 1]
          : null;
      Map<String, dynamic>? previousSlide;
      for (var previousIndex = index - 1; previousIndex >= 0; previousIndex--) {
        previousSlide = availableSlidesByKey[plan.slides[previousIndex].key];
        if (previousSlide != null) break;
      }
      Map<String, dynamic>? composed;
      var validationIssues = <GenerationValidationIssue>[];
      final repairConstraints = <GenerationValidationIssue>[];

      for (
        var repairAttempt = 1;
        repairAttempt <= maxSlideValidationAttempts;
        repairAttempt++
      ) {
        if (repairAttempt > 1 && !executor.hasRepairCapacity) {
          debugLog.log(
            'DECK_GEN',
            'Slide ${index + 1} repair skipped: run repair budget exhausted.',
          );
          break;
        }
        onProgress?.call(
          GenerationProgress(
            GenerationPhase.composingSlides,
            slideIndex: index + 1,
            slideCount: plan.slides.length,
            isRepairing: repairAttempt > 1,
          ),
        );
        try {
          composed = await _generateSingleSlide(
            executor: executor,
            originalPrompt: prompt,
            plan: plan,
            current: current,
            previousSlide: previousSlide,
            next: next,
            validationIssues: repairConstraints,
            invalidSlide: composed,
            repairAttempt: repairAttempt,
            slideIndex: index + 1,
            slideCount: plan.slides.length,
          );
        } on GenerationCancelledException {
          rethrow;
        } on GenerationBudgetExceededException {
          rethrow;
        } catch (error, stack) {
          final category = const ErrorClassifier().classify(error);
          if (category != .network) rethrow;
          validationIssues = [
            GenerationValidationIssue(
              code: GenerationValidationCode.invalidResponse,
              category: GenerationValidationCategory.schema,
              severity: GenerationValidationSeverity.blocking,
              location: GenerationValidationLocation.visibleContent,
              message: '${category.userMessage} Retry this slide.',
            ),
          ];
          debugLog.error(
            'DECK_GEN',
            'Slide ${index + 1} transport failed; continuing with the deck.',
            stack,
          );
          trace.emit(
            kind: GenerationTraceKind.validation,
            phase: GenerationTracePhase.slide,
            attempt: repairAttempt,
            slideIndex: index + 1,
            slideCount: plan.slides.length,
            validationErrors: validationIssues.messages,
            validationIssues: validationIssues,
          );
          break;
        }
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
        failures.add(
          SlideGenerationFailure(
            slideIndex: index + 1,
            slideKey: current.key,
            issues: List.unmodifiable(validationIssues.blockingIssues),
          ),
        );
        continue;
      }
      final canonicalSlide = sanitizeGeneratedSlides([composed]).singleOrNull;
      if (canonicalSlide == null) {
        debugLog.error(
          'DECK_GEN',
          'Slide ${index + 1} could not be normalized after validation.',
        );
        failures.add(
          SlideGenerationFailure(
            slideIndex: index + 1,
            slideKey: current.key,
            issues: const [
              GenerationValidationIssue(
                code: GenerationValidationCode.invalidSchema,
                category: GenerationValidationCategory.schema,
                severity: GenerationValidationSeverity.blocking,
                location: GenerationValidationLocation.visibleContent,
                message: 'Generated slide could not be normalized.',
              ),
            ],
          ),
        );
        continue;
      }
      slides.add(canonicalSlide);
      availableSlidesByKey[current.key] = canonicalSlide;
    }

    trace.emit(
      kind: GenerationTraceKind.phaseDone,
      phase: GenerationTracePhase.slide,
      slideCount: plan.slides.length,
    );

    return _SlideCompositionResult(
      slides: List.unmodifiable(slides),
      failures: List.unmodifiable(failures),
    );
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
      systemInstruction: google_ai.Content(
        parts: [google_ai.Part(text: systemPrompt)],
      ),
      contents: [
        google_ai.Content(
          role: 'user',
          parts: [google_ai.Part(text: originalPrompt)],
        ),
      ],
      generationConfig: google_ai.GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: adaptResult.schema,
        thinkingConfig: google_ai.ThinkingConfig(thinkingBudget: 0),
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

({
  List<String> compositions,
  List<String> elementTypes,
  bool allowElementSources,
  bool requireImageGenerationPrompt,
})
_outlineDraftCapabilities(DeckGenerationRequest request) {
  final groundedTypes = {
    for (final element in request.groundedElements) element.type,
  }..retainAll(deckPlanElementTypes);
  final hasGeneratedImages =
      request.imageStyleId != null && request.maxGeneratedImages > 0;
  final elementTypes = {...groundedTypes, if (hasGeneratedImages) 'image'};
  final compositions = {
    'title',
    'content',
    'twoColumn',
    'threeColumn',
    'table',
    'quote',
    'titleLeft',
    'metric',
    if (elementTypes.contains('image')) ...{
      'imageLeft',
      'imageRight',
      'imageFullBleed',
    },
    if (elementTypes.contains('webview')) 'webview',
    if (elementTypes.contains('dartpad')) 'dartpad',
    if (elementTypes.contains('custom')) 'custom',
  };
  final hasGroundedImage = request.groundedElements.any(
    (element) => element.type == 'image',
  );

  return (
    compositions: List.unmodifiable(compositions),
    elementTypes: List.unmodifiable(elementTypes),
    allowElementSources: request.groundedElements.isNotEmpty,
    requireImageGenerationPrompt:
        hasGeneratedImages && elementTypes.length == 1 && !hasGroundedImage,
  );
}
