import 'dart:async';
import 'dart:typed_data';

import 'package:dartantic_ai/dartantic_ai.dart';

import '../../../core/domain/generated_image_asset.dart';
import '../quick_agent/core/engine/services/error_classifier.dart';

const geminiImageGenerationModel = 'gemini-3.1-flash-image';

/// Input for a single image-generation request.
final class ImageGenerationRequest {
  const ImageGenerationRequest({
    required this.prompt,
    required this.aspectRatio,
  });

  final String prompt;
  final GeneratedImageAspectRatio aspectRatio;
}

/// Explicit outcome of an image-generation request.
sealed class ImageGenerationResult {
  const ImageGenerationResult();
}

final class ImageGenerationSuccess extends ImageGenerationResult {
  ImageGenerationSuccess(List<int> bytes) : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;
}

final class ImageGenerationFailure extends ImageGenerationResult {
  const ImageGenerationFailure(this.message);

  final String message;
}

abstract interface class ImageGenerator {
  Future<ImageGenerationResult> generate(ImageGenerationRequest request);
}

/// Converts unexpected provider exceptions into the same safe failure type
/// returned by conforming [ImageGenerator] implementations.
Future<ImageGenerationResult> generateImageSafely(
  ImageGenerator generator,
  ImageGenerationRequest request,
) async {
  try {
    return await generator.generate(request);
  } catch (error) {
    return ImageGenerationFailure(
      const ErrorClassifier().getUserMessage(error),
    );
  }
}

/// Combines generation output with the metadata needed to persist and retry it.
GeneratedImageAsset generatedImageAssetFromResult({
  required ImageGenerationResult result,
  required String assetKey,
  required String slideKey,
  required String subject,
  required String prompt,
  required GeneratedImageAspectRatio aspectRatio,
}) {
  return switch (result) {
    ImageGenerationSuccess(:final bytes) => GeneratedImageAsset.success(
      assetKey: assetKey,
      slideKey: slideKey,
      subject: subject,
      prompt: prompt,
      aspectRatio: aspectRatio,
      bytes: bytes,
    ),
    ImageGenerationFailure(:final message) => GeneratedImageAsset.failure(
      assetKey: assetKey,
      slideKey: slideKey,
      subject: subject,
      prompt: prompt,
      aspectRatio: aspectRatio,
      error: message,
    ),
  };
}

/// Used when image generation is unavailable in the current app environment.
final class UnavailableImageGenerator implements ImageGenerator {
  const UnavailableImageGenerator([
    this.message = 'Image generation is unavailable.',
  ]);

  final String message;

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) async {
    return ImageGenerationFailure(message);
  }
}

typedef DartanticMediaModelFactory =
    MediaGenerationModel<GoogleMediaGenerationModelOptions> Function({
      required String apiKey,
      required String modelName,
      required GoogleMediaGenerationModelOptions options,
    });

/// Generates PNG images through Dartantic's Google media provider.
final class DartanticImageGenerator implements ImageGenerator {
  DartanticImageGenerator({
    required this.apiKey,
    this.modelName = geminiImageGenerationModel,
    this.timeout = const Duration(seconds: 90),
    DartanticMediaModelFactory? modelFactory,
  }) : _modelFactory = modelFactory ?? _createGoogleModel;

  final String apiKey;
  final String modelName;
  final Duration timeout;
  final DartanticMediaModelFactory _modelFactory;

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) async {
    final options = GoogleMediaGenerationModelOptions(
      aspectRatio: request.aspectRatio.apiValue,
      responseMimeType: 'image/png',
      responseModalities: const ['IMAGE'],
    );
    MediaGenerationModel<GoogleMediaGenerationModelOptions>? model;

    try {
      model = _modelFactory(
        apiKey: apiKey,
        modelName: modelName,
        options: options,
      );
      await for (final chunk
          in model
              .generateMediaStream(
                request.prompt,
                mimeTypes: const ['image/png'],
                options: options,
              )
              .timeout(timeout)) {
        final image = chunk.assets.whereType<DataPart>().firstOrNull;
        if (image == null || image.bytes.isEmpty) continue;

        return ImageGenerationSuccess(image.bytes);
      }
      return const ImageGenerationFailure(
        'The provider returned no image. Try again.',
      );
    } on TimeoutException {
      return const ImageGenerationFailure(
        'Image generation timed out. Try again.',
      );
    } catch (error) {
      return ImageGenerationFailure(
        const ErrorClassifier().getUserMessage(error),
      );
    } finally {
      try {
        model?.dispose();
      } catch (_) {
        // Cleanup must not replace a typed provider result with an exception.
      }
    }
  }

  static MediaGenerationModel<GoogleMediaGenerationModelOptions>
  _createGoogleModel({
    required String apiKey,
    required String modelName,
    required GoogleMediaGenerationModelOptions options,
  }) {
    return GoogleProvider(apiKey: apiKey).createMediaModel(
      name: modelName,
      options: options,
      mimeTypes: const ['image/png'],
    );
  }
}

/// Adds presentation-safe composition constraints to a style and subject.
String buildPresentationImagePrompt(
  String stylePrompt, {
  String? backgroundColor,
}) {
  final background = backgroundColor == null || backgroundColor.isEmpty
      ? ''
      : '\nUse $backgroundColor as the dominant background color. The subject '
            'must remain clearly distinguishable from it.';
  return '''
$stylePrompt

Render the subject as a stylized, minimal composition centered in the frame.
Keep it clean with generous negative space. Avoid photorealism. Do not include
readable text, logos, branding, borders, or presentation chrome.$background
'''
      .trim();
}
