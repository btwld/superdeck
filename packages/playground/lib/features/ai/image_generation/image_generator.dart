import 'dart:async';
import 'dart:typed_data';

import 'package:dartantic_ai/dartantic_ai.dart';

import '../../../core/domain/generated_image_asset.dart';
import '../quick_agent/core/engine/services/error_classifier.dart';

const geminiImagePreviewModel = 'gemini-3.1-flash-lite-image';
const geminiImageGenerationModel = 'gemini-3.1-flash-image';
const imagePreviewTimeout = Duration(seconds: 8);
const imageGenerationTimeout = Duration(seconds: 12);

/// Input for one image-generation request.
final class ImageGenerationRequest {
  final String prompt;
  final GeneratedImageAspectRatio aspectRatio;

  const ImageGenerationRequest({
    required this.prompt,
    required this.aspectRatio,
  });
}

/// Explicit outcome of one image-generation request.
sealed class ImageGenerationResult {
  const ImageGenerationResult();
}

final class ImageGenerationSuccess extends ImageGenerationResult {
  final Uint8List bytes;

  ImageGenerationSuccess(List<int> bytes) : bytes = Uint8List.fromList(bytes);
}

final class ImageGenerationFailure extends ImageGenerationResult {
  final String message;

  const ImageGenerationFailure(this.message);
}

abstract interface class ImageGenerator {
  Future<ImageGenerationResult> generate(ImageGenerationRequest request);
}

/// Converts unexpected provider exceptions into the typed failure boundary.
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

/// Used when media generation is unavailable in the current environment.
final class UnavailableImageGenerator implements ImageGenerator {
  final String message;

  const UnavailableImageGenerator([
    this.message = 'Image generation is unavailable.',
  ]);

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
  final String apiKey;
  final String modelName;
  final Duration timeout;
  final DartanticMediaModelFactory _modelFactory;

  DartanticImageGenerator({
    required this.apiKey,
    this.modelName = geminiImagePreviewModel,
    Duration? timeout,
    DartanticMediaModelFactory? modelFactory,
  }) : timeout = timeout ?? _defaultTimeout(modelName),
       _modelFactory = modelFactory ?? _createGoogleModel;

  static Duration _defaultTimeout(String modelName) {
    if (modelName == geminiImageGenerationModel) {
      return imageGenerationTimeout;
    }

    return imagePreviewTimeout;
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

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) async {
    final options = GoogleMediaGenerationModelOptions(
      responseMimeType: 'image/png',
      aspectRatio: request.aspectRatio.apiValue,
      responseModalities: const ['IMAGE'],
    );
    MediaGenerationModel<GoogleMediaGenerationModelOptions>? model;

    try {
      model = _modelFactory(
        apiKey: apiKey,
        modelName: modelName,
        options: options,
      );
      final image = await _firstImageWithin(
        model.generateMediaStream(
          request.prompt,
          mimeTypes: const ['image/png'],
          options: options,
        ),
        timeout,
      );
      if (image != null) return ImageGenerationSuccess(image.bytes);

      return const ImageGenerationFailure(
        'The provider returned no image. Try again.',
      );
    } on TimeoutException {
      final operation = modelName == geminiImageGenerationModel
          ? 'Image generation'
          : 'Image preview';

      return ImageGenerationFailure('$operation took too long. Try again.');
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
}

/// Waits for the first usable image under one wall-clock deadline.
///
/// `Stream.timeout` measures inactivity between chunks. Media providers can
/// emit progress chunks indefinitely, so a shrinking deadline is required to
/// keep the complete image request inside [timeout].
Future<DataPart?> _firstImageWithin(
  Stream<MediaGenerationResult> stream,
  Duration timeout,
) async {
  final timer = Stopwatch()..start();
  final iterator = StreamIterator(stream);
  try {
    while (timer.elapsed < timeout) {
      final remaining = timeout - timer.elapsed;
      final hasNext = await iterator.moveNext().timeout(remaining);
      if (!hasNext) return null;
      final image = iterator.current.assets.whereType<DataPart>().firstOrNull;
      if (image != null && image.bytes.isNotEmpty) return image;
    }
    throw TimeoutException('Image generation exceeded its deadline.');
  } finally {
    await iterator.cancel();
  }
}

/// Adds presentation-safe constraints to a style and subject.
String buildPresentationImagePrompt(
  String stylePrompt, {
  String? backgroundColor,
}) {
  final background = backgroundColor == null || backgroundColor.isEmpty
      ? ''
      : '\nRender the entire background as a flat, untextured $backgroundColor '
            'field so it blends into the slide. Do not add a paper rectangle, '
            'frame, border, vignette, gradient, or shadow behind the subject. '
            'Keep the subject clearly distinguishable from the background.';

  return '''
$stylePrompt

Create a polished presentation illustration with one clear focal subject and
generous negative space. Do not include readable text, logos, branding,
borders, presentation chrome, watermarks, or photorealistic faces.$background
'''
      .trim();
}
