import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:path/path.dart' as p;
import '../prompts/examples_loader.dart';
import '../prompts/image_style_prompts.dart';
import '../prompts/prompt_registry.dart';
import '../schemas/deck_schemas.dart';
import '../schemas/outline_schema.dart';
import './error_classifier.dart';
import './generation_progress.dart';
import './image_generator_service.dart';
import './retry_policy.dart';
import './slide_key_utils.dart';
import './style_json_serializer.dart';
import '../../constants/gemini_models.dart';
import '../../constants/paths.dart';
import '../../debug_logger.dart';

part 'deck_generator_pipeline.dart';
part 'deck_generator_pipeline_helpers.dart';
part 'deck_generator_workflow.dart';

/// Result of deck generation.
class DeckGenerationResult {
  const DeckGenerationResult._({
    required this.success,
    this.message,
    this.path,
    this.error,
    this.slideCount,
    this.style,
    this.imageFailures,
  });

  DeckGenerationResult.success({
    required String path,
    required int slideCount,
    DeckStyleType? style,
    Map<String, String>? imageFailures,
  }) : this._(
         success: true,
         message:
             'Successfully generated presentation with $slideCount slides.',
         path: path,
         slideCount: slideCount,
         style: style,
         imageFailures: imageFailures,
       );

  DeckGenerationResult.failure(String error)
    : this._(success: false, error: error);

  final bool success;
  final String? message;
  final String? path;
  final String? error;
  final int? slideCount;

  /// Style configuration extracted from the generated deck.
  final DeckStyleType? style;

  /// Images that failed to generate, keyed by slide key.
  /// Null if no images were requested or all succeeded.
  final Map<String, String>? imageFailures;

  /// Whether all requested images were generated successfully.
  bool get allImagesGenerated =>
      imageFailures == null || imageFailures!.isEmpty;
}

class _ImagePhaseData {
  const _ImagePhaseData({
    required this.availableImages,
    required this.imageFailures,
  });

  final Map<String, String> availableImages;
  final Map<String, String>? imageFailures;
}

class _StyleData {
  const _StyleData({required this.style, required this.styleJson});

  final DeckStyleType? style;
  final Map<String, Object?>? styleJson;
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
      final outline = await _runOutlinePhase(
        this,
        service: service,
        prompt: prompt,
        onProgress: onProgress,
      );
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
      );

      final deckJson = await _runFinalDeckPhase(
        this,
        service: service,
        prompt: prompt,
        outline: outline,
        availableImages: imagePhase.availableImages,
        onProgress: onProgress,
      );

      if (deckJson == null) {
        return DeckGenerationResult.failure(
          'Failed to generate final presentation. Please try again.',
        );
      }

      return _finalizeDeck(
        this,
        deckJson: deckJson,
        availableImages: imagePhase.availableImages,
        imageFailures: imagePhase.imageFailures,
        pipelineStart: pipelineStart,
        onProgress: onProgress,
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

  /// Regenerates from the last saved generation metadata.
  ///
  /// Reads prompt and parameters (imageStyleId, backgroundColor) from
  /// the metadata JSON saved during the previous generation.
  /// Falls back to plain prompt file if metadata is unavailable.
  Future<DeckGenerationResult> regenerateFromLastPrompt({
    GenerationProgressCallback? onProgress,
  }) async {
    // Try metadata JSON first (has full parameters)
    final metadataFile = File(Paths.lastGenerationPath);
    if (await metadataFile.exists()) {
      try {
        final json =
            jsonDecode(await metadataFile.readAsString())
                as Map<String, dynamic>;
        final prompt = json['prompt'] as String?;
        if (prompt != null && prompt.trim().isNotEmpty) {
          return generate(
            prompt,
            imageStyleId: json['imageStyleId'] as String?,
            backgroundColor: json['backgroundColor'] as String?,
            onProgress: onProgress,
          );
        }
      } catch (e) {
        debugLog.log('DECK_GEN', 'Failed to read metadata, falling back: $e');
      }
    }

    // Fallback to plain prompt file
    final promptFile = File(Paths.lastPromptPath);
    if (!await promptFile.exists()) {
      return DeckGenerationResult.failure(
        'No previous prompt found. Complete the wizard at least once.',
      );
    }

    final prompt = await promptFile.readAsString();
    if (prompt.trim().isEmpty) {
      return DeckGenerationResult.failure('Previous prompt file is empty.');
    }

    return generate(prompt, onProgress: onProgress);
  }
}
