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
        GeminiImageSize.px512,
      );
      expect(
        GeminiImageModel.gemini3ProImage.defaultImageSize,
        GeminiImageSize.k1,
      );
    });

    test('exposes model-specific option support', () {
      expect(
        GeminiImageModel.gemini31FlashImage.supportsImageSize(
          GeminiImageSize.px512,
        ),
        isTrue,
      );
      expect(
        GeminiImageModel.gemini3ProImage.supportsImageSize(
          GeminiImageSize.px512,
        ),
        isFalse,
      );
      expect(
        GeminiImageModel.gemini3ProImage.supportsAspectRatio(
          GeminiImageAspectRatio.tall1x4,
        ),
        isFalse,
      );
      expect(
        GeminiImageModel.gemini3ProImage.supportsAspectRatio(
          GeminiImageAspectRatio.widescreen16x9,
        ),
        isTrue,
      );
    });
  });

  group('GeminiImageResponseType', () {
    test('contains image response format type', () {
      expect(
        GeminiImageResponseType.values.map((type) => type.apiValue),
        unorderedEquals({'image'}),
      );
    });
  });

  group('GeminiImageAspectRatio', () {
    test('contains documented aspect ratio API values', () {
      expect(
        GeminiImageAspectRatio.values.map((ratio) => ratio.apiValue),
        unorderedEquals({
          '1:1',
          '2:3',
          '3:2',
          '3:4',
          '4:3',
          '4:5',
          '5:4',
          '9:16',
          '16:9',
          '21:9',
          '1:4',
          '4:1',
          '1:8',
          '8:1',
          '9:21',
        }),
      );
    });

    test('exposes numeric ratio metadata', () {
      expect(GeminiImageAspectRatio.widescreen16x9.width, 16);
      expect(GeminiImageAspectRatio.widescreen16x9.height, 9);
      expect(GeminiImageAspectRatio.widescreen16x9.value, 16 / 9);
    });

    test('marks Flash-only aspect ratios', () {
      expect(GeminiImageAspectRatio.tall1x4.flashOnly, isTrue);
      expect(GeminiImageAspectRatio.wide4x1.flashOnly, isTrue);
      expect(GeminiImageAspectRatio.tall1x8.flashOnly, isTrue);
      expect(GeminiImageAspectRatio.wide8x1.flashOnly, isTrue);
      expect(GeminiImageAspectRatio.portrait9x21.flashOnly, isTrue);
      expect(GeminiImageAspectRatio.widescreen16x9.flashOnly, isFalse);
    });
  });

  group('GeminiImageSize', () {
    test('contains documented image size API values', () {
      expect(
        GeminiImageSize.values.map((size) => size.apiValue),
        unorderedEquals({'512', '1K', '2K', '4K'}),
      );
    });

    test('marks 4K as preview', () {
      expect(GeminiImageSize.k4.preview, isTrue);
      expect(GeminiImageSize.px512.preview, isFalse);
    });

    test('marks 512 as Flash-only', () {
      expect(GeminiImageSize.px512.flashOnly, isTrue);
      expect(GeminiImageSize.k1.flashOnly, isFalse);
    });
  });
}
