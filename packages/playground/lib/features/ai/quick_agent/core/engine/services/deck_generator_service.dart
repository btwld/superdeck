import 'dart:async';
import 'dart:convert';

import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:superdeck_core/superdeck_core.dart';
import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../../../core/domain/design/presentation_typography_catalog.dart';
import '../prompts/generation_prompt_provider.dart';
import '../schemas/outline_schema.dart';
import 'deck_generation_request.dart';
import 'deck_generator_pipeline_helpers.dart';
import 'deck_plan_validator.dart';
import 'deck_theme_resolution.dart';
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
import 'theme_json_serializer.dart';
import '../../constants/gemini_models.dart';
import '../../debug_logger.dart';

part 'deck_generator_pipeline.dart';
part 'deck_plan_repair.dart';
part 'deck_generator_workflow.dart';

/// One slide slot that could not be composed into a valid canonical slide.
final class SlideGenerationFailure {
  const SlideGenerationFailure({
    required this.slideIndex,
    required this.slideKey,
    required this.issues,
    this.retryable = true,
  });

  final int slideIndex;
  final String slideKey;
  final List<GenerationValidationIssue> issues;
  final bool retryable;

  String get message => issues.messages.join(' ');

  Map<String, Object?> toJson() => {
    'slideIndex': slideIndex,
    'slideKey': slideKey,
    'retryable': retryable,
    'issues': [for (final issue in issues) issue.toJson()],
  };
}

/// Result of deck generation.
class DeckGenerationResult {
  final bool success;
  final String? message;
  final String? error;

  /// Generated slides (in-memory, not written to disk).
  final List<Slide> slides;

  /// Exact catalog theme resolved for runtime application.
  final ResolvedPresentationTheme? theme;

  /// The validated, mechanically normalized plan used to compose the deck.
  final DeckPlanType? plan;

  /// Ordered slide slots that remain unresolved and can be retried.
  final List<SlideGenerationFailure> slideFailures;

  const DeckGenerationResult._({
    required this.success,
    this.message,
    this.error,
    List<Slide>? slides,
    List<SlideGenerationFailure>? slideFailures,
    this.theme,
    this.plan,
  }) : slides = slides ?? const [],
       slideFailures = slideFailures ?? const [];

  DeckGenerationResult.success({
    required List<Slide> slides,
    required DeckPlanType plan,
    required ResolvedPresentationTheme theme,
  }) : this._(
         success: true,
         message:
             'Successfully generated presentation with ${slides.length} slides.',
         slides: slides,
         theme: theme,
         plan: plan,
       );

  DeckGenerationResult.partial({
    required List<Slide> slides,
    required List<SlideGenerationFailure> slideFailures,
    required DeckPlanType plan,
    required ResolvedPresentationTheme theme,
  }) : this._(
         success: false,
         error:
             'Generated ${slides.length} of ${plan.slides.length} slides; '
             'failed: ${slideFailures.map((failure) => '${failure.slideKey} '
                 '(${failure.message})').join(', ')}.',
         slides: slides,
         slideFailures: slideFailures,
         theme: theme,
         plan: plan,
       );

  DeckGenerationResult.failure(String error)
    : this._(success: false, error: error);

  /// Number of slides in the result.
  int get slideCount => slides.length;

  bool get isPartial => plan != null && slideFailures.isNotEmpty;
}

final class _SlideCompositionResult {
  const _SlideCompositionResult({required this.slides, required this.failures});

  final List<Map<String, dynamic>> slides;
  final List<SlideGenerationFailure> failures;
}

/// Service that generates SuperDeck presentations using Google Generative AI.
///
/// Uses a plan-first pipeline, then composes and validates narrative sections.
class DeckGeneratorService {
  final GenerationElementCatalog elementCatalog;

  final PresentationTypographyCatalog typographyCatalog;

  final PresentationThemeCatalog themeCatalog;

  final String apiKey;

  /// Model used to compose and repair each slide.
  ///
  /// Defaults to stable Flash-Lite for latency-sensitive composition.
  final String modelName;

  /// Model used for the outline generation (Phase 1).
  ///
  /// Planning uses the current stable Flash model; the validated sections then
  /// compose concurrently on the current stable Flash-Lite model.
  final String outlineModelName;

  /// Fast model used only when the validated global plan needs correction.
  final String outlineRepairModelName;

  /// Decks at or above this size compose one request per narrative section.
  ///
  /// Smaller decks retain the sequential path for focused repair diagnostics.
  final int sectionBatchThreshold;

  /// Deadline for each outline or slide model call.
  final Duration requestTimeout;

