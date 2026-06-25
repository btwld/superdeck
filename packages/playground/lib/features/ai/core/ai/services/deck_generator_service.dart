import 'dart:async';
import 'dart:convert';

import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/ai/prompts/examples_loader.dart';
import 'package:playground/features/ai/core/ai/prompts/image_style_prompts.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/ai/schemas/outline_schema.dart';
import 'package:playground/features/ai/core/ai/services/error_classifier.dart';
import 'package:playground/features/ai/core/ai/services/generation_progress.dart';
import 'package:playground/features/ai/core/ai/services/image_generator_service.dart';
import 'package:playground/features/ai/core/ai/services/retry_policy.dart';
import 'package:playground/features/ai/core/ai/services/slide_key_utils.dart';
import 'package:playground/features/ai/core/ai/services/style_json_serializer.dart';
import 'package:playground/features/ai/core/constants/gemini_models.dart';
import 'package:playground/features/ai/core/debug_logger.dart';

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
    this.modelName = GeminiModelNames.gemini25Pro,
    this.outlineModelName = GeminiModelNames.gemini3FlashPreview,
    this.thinkingBudget = 3072,
    RetryPolicy? retryPolicy,
  }) : retryPolicy = retryPolicy ?? RetryPolicy();

  final String apiKey;

  /// Model used for the final deck generation (Phase 3).
  final String modelName;

  /// Model used for the outline generation (Phase 1).
  final String outlineModelName;

  /// Token budget for thinking. Set to 0 to disable thinking.
  final int thinkingBudget;

  /// Retry policy for transient generation failures.
  final RetryPolicy retryPolicy;

  // In-memory storage of the last generation request for regeneration.
  String? _lastPrompt;
  String? _lastImageStyleId;
  String? _lastBackgroundColor;

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
    // Store last generation request for regeneration.
    _lastPrompt = prompt;
    _lastImageStyleId = imageStyleId;
    _lastBackgroundColor = backgroundColor;

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

      if (generationCancelled()) {
        return cancelledResult();
      }

      return _finalizeDeck(
        this,
        deckJson: deckJson,
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

  /// Regenerates from the last in-memory generation request.
  ///
  /// Uses the prompt and parameters stored from the previous [generate] call.
  /// Returns a failure result if no previous generation has been performed.
  Future<DeckGenerationResult> regenerateFromLastPrompt({
    GenerationProgressCallback? onProgress,
    bool Function()? isCancelled,
  }) async {
    final prompt = _lastPrompt;
    if (prompt == null || prompt.trim().isEmpty) {
      return DeckGenerationResult.failure(
        'No previous prompt found. Complete the wizard at least once.',
      );
    }

    return generate(
      prompt,
      imageStyleId: _lastImageStyleId,
      backgroundColor: _lastBackgroundColor,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }
}
