import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import '../prompts/prompt_registry.dart';
import 'retry_policy.dart';
import '../../constants/gemini_models.dart';
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

/// Generates slide-safe background images via Gemini image models.
///
/// Converts provider/model/safety failures into user-safe error results.
/// See `docs/ai/image-generation.md` for prompt-writing guidance.
class ImageGeneratorService {
  ImageGeneratorService({
    required this.apiKey,
    this.modelName = GeminiModelNames.gemini31FlashImagePreview,
    this.aspectRatio = '16:9',
    RetryPolicy? retryPolicy,
    http.Client? httpClient,
  }) : retryPolicy = retryPolicy ?? RetryPolicy(),
       _httpClient = httpClient,
       _ownsHttpClient = httpClient == null;

  final String apiKey;
  final String modelName;

  /// Aspect ratio for generated images.
  /// Supported: 1:1, 2:3, 3:2, 3:4, 4:3, 9:16, 16:9, 21:9
  final String aspectRatio;

  /// Retry policy for transient generation failures.
  final RetryPolicy retryPolicy;

  http.Client? _httpClient;
  final bool _ownsHttpClient;

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

    return _requestImage(prompt, key);
  }

  Future<ImageGenerationResult> _requestImage(
    String prompt,
    int cacheKey,
  ) async {
    try {
      debugLog.log(
        'IMG',
        'Starting interactions image generation with model: $modelName',
      );

      final client = _httpClient ??= http.Client();
      final response = await retryPolicy.run(
        () => client
            .post(
              Uri.https(
                'generativelanguage.googleapis.com',
                '/v1beta/interactions',
              ),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode({
                'model': modelName,
                'input': prompt,
                'response_format': {
                  'type': 'image',
                  'aspect_ratio': aspectRatio,
                  'image_size': '512',
                },
              }),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw TimeoutException('Image generation timed out');
              },
            ),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _parseError(response.body);
        debugLog.error(
          'IMG',
          'Interactions image generation failed: ${response.statusCode}',
        );
        return ImageGenerationResult.failure(message);
      }

      final decoded = jsonDecode(response.body);
      final bytes = _extractImageBytes(decoded);
      if (bytes == null) {
        debugLog.log('IMG', 'No image data in interactions response');
        return ImageGenerationResult.failure('No image data in response');
      }

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

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        final error = decoded['error'];
        if (error is Map<String, Object?>) {
          final message = error['message']?.toString();
          if (message != null && message.isNotEmpty) {
            return message;
          }
          final code = error['code']?.toString();
          if (code != null && code.isNotEmpty) {
            return code;
          }
        }
      }
    } catch (_) {
      // Fall through to generic message.
    }
    return 'Image generation failed';
  }

  Uint8List? _extractImageBytes(Object? value) {
    if (value is Map) {
      final data = value['data'];
      final mimeType = value['mime_type'] ?? value['mimeType'];
      final type = value['type'];
      final looksLikeImage =
          type == 'image' ||
          (mimeType is String && mimeType.toLowerCase().startsWith('image/'));
      if (data is String && data.isNotEmpty && looksLikeImage) {
        return base64Decode(data);
      }

      for (final child in value.values) {
        final bytes = _extractImageBytes(child);
        if (bytes != null) return bytes;
      }
    }

    if (value is Iterable) {
      for (final child in value) {
        final bytes = _extractImageBytes(child);
        if (bytes != null) return bytes;
      }
    }

    return null;
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
    if (_ownsHttpClient) {
      _httpClient?.close();
    }
    _httpClient = null;
  }
}
