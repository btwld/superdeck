import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:superdeck_ai/core/ai/prompts/prompt_registry.dart';
import 'package:superdeck_ai/core/ai/services/retry_policy.dart';
import 'package:superdeck_ai/core/constants/gemini_models.dart';
import 'package:superdeck_ai/core/debug_logger.dart';

/// Result of image generation.
class ImageGenerationResult {
  const ImageGenerationResult._({
    required this.success,
    this.bytes,
    this.error,
  });

  /// Creates a successful result with image bytes.
  ImageGenerationResult.success(Uint8List bytes)
    : this._(success: true, bytes: bytes);

  /// Creates a failure result with an error message.
  ImageGenerationResult.failure(String error)
    : this._(success: false, error: error);

  /// Whether the image generation succeeded.
  final bool success;

  /// The generated image bytes (only present on success).
  final Uint8List? bytes;

  /// Error message (only present on failure).
  final String? error;
}

/// Generates slide-safe background images via Gemini image models.
///
/// Converts provider/model/safety failures into user-safe error results.
/// See `docs/ai/image-generation.md` for prompt-writing guidance.
class ImageGeneratorService {
  ImageGeneratorService({
    required this.apiKey,
    this.modelName = GeminiModelNames.gemini25FlashImage,
    this.aspectRatio = '16:9',
    RetryPolicy? retryPolicy,
  }) : retryPolicy = retryPolicy ?? RetryPolicy();

  final String apiKey;
  final String modelName;

  /// Aspect ratio for generated images.
  /// Supported: 1:1, 2:3, 3:2, 3:4, 4:3, 9:16, 16:9, 21:9
  final String aspectRatio;

  /// Retry policy for transient generation failures.
  final RetryPolicy retryPolicy;

  google_ai.GenerativeService? _service;

  // Simple in-memory LRU cache to avoid regenerating identical prompts during a
  // single app/session (e.g., navigating back to the image style selector).
  //
  // Network/model inference dominates latency; caching is the highest-leverage
  // local speedup without changing model behavior.
  static final LinkedHashMap<int, Uint8List> _memoryCache =
      LinkedHashMap<int, Uint8List>();
  static const int _maxCacheEntries = 32;

  int _cacheKey(String prompt) => Object.hash(modelName, aspectRatio, prompt);

  /// Generates an image from a text prompt.
  ///
  /// Returns [ImageGenerationResult.success] with image bytes on success,
  /// or [ImageGenerationResult.failure] with an error message on failure.
  Future<ImageGenerationResult> generateImage(String prompt) async {
    try {
      final key = _cacheKey(prompt);
      final cached = _memoryCache.remove(key);
      if (cached != null) {
        // Re-insert to mark as most-recently-used.
        _memoryCache[key] = cached;
        debugLog.log(
          'IMG',
          'Cache hit (${cached.length} bytes) for model: $modelName',
        );
        return ImageGenerationResult.success(cached);
      }

      _service ??= google_ai.GenerativeService.fromApiKey(apiKey);

      debugLog.log('IMG', 'Starting image generation with model: $modelName');

      final request = google_ai.GenerateContentRequest(
        model: modelName,
        contents: [
          google_ai.Content(
            role: 'user',
            parts: [google_ai.Part(text: prompt)],
          ),
        ],
        generationConfig: google_ai.GenerationConfig(
          // Request image-only output to avoid text-only responses
          responseModalities: [google_ai.GenerationConfig_Modality.image],
          imageConfig: google_ai.ImageConfig(aspectRatio: aspectRatio),
        ),
      );

      final response = await retryPolicy.run(
        () => _service!
            .generateContent(request)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw TimeoutException('Image generation timed out');
              },
            ),
      );

      debugLog.log(
        'IMG',
        'Response received - candidates: ${response.candidates.length}',
      );

      // Check for blocked prompts
      final blockReason = response.promptFeedback?.blockReason;
      if (blockReason != null && blockReason.isNotDefault) {
        debugLog.log('IMG', 'Prompt blocked: $blockReason');
        return ImageGenerationResult.failure(
          'Content blocked by safety filter',
        );
      }

      final candidate = response.candidates.firstOrNull;

      // Check finish reason for image-specific failures
      final finishReason = candidate?.finishReason;
      if (finishReason != null) {
        final imageFailReasons = {
          google_ai.Candidate_FinishReason.safety,
          google_ai.Candidate_FinishReason.recitation,
          google_ai.Candidate_FinishReason.blocklist,
          google_ai.Candidate_FinishReason.prohibitedContent,
          google_ai.Candidate_FinishReason.imageSafety,
          google_ai.Candidate_FinishReason.imageProhibitedContent,
          google_ai.Candidate_FinishReason.imageRecitation,
          google_ai.Candidate_FinishReason.noImage,
          google_ai.Candidate_FinishReason.imageOther,
        };
        if (imageFailReasons.contains(finishReason)) {
          debugLog.log('IMG', 'Image blocked by finish reason: $finishReason');
          return ImageGenerationResult.failure(
            'Content blocked by safety filter',
          );
        }
      }

      final parts = candidate?.content?.parts ?? [];
      debugLog.log('IMG', 'Parts in response: ${parts.length}');

      for (final part in parts) {
        if (part.inlineData != null && part.inlineData!.data.isNotEmpty) {
          debugLog.log(
            'IMG',
            'Image generated: ${part.inlineData!.data.length} bytes, '
                'mime: ${part.inlineData!.mimeType}',
          );
          final bytes = part.inlineData!.data;

          _memoryCache[key] = bytes;
          while (_memoryCache.length > _maxCacheEntries) {
            _memoryCache.remove(_memoryCache.keys.first);
          }

          return ImageGenerationResult.success(bytes);
        }
        if (part.text != null) {
          debugLog.log('IMG', 'Text response: ${part.text}');
        }
      }

      debugLog.log('IMG', 'No image data in response');
      return ImageGenerationResult.failure('No image data in response');
    } on TimeoutException {
      debugLog.error('IMG', 'Image generation timed out after 60s');
      return ImageGenerationResult.failure('Image generation timed out');
    } catch (e) {
      // Log error type only - avoid exposing API keys in stack traces
      debugLog.error('IMG', 'Image generation failed: ${e.runtimeType}');
      return ImageGenerationResult.failure(
        'Image generation failed: ${e.runtimeType}',
      );
    }
  }

  /// Builds an image prompt with presentation-specific constraints.
  ///
  /// [stylePrompt] should describe visual intent as narrative prose.
  /// See `docs/ai/image-generation.md` for examples and prompting guidance.
  static String buildPrompt(String stylePrompt, {String? backgroundColor}) {
    final base = PromptRegistry.instance.render(
      'image_generation',
      input: {'stylePrompt': stylePrompt},
    );
    if (backgroundColor != null && backgroundColor.isNotEmpty) {
      return '$base\n'
          'Use $backgroundColor as the dominant background color for the image. '
          'The subject should complement this background.';
    }
    return base;
  }

  void dispose() {
    _service?.close();
    _service = null;
  }
}