  /// Bounded initial planning request plus one targeted semantic repair.
  final int maxOutlineValidationAttempts;

  /// Bounded local repairs for one slide inside an otherwise valid deck plan.
  ///
  /// Repairing a small slide object prevents a semantic correction from
  /// rewriting or regressing the rest of a 10–20-slide blueprint.
  final int maxOutlineSlideValidationAttempts;

  /// Bounded initial composition plus one targeted semantic repair per slide.
  final int maxSlideValidationAttempts;

  /// Maximum provider calls across the whole run, including transport retries.
  final int maxModelRequests;

  /// Optional semantic repair ceiling across outline and slide generation.
  ///
  /// When omitted, the run uses a small slide-count-aware budget: two repairs
  /// for decks below 20 slides and roughly 15% of the requested slides after
  /// that. This prevents independent per-slide retries from multiplying latency.
  final int? maxRepairRequests;

  /// Wall-clock limit shared by every phase and model request in one run.
  final Duration runTimeout;

  /// Retry policy for transient generation failures.
  final RetryPolicy retryPolicy;

  final GenerationModelClientFactory _modelClientFactory;

  final GenerationPromptProvider _promptProvider;

  DeckGeneratorService({
    required this.apiKey,
    this.modelName = GeminiModelNames.gemini31FlashLite,
    this.outlineModelName = GeminiModelNames.gemini35Flash,
    this.outlineRepairModelName = GeminiModelNames.gemini31FlashLite,
    this.sectionBatchThreshold = 5,
    this.requestTimeout = const Duration(seconds: 45),
    this.maxOutlineValidationAttempts = 2,
    this.maxOutlineSlideValidationAttempts = 2,
    this.maxSlideValidationAttempts = 2,
    this.maxModelRequests = 96,
    this.maxRepairRequests,
    this.runTimeout = const Duration(minutes: 15),
    RetryPolicy? retryPolicy,
    GenerationModelClientFactory? modelClientFactory,
    GenerationPromptProvider? promptProvider,
    GenerationElementCatalog? elementCatalog,
    PresentationTypographyCatalog? typographyCatalog,
    PresentationThemeCatalog? themeCatalog,
  }) : assert(sectionBatchThreshold > 0),
       assert(maxOutlineValidationAttempts > 0),
       assert(maxOutlineSlideValidationAttempts > 0),
       assert(maxSlideValidationAttempts > 0),
       assert(maxModelRequests > 0),
       assert(maxRepairRequests == null || maxRepairRequests > 0),
       assert(runTimeout > Duration.zero),
       retryPolicy = retryPolicy ?? RetryPolicy(maxAttempts: 2),
       elementCatalog = elementCatalog ?? GenerationElementCatalog.builtIn(),
       typographyCatalog =
           typographyCatalog ?? PresentationTypographyCatalog.withDefaults(),
       themeCatalog = themeCatalog ?? PresentationThemeCatalog.withDefaults(),
       _modelClientFactory =
           modelClientFactory ?? GoogleGenerationModelClient.fromApiKey,
       _promptProvider = promptProvider ?? AssetGenerationPromptProvider();

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

    final List<PresentationThemeDescriptor> themeCandidates;
    try {
      themeCandidates = themeCandidatesForRequest(
        request: request,
        themeCatalog: themeCatalog,
        typographyCatalog: typographyCatalog,
      );
    } catch (error) {
      return DeckGenerationResult.failure(
        'Theme selection is invalid: ${_argumentMessage(error)}',
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
    final repairBudget =
        maxRepairRequests ?? _defaultRepairBudget(request.slideCount);
    debugLog.log(
      'DECK_GEN',
      'Run budgets: repairs=$repairBudget, requests=$maxModelRequests, '
          'timeout=${runTimeout.inSeconds}s',
    );
    final executor = GenerationModelCallExecutor(
      client: service,
      retryPolicy: retryPolicy,
      trace: trace,
      requestTimeout: requestTimeout,
      isCancelled: generationCancelled,
      maxModelRequests: maxModelRequests,
      maxRepairRequests: repairBudget,
      runTimeout: runTimeout,
    );

    try {
      await _promptProvider.load();

      final outline = await _runOutlinePhase(
        this,
        executor: executor,
        prompt: modelInput,
        request: request,
        themeCandidates: themeCandidates,
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

      final composition = await _runSlideCompositionPhase(
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

      if (composition == null) {
        return DeckGenerationResult.failure(
          'Failed while composing presentation slides. Please try again.',
        );
      }

      return _finalizeDeck(
        this,
        composition: composition,
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
