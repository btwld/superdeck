import 'dart:async';
import 'dart:convert';

import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:superdeck_core/superdeck_core.dart';
import '../../../../../../core/domain/design/presentation_typography_catalog.dart';
import '../prompts/generation_prompt_provider.dart';
import '../schemas/deck_schemas.dart';
import '../schemas/outline_schema.dart';
import 'deck_generation_request.dart';
import 'deck_generator_pipeline_helpers.dart';
import 'deck_plan_normalizer.dart';
import 'deck_plan_validator.dart';
import 'error_classifier.dart';
import 'generation_model_client.dart';
import 'generation_element_catalog.dart';
import 'generation_model_call_executor.dart';
import 'generation_progress.dart';
import 'generation_trace.dart';
import 'generation_validation_issue.dart';
import 'generated_slide_validator.dart';
import 'google_schema_adapter.dart';
import 'retry_policy.dart';
import '../../constants/gemini_models.dart';
import '../../debug_logger.dart';

part 'deck_generator_pipeline.dart';
part 'deck_plan_repair.dart';
part 'deck_generator_workflow.dart';

/// Result of deck generation.
class DeckGenerationResult {
  const DeckGenerationResult._({
    required this.success,
    this.message,
    this.error,
    List<Slide>? slides,
    this.style,
    this.plan,
  }) : slides = slides ?? const [];

  DeckGenerationResult.success({
    required List<Slide> slides,
    required DeckPlanType plan,
  }) : this._(
         success: true,
         message:
             'Successfully generated presentation with ${slides.length} slides.',
         slides: slides,
         style: plan.style,
         plan: plan,
       );

  DeckGenerationResult.failure(String error)
    : this._(success: false, error: error);

  final bool success;
  final String? message;
  final String? error;

  /// Generated slides (in-memory, not written to disk).
  final List<Slide> slides;

  /// Style configuration extracted from the generated deck.
  final DeckStyleType? style;

  /// The validated, mechanically normalized plan used to compose the deck.
  final DeckPlanType? plan;

  /// Number of slides in the result.
  int get slideCount => slides.length;
}

/// Service that generates SuperDeck presentations using Google Generative AI.
///
/// Uses a plan-first pipeline, then composes and validates one slide at a time.
class DeckGeneratorService {
  DeckGeneratorService({
    required this.apiKey,
    this.modelName = GeminiModelNames.gemini3FlashPreview,
    this.outlineModelName = GeminiModelNames.gemini3FlashPreview,
    this.requestTimeout = const Duration(seconds: 45),
    this.maxOutlineValidationAttempts = 6,
    this.maxOutlineSlideValidationAttempts = 3,
    this.maxSlideValidationAttempts = 4,
    this.maxModelRequests = 96,
    this.maxRepairRequests = 72,
    this.runTimeout = const Duration(minutes: 15),
    RetryPolicy? retryPolicy,
    GenerationModelClientFactory? modelClientFactory,
    GenerationPromptProvider? promptProvider,
    GenerationElementCatalog? elementCatalog,
    PresentationTypographyCatalog? typographyCatalog,
  }) : assert(maxOutlineValidationAttempts > 0),
       assert(maxOutlineSlideValidationAttempts > 0),
       assert(maxSlideValidationAttempts > 0),
       assert(maxModelRequests > 0),
       assert(maxRepairRequests > 0),
       assert(runTimeout > Duration.zero),
       retryPolicy = retryPolicy ?? RetryPolicy(maxAttempts: 2),
       elementCatalog = elementCatalog ?? GenerationElementCatalog.builtIn(),
       typographyCatalog =
           typographyCatalog ?? PresentationTypographyCatalog.withDefaults(),
       _modelClientFactory =
           modelClientFactory ?? GoogleGenerationModelClient.fromApiKey,
       _promptProvider = promptProvider ?? AssetGenerationPromptProvider();

  final GenerationElementCatalog elementCatalog;

  final PresentationTypographyCatalog typographyCatalog;

  final String apiKey;

  /// Model used to compose and repair each slide.
  ///
  /// Defaults to the existing `gemini-3-flash-preview` configuration for fast
  /// sequential composition. Callers can inject another configured model for
  /// quality and latency comparisons.
  final String modelName;

  /// Model used for the outline generation (Phase 1).
  final String outlineModelName;

  /// Deadline for each outline or slide model call.
  final Duration requestTimeout;

  /// Bounded initial planning request plus targeted semantic repairs.
  ///
  /// Large plans have more cross-field constraints, so bounded follow-up repairs
  /// can recover when one repair fixes an invariant but disturbs another. The
  /// sixth and final attempt is only reached after five invalid responses; a
  /// valid first draft still completes in one request.
  final int maxOutlineValidationAttempts;

