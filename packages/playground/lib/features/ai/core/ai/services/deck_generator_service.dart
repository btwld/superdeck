import 'dart:async';
import 'dart:convert';

import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:superdeck_core/superdeck_core.dart';
import '../prompts/examples_loader.dart';
import '../prompts/image_style_prompts.dart';
import '../prompts/prompt_registry.dart';
import '../schemas/deck_schemas.dart';
import '../schemas/outline_schema.dart';
import 'error_classifier.dart';
import 'generation_progress.dart';
import 'google_schema_adapter.dart';
import 'image_generator_service.dart';
import 'retry_policy.dart';
import 'slide_key_utils.dart';
import 'style_json_serializer.dart';
import '../../constants/gemini_image_options.dart';
import '../../constants/gemini_models.dart';
import '../../debug_logger.dart';

part 'deck_generator_pipeline.dart';
part 'deck_generator_pipeline_helpers.dart';
part 'deck_generator_workflow.dart';

/// Result of deck generation.
class DeckGenerationResult {
  const DeckGenerationResult._({
    required this.success,
    this.message,
    this.error,
    List<Slide>? slides,
    Map<String, Uint8List>? images,
    this.style,
    this.imageFailures,
  }) : slides = slides ?? const [],
       images = images ?? const {};

  DeckGenerationResult.success({
    required List<Slide> slides,
    Map<String, Uint8List> images = const {},
    DeckStyleType? style,
    Map<String, String>? imageFailures,
  }) : this._(
         success: true,
         message:
             'Successfully generated presentation with ${slides.length} slides.',
         slides: slides,
         images: images,
         style: style,
         imageFailures: imageFailures,
       );

  DeckGenerationResult.failure(String error)
    : this._(success: false, error: error);

  final bool success;
  final String? message;
  final String? error;

  /// Generated slides (in-memory, not written to disk).
  final List<Slide> slides;

  /// Generated image bytes keyed by bare asset filename (e.g. slide-intro-illustration.png).
  final Map<String, Uint8List> images;

  /// Style configuration extracted from the generated deck.
  final DeckStyleType? style;

  /// Images that failed to generate, keyed by slide key.
  /// Null if no images were requested or all succeeded.
  final Map<String, String>? imageFailures;

  /// Number of slides in the result.
  int get slideCount => slides.length;

  /// Whether all requested images were generated successfully.
  bool get allImagesGenerated =>
      imageFailures == null || imageFailures!.isEmpty;
}

class _ImagePhaseData {
  const _ImagePhaseData({
    required this.availableImages,
    required this.imageFailures,
    required this.imageBytes,
  });

  final Map<String, String> availableImages;
  final Map<String, String>? imageFailures;
  final Map<String, Uint8List> imageBytes;
}

/// Service that generates SuperDeck presentations using Google Generative AI.
///
/// Uses a 3-phase pipeline:
/// 1. Generate outline (structure + image requirements)
/// 2. Generate images based on outline
/// 3. Generate final deck with available images context
class DeckGeneratorService {
  DeckGeneratorService({
    required this.apiKey,
    this.modelName = GeminiModelNames.gemini25Flash,
    this.outlineModelName = GeminiModelNames.gemini3FlashPreview,
    this.thinkingBudget = 3072,
    RetryPolicy? retryPolicy,
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

  /// Generates a presentation deck from a natural language prompt.
  ///
  /// The [prompt] should describe the presentation requirements including:
  /// - Topic and content
  /// - Target audience
  /// - Presentation approach/style
  /// - Number of slides
  /// - Visual style preferences
  ///
  /// Uses a 3-phase pipeline:
  /// 1. Generate outline with image requirements
  /// 2. Generate images for slides that need them
  /// 3. Generate final deck with available images context
  ///
  /// Progress updates are reported via [onProgress] if provided.
  Future<DeckGenerationResult> generate(
    String prompt, {
    String? imageStyleId,
    String? backgroundColor,
    GenerationProgressCallback? onProgress,
    bool Function()? isCancelled,
  }) async {
    _logPipelineConfig(
      this,
      prompt: prompt,
      imageStyleId: imageStyleId,
      backgroundColor: backgroundColor,
    );
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

      final imagePhase = await _runImagePhase(
        this,
        outline: outline,
        imageStyleId: imageStyleId,
        backgroundColor: backgroundColor,
        onProgress: onProgress,
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
        availableImages: imagePhase.availableImages,
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
        availableImages: imagePhase.availableImages,
        imageBytes: imagePhase.imageBytes,
        imageFailures: imagePhase.imageFailures,
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
