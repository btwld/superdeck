import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';

void main() {
  const apiKey = String.fromEnvironment('GOOGLE_AI_API_KEY');

  test('Gemini generates Wizard preview and slide artwork PNGs', () async {
    if (apiKey.isEmpty) {
      markTestSkipped(
        'GOOGLE_AI_API_KEY is required via --dart-define-from-file.',
      );
      return;
    }

    final generator = DartanticImageGenerator(apiKey: apiKey);
    for (final ratio in [
      GeneratedImageAspectRatio.preview16x9,
      GeneratedImageAspectRatio.slide3x4,
    ]) {
      final result = await generator.generate(
        ImageGenerationRequest(
          prompt: buildPresentationImagePrompt(
            'A single friendly geometric lighthouse guiding one small boat',
            backgroundColor: '#102A43',
          ),
          aspectRatio: ratio,
        ),
      );

      expect(result, isA<ImageGenerationSuccess>());
      expect((result as ImageGenerationSuccess).bytes.length, greaterThan(100));
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
