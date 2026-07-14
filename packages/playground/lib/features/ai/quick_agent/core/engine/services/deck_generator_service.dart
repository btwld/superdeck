import 'dart:async';
import 'dart:convert';

import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:superdeck_core/superdeck_core.dart';
import '../../../../../../core/domain/generated_image_asset.dart';
import '../../../../image_generation/image_generator.dart';
import '../prompts/examples_loader.dart';
import '../prompts/prompt_registry.dart';
import '../schemas/deck_schemas.dart';
import '../schemas/outline_schema.dart';
import 'error_classifier.dart';
import 'generation_progress.dart';
import 'google_schema_adapter.dart';
import 'retry_policy.dart';
import 'slide_key_utils.dart';
import 'style_json_serializer.dart';
import '../../constants/gemini_models.dart';
import '../../debug_logger.dart';

part 'deck_generator_pipeline.dart';
part 'deck_generator_pipeline_helpers.dart';
part 'deck_generator_images.dart';
part 'deck_generator_workflow.dart';

/// Wizard-only visual direction used to synthesize planned slide images.
final class DeckGenerationImageConfiguration {
  const DeckGenerationImageConfiguration({
    required this.styleTreatment,
    this.backgroundColor,
  });

  final String styleTreatment;
  final String? backgroundColor;
}

typedef ImageGenerationProgressCallback =
    void Function(int completed, int total);

/// Result of deck generation.
class DeckGenerationResult {
  const DeckGenerationResult._({
    required this.success,
    this.message,
    this.error,
    List<Slide>? slides,
    List<GeneratedImageAsset>? generatedImages,
    this.style,
  }) : slides = slides ?? const [],
       generatedImages = generatedImages ?? const [];

  DeckGenerationResult.success({
    required List<Slide> slides,
    List<GeneratedImageAsset> generatedImages = const [],
    DeckStyleType? style,
  }) : this._(
         success: true,
         message:
             'Successfully generated presentation with ${slides.length} slides.',
         slides: slides,
         generatedImages: generatedImages,
         style: style,
       );

  DeckGenerationResult.failure(String error)
    : this._(success: false, error: error);

  final bool success;
  final String? message;
  final String? error;

  /// Generated slides (in-memory, not written to disk).
  final List<Slide> slides;

  /// Images planned for slides, including non-fatal failed generations.
  final List<GeneratedImageAsset> generatedImages;

  /// Style configuration extracted from the generated deck.
  final DeckStyleType? style;

  /// Number of slides in the result.
  int get slideCount => slides.length;
}

/// Service that generates SuperDeck presentations using Google Generative AI.
///
/// Uses a three-phase pipeline when image generation is configured:
/// 1. Generate outline (structure)
/// 2. Generate planned images (Wizard only)
/// 3. Generate final deck from the outline
class DeckGeneratorService {
  DeckGeneratorService({
    required this.apiKey,
    this.modelName = GeminiModelNames.gemini25Flash,
    this.outlineModelName = GeminiModelNames.gemini3FlashPreview,
    this.thinkingBudget = 3072,
    RetryPolicy? retryPolicy,
    this.imageGenerator,
  }) : retryPolicy = retryPolicy ?? RetryPolicy();

  final String apiKey;

  /// Model used for the final deck generation (Phase 3).
  ///
  /// Defaults to `gemini-2.5-flash` so deck generation works on a free-tier
  /// API key. Pass `GeminiModelNames.gemini25Pro` for higher-quality decks on a
  /// billing-enabled key.
  final String modelName;

  /// Model used for the outline generation (Phase 1).
  final String outlineModelName;

  /// Token budget for thinking. Set to 0 to disable thinking.
  final int thinkingBudget;

  /// Retry policy for transient generation failures.
  final RetryPolicy retryPolicy;

  /// Optional image boundary. Required only for Wizard image generation.
  final ImageGenerator? imageGenerator;

  /// Generates a presentation deck from a natural language prompt.
  ///
  /// The [prompt] should describe the presentation requirements including:
  /// - Topic and content
  /// - Target audience
  /// - Presentation approach/style
  /// - Number of slides
  /// - Visual style preferences
  ///
  /// Uses a three-phase pipeline when [imageConfiguration] is provided:
  /// 1. Generate outline (structure)
  /// 2. Generate planned images
  /// 3. Generate final deck from the outline
  ///
  /// Progress updates are reported via [onProgress] if provided.
  Future<DeckGenerationResult> generate(
    String prompt, {
    GenerationProgressCallback? onProgress,
    DeckGenerationImageConfiguration? imageConfiguration,
    ImageGenerationProgressCallback? onImageProgress,
    bool Function()? isCancelled,
  }) async {
    _logPipelineConfig(this, prompt: prompt);
    final pipelineStart = DateTime.now();
    final service = google_ai.GenerativeService.fromApiKey(apiKey);

    try {
      bool generationCancelled() => isCancelled?.call() ?? false;
      DeckGenerationResult cancelledResult() =>
          DeckGenerationResult.failure('Generation cancelled.');

      // Ensure dotprompt templates are loaded before any phase renders them.
      await PromptRegistry.instance.load();

      final outline = await _runOutlinePhase(
        this,
        service: service,
        prompt: prompt,
        onProgress: onProgress,
      );
      if (generationCancelled()) {
        return cancelledResult();
      }
      if (outline == null) {
        return DeckGenerationResult.failure(
          'Failed to generate presentation outline. Please try again.',
        );
      }

      final generatedImages = await _runImagePhase(
        this,
        outline: outline,
        configuration: imageConfiguration,
        onProgress: onProgress,
        onImageProgress: onImageProgress,
        isCancelled: isCancelled,
      );
      if (generationCancelled()) {
        return cancelledResult();
      }

      final deckJson = await _runFinalDeckPhase(
        this,
        service: service,
        prompt: prompt,
        outline: outline,
        generatedImages: generatedImages,
        onProgress: onProgress,
      );
      if (generationCancelled()) {
        return cancelledResult();
      }

      if (deckJson == null) {
        return DeckGenerationResult.failure(
          'Failed to generate final presentation. Please try again.',
        );
      }

      return _finalizeDeck(
        this,
        deckJson: deckJson,
        expectedSlideCount: (outline['slides'] as List?)?.length ?? 0,
        generatedImages: generatedImages,
        pipelineStart: pipelineStart,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
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
