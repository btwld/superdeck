import 'package:googleai_dart/googleai_dart.dart' as ga;

import 'gemini_models.dart';

typedef GeminiImageAspectRatio = ga.InteractionImageResponseFormatAspectRatio;
typedef GeminiImageSize = ga.InteractionImageResponseFormatSize;

const _flashOnlyAspectRatios = {
  GeminiImageAspectRatio.ratio1x4,
  GeminiImageAspectRatio.ratio4x1,
  GeminiImageAspectRatio.ratio1x8,
  GeminiImageAspectRatio.ratio8x1,
};

/// Gemini image-generation models available to internal image services.
enum GeminiImageModel {
  gemini31FlashImage(
    apiValue: GeminiModelNames.gemini31FlashImage,
    label: 'Gemini 3.1 Flash Image',
  ),
  gemini3ProImage(
    apiValue: GeminiModelNames.gemini3ProImage,
    label: 'Gemini 3 Pro Image',
  );

  const GeminiImageModel({required this.apiValue, required this.label});

  final String apiValue;
  final String label;
}

extension GeminiImageModelOptions on GeminiImageModel {
  GeminiImageSize get defaultImageSize {
    return switch (this) {
      GeminiImageModel.gemini31FlashImage => GeminiImageSize.size512,
      GeminiImageModel.gemini3ProImage => GeminiImageSize.size1k,
    };
  }

  bool supportsAspectRatio(GeminiImageAspectRatio aspectRatio) {
    return switch (this) {
      GeminiImageModel.gemini31FlashImage => true,
      GeminiImageModel.gemini3ProImage => !_flashOnlyAspectRatios.contains(
        aspectRatio,
      ),
    };
  }

  bool supportsImageSize(GeminiImageSize imageSize) {
    return switch (this) {
      GeminiImageModel.gemini31FlashImage => true,
      GeminiImageModel.gemini3ProImage => imageSize != GeminiImageSize.size512,
    };
  }
}

String geminiImageAspectRatioApiValue(GeminiImageAspectRatio aspectRatio) {
  return ga.interactionImageResponseFormatAspectRatioToString(aspectRatio);
}

String geminiImageSizeApiValue(GeminiImageSize imageSize) {
  return ga.interactionImageResponseFormatSizeToString(imageSize);
}
