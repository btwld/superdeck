import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:googleai_dart/googleai_dart.dart' as ga;
import 'package:http/http.dart' as http;

import '../prompts/prompt_registry.dart';
import 'retry_policy.dart';
import '../../constants/gemini_image_options.dart';
import '../../debug_logger.dart';

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

typedef _ImageCacheKey = ({
  GeminiImageModel model,
  GeminiImageAspectRatio aspectRatio,
  GeminiImageSize imageSize,
  String prompt,
});

/// Generates slide-safe background images via Gemini image models.
///
/// Converts provider/model/safety failures into user-safe error results.
/// See `docs/ai/image-generation.md` for prompt-writing guidance.
class ImageGeneratorService {
  ImageGeneratorService({
    required this.apiKey,
    this.model = GeminiImageModel.gemini31FlashImage,
    this.aspectRatio = GeminiImageAspectRatio.ratio16x9,
    GeminiImageSize? imageSize,
    RetryPolicy? retryPolicy,
    http.Client? httpClient,
  }) : imageSize = imageSize ?? model.defaultImageSize,
       retryPolicy = retryPolicy ?? RetryPolicy() {
    _validateModelOptions();
    _client = ga.GoogleAIClient(
      config: ga.GoogleAIConfig.googleAI(
        apiVersion: ga.ApiVersion.v1beta,
        authProvider: ga.ApiKeyProvider(
          apiKey,
          placement: ga.AuthPlacement.header,
        ),
        retryPolicy: const ga.RetryPolicy(maxRetries: 0),
      ),
      httpClient: httpClient,
    );
  }

  final String apiKey;
  final GeminiImageModel model;

  /// Aspect ratio for generated images.
  final GeminiImageAspectRatio aspectRatio;

  /// Output resolution for generated images.
  final GeminiImageSize imageSize;

  /// Retry policy for transient generation failures.
  final RetryPolicy retryPolicy;

  late final ga.GoogleAIClient _client;

  // Simple in-memory LRU cache to avoid regenerating identical prompts during a
  // single app/session (e.g., navigating back to the image style selector).
  //
  // Network/model inference dominates latency; caching is the highest-leverage
  // local speedup without changing model behavior.
  static final LinkedHashMap<_ImageCacheKey, Uint8List> _memoryCache =
      LinkedHashMap<_ImageCacheKey, Uint8List>();
  static const int _maxCacheEntries = 32;

  _ImageCacheKey _cacheKey(String prompt) {
    return (
      model: model,
      aspectRatio: aspectRatio,
      imageSize: imageSize,
      prompt: prompt,
    );
  }

  void _validateModelOptions() {
    if (!model.supportsAspectRatio(aspectRatio)) {
      throw ArgumentError.value(
        aspectRatio,
        'aspectRatio',
        '${model.label} does not support '
            '${geminiImageAspectRatioApiValue(aspectRatio)}',
      );
    }
    if (!model.supportsImageSize(imageSize)) {
      throw ArgumentError.value(
        imageSize,
        'imageSize',
        '${model.label} does not support ${geminiImageSizeApiValue(imageSize)}',
      );
    }
  }

  ga.InteractionResponseFormatConfig _buildResponseFormat() {
    return ga.InteractionResponseFormatConfig.single(
      ga.InteractionImageResponseFormat(
        aspectRatio: aspectRatio,
        imageSize: imageSize,
      ),
    );
  }

  /// Generates an image from a text prompt.
  ///
  /// Returns [ImageGenerationResult.success] with image bytes on success,
  /// or [ImageGenerationResult.failure] with an error message on failure.
  Future<ImageGenerationResult> generateImage(String prompt) async {
    final key = _cacheKey(prompt);
    final cached = _memoryCache.remove(key);
    if (cached != null) {
      // Re-insert to mark as most-recently-used.
      _memoryCache[key] = cached;
      debugLog.log(
        'IMG',
        'Cache hit (${cached.length} bytes) for model: ${model.apiValue}',
      );
      return ImageGenerationResult.success(cached);
    }

    return _requestImage(prompt, key);
  }

  Future<ImageGenerationResult> _requestImage(
    String prompt,
    _ImageCacheKey cacheKey,
  ) async {
    try {
      debugLog.log(
        'IMG',
        'Starting interactions image generation with model: ${model.apiValue}',
      );

      final interaction = await retryPolicy.run(
        () => _client.interactions
            .create(
              model: model.apiValue,
              input: ga.InteractionInput.text(prompt),
              responseFormat: _buildResponseFormat(),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw TimeoutException('Image generation timed out');
              },
            ),
      );

      String? imageData;
      for (final image in interaction.imageOutputs) {
        final data = image.data;
        if (data != null && data.isNotEmpty) {
          imageData = data;
          break;
        }
      }
      if (imageData == null) {
        debugLog.log('IMG', 'No image data in interactions response');
        return ImageGenerationResult.failure('No image data in response');
      }

      final bytes = base64Decode(imageData);
      _memoryCache[cacheKey] = bytes;
      while (_memoryCache.length > _maxCacheEntries) {
        _memoryCache.remove(_memoryCache.keys.first);
      }

      debugLog.log(
        'IMG',
        'Interactions image generated: ${bytes.length} bytes',
      );
      return ImageGenerationResult.success(bytes);
    } on TimeoutException {
      debugLog.error('IMG', 'Image generation timed out after 60s');
      return ImageGenerationResult.failure('Image generation timed out');
    } on ga.GoogleAIException catch (e) {
      debugLog.error(
        'IMG',
        'Interactions image generation failed: ${e.message}',
      );
      return ImageGenerationResult.failure(e.message);
    } catch (e) {
      debugLog.error(
        'IMG',
        'Interactions image generation failed: ${e.runtimeType}',
      );
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
    _client.close();
  }
}
