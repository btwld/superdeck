import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/constants/gemini_image_options.dart';
import 'package:playground/features/ai/core/constants/gemini_models.dart';

void main() {
  group('GeminiImageModel', () {
    test('contains supported image model API values', () {
      expect(
        GeminiImageModel.values.map((model) => model.apiValue),
        unorderedEquals({
          GeminiModelNames.gemini31FlashImage,
          GeminiModelNames.gemini3ProImage,
        }),
      );
    });

    test('exposes model-specific default sizes', () {
      expect(
        GeminiImageModel.gemini31FlashImage.defaultImageSize,
        GeminiImageSize.size512,
      );
      expect(
        GeminiImageModel.gemini3ProImage.defaultImageSize,
        GeminiImageSize.size1k,
      );
    });

    test('exposes model-specific option support', () {
      expect(
        GeminiImageModel.gemini31FlashImage.supportsImageSize(
          GeminiImageSize.size512,
        ),
        isTrue,
      );
      expect(
        GeminiImageModel.gemini3ProImage.supportsImageSize(
          GeminiImageSize.size512,
        ),
        isFalse,
      );
      expect(
        GeminiImageModel.gemini3ProImage.supportsAspectRatio(
          GeminiImageAspectRatio.ratio1x4,
        ),
        isFalse,
      );
      expect(
        GeminiImageModel.gemini3ProImage.supportsAspectRatio(
          GeminiImageAspectRatio.ratio16x9,
        ),
        isTrue,
      );
    });
  });

  group('GeminiImageAspectRatio', () {
    test('serializes API values through googleai_dart helpers', () {
      expect(
        geminiImageAspectRatioApiValue(GeminiImageAspectRatio.ratio16x9),
        '16:9',
      );
      expect(
        geminiImageAspectRatioApiValue(GeminiImageAspectRatio.ratio3x4),
        '3:4',
      );
    });
  });

  group('GeminiImageSize', () {
    test('serializes API values through googleai_dart helpers', () {
      expect(geminiImageSizeApiValue(GeminiImageSize.size512), '512');
      expect(geminiImageSizeApiValue(GeminiImageSize.size2k), '2K');
    });
  });
}