  /// Bounded local repairs for one slide inside an otherwise valid deck plan.
  ///
  /// Repairing a small slide object prevents a semantic correction from
  /// rewriting or regressing the rest of a 10–20-slide blueprint.
  final int maxOutlineSlideValidationAttempts;

  /// Bounded initial composition plus targeted semantic repairs per slide.
  ///
  /// Valid slides still use one request. A fourth and final targeted attempt
  /// prevents one stubborn semantic miss from forcing a full 10–20-slide deck
  /// restart after the outline and preceding slides already passed.
  final int maxSlideValidationAttempts;

  /// Maximum provider calls across the whole run, including transport retries.
  final int maxModelRequests;

  /// Maximum semantic repair calls across outline and slide generation.
  final int maxRepairRequests;

  /// Wall-clock limit shared by every phase and model request in one run.
  final Duration runTimeout;

  /// Retry policy for transient generation failures.
  final RetryPolicy retryPolicy;

  final GenerationModelClientFactory _modelClientFactory;

  final GenerationPromptProvider _promptProvider;

  /// Generates a presentation deck from typed user intent.
  ///
  /// Contractual fields such as slide count and typography remain typed so they
  /// can be validated independently from the user's prose.
  ///
  /// Uses a two-phase pipeline:
  /// 1. Plan the shared narrative and visual system.
  /// 2. Compose and validate one slide at a time from that plan.
  ///
  /// Progress updates are reported via [onProgress] if provided.
  Future<DeckGenerationResult> generate(
    DeckGenerationRequest request, {
    GenerationProgressCallback? onProgress,
    GenerationTraceCallback? onTrace,
    bool Function()? isCancelled,
  }) async {
    if (request.userIntent.trim().isEmpty) {
      return DeckGenerationResult.failure(
        'Describe the presentation to create.',
      );
    }
    if (request.slideCount < 1 || request.slideCount > 50) {
      return DeckGenerationResult.failure(
        'Slide count must be between 1 and 50.',
      );
    }

    final modelInput = request.toModelInput();
    _logPipelineConfig(this, prompt: modelInput);
    final pipelineStart = DateTime.now();
    final service = _modelClientFactory(apiKey);
    final trace = GenerationTraceEmitter(onTrace);
    bool generationCancelled() => isCancelled?.call() ?? false;
    DeckGenerationResult cancelledResult() =>
        DeckGenerationResult.failure('Generation cancelled.');
    final executor = GenerationModelCallExecutor(
      client: service,
      retryPolicy: retryPolicy,
      trace: trace,
      requestTimeout: requestTimeout,
      isCancelled: generationCancelled,
      maxModelRequests: maxModelRequests,
      maxRepairRequests: maxRepairRequests,
      runTimeout: runTimeout,
    );

    try {
      await _promptProvider.load();

      final outline = await _runOutlinePhase(
        this,
        executor: executor,
        prompt: modelInput,
        request: request,
        onProgress: onProgress,
        trace: trace,
      );
      if (generationCancelled()) {
        return cancelledResult();
      }
      if (outline == null) {
        return DeckGenerationResult.failure(
          'Failed to generate presentation outline. Please try again.',
        );
      }

      final deckJson = await _runSlideCompositionPhase(
        this,
        executor: executor,
        prompt: modelInput,
        request: request,
        outline: outline,
        onProgress: onProgress,
        trace: trace,
        isCancelled: isCancelled,
      );
      if (generationCancelled()) {
        return cancelledResult();
      }

      if (deckJson == null) {
        return DeckGenerationResult.failure(
          'Failed while composing presentation slides. Please try again.',
        );
      }

      return _finalizeDeck(
        deckJson: deckJson,
        plan: outline,
        pipelineStart: pipelineStart,
        onProgress: onProgress,
        isCancelled: isCancelled,
        trace: trace,
      );
    } on GenerationCancelledException {
      return cancelledResult();
    } on GenerationBudgetExceededException catch (error, stack) {
      final totalMs = DateTime.now().difference(pipelineStart).inMilliseconds;
      debugLog.error(
        'DECK_GEN',
        'Pipeline stopped after ${totalMs}ms: ${error.message}',
        stack,
      );
      return DeckGenerationResult.failure(error.message);
    } catch (e, stack) {
      final totalMs = DateTime.now().difference(pipelineStart).inMilliseconds;
      debugLog.error(
        'DECK_GEN',
        'Pipeline FAILED after ${totalMs}ms: $e',
        stack,
      );
      final userMessage = const ErrorClassifier().getUserMessage(e);
      return DeckGenerationResult.failure(userMessage);
    } finally {
      service.close();
    }
  }
}
