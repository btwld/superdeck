import 'gemini_models.dart';

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
      GeminiImageModel.gemini31FlashImage => GeminiImageSize.px512,
      GeminiImageModel.gemini3ProImage => GeminiImageSize.k1,
    };
  }

  bool supportsAspectRatio(GeminiImageAspectRatio aspectRatio) {
    return switch (this) {
      GeminiImageModel.gemini31FlashImage => true,
      GeminiImageModel.gemini3ProImage => !aspectRatio.flashOnly,
    };
  }

  bool supportsImageSize(GeminiImageSize imageSize) {
    return switch (this) {
      GeminiImageModel.gemini31FlashImage => true,
      GeminiImageModel.gemini3ProImage => !imageSize.flashOnly,
    };
  }
}

/// Gemini image response format types.
enum GeminiImageResponseType {
  image(apiValue: 'image', label: 'Image');

  const GeminiImageResponseType({required this.apiValue, required this.label});

  final String apiValue;
  final String label;
}

/// Aspect ratios supported by Gemini image generation.
enum GeminiImageAspectRatio {
  square1x1(apiValue: '1:1', label: 'Square', width: 1, height: 1),
  portrait2x3(apiValue: '2:3', label: 'Portrait 2:3', width: 2, height: 3),
  landscape3x2(apiValue: '3:2', label: 'Landscape 3:2', width: 3, height: 2),
  portrait3x4(apiValue: '3:4', label: 'Portrait 3:4', width: 3, height: 4),
  landscape4x3(apiValue: '4:3', label: 'Landscape 4:3', width: 4, height: 3),
  portrait4x5(apiValue: '4:5', label: 'Portrait 4:5', width: 4, height: 5),
  landscape5x4(apiValue: '5:4', label: 'Landscape 5:4', width: 5, height: 4),
  portrait9x16(apiValue: '9:16', label: 'Portrait 9:16', width: 9, height: 16),
  widescreen16x9(
    apiValue: '16:9',
    label: 'Widescreen 16:9',
    width: 16,
    height: 9,
  ),
  ultrawide21x9(
    apiValue: '21:9',
    label: 'Ultrawide 21:9',
    width: 21,
    height: 9,
  ),
  tall1x4(
    apiValue: '1:4',
    label: 'Tall 1:4',
    width: 1,
    height: 4,
    flashOnly: true,
  ),
  wide4x1(
    apiValue: '4:1',
    label: 'Wide 4:1',
    width: 4,
    height: 1,
    flashOnly: true,
  ),
  tall1x8(
    apiValue: '1:8',
    label: 'Tall 1:8',
    width: 1,
    height: 8,
    flashOnly: true,
  ),
  wide8x1(
    apiValue: '8:1',
    label: 'Wide 8:1',
    width: 8,
    height: 1,
    flashOnly: true,
  ),
  portrait9x21(
    apiValue: '9:21',
    label: 'Portrait 9:21',
    width: 9,
    height: 21,
    flashOnly: true,
  );

  const GeminiImageAspectRatio({
    required this.apiValue,
    required this.label,
    required this.width,
    required this.height,
    this.flashOnly = false,
  });

  final String apiValue;
  final String label;
  final int width;
  final int height;
  final bool flashOnly;

  double get value => width / height;
}

/// Output image sizes supported by Gemini image generation.
enum GeminiImageSize {
  px512(apiValue: '512', label: '512 px', flashOnly: true),
  k1(apiValue: '1K', label: '1K'),
  k2(apiValue: '2K', label: '2K'),
  k4(apiValue: '4K', label: '4K', preview: true);

  const GeminiImageSize({
    required this.apiValue,
    required this.label,
    this.flashOnly = false,
    this.preview = false,
  });

  final String apiValue;
  final String label;
  final bool flashOnly;
  final bool preview;
}
