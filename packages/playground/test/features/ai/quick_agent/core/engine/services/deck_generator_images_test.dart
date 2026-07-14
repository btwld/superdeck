import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';

final class _TrackingImageGenerator implements ImageGenerator {
  int active = 0;
  int maximumActive = 0;
  final List<ImageGenerationRequest> requests = [];

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) async {
    requests.add(request);
    active++;
    if (active > maximumActive) maximumActive = active;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    active--;
    if (request.prompt.contains('blocked subject')) {
      return const ImageGenerationFailure('Blocked by safety filters.');
    }
    return ImageGenerationSuccess(Uint8List.fromList([1, requests.length]));
  }
}

void main() {
  test(
    'generates every planned image with two workers and keeps failures',
    () async {
      final generator = _TrackingImageGenerator();
      final progress = <(int, int)>[];
      final outline = <String, dynamic>{
        'topic': 'Ocean systems',
        'slides': [
          {
            'key': 'opening-wave',
            'imageRequirement': {'subject': 'a curling ocean wave'},
          },
          {'key': 'data-table'},
          {
            'key': 'reef-risk',
            'imageRequirement': {'subject': 'blocked subject'},
          },
          {
            'key': 'future-action',
            'imageRequirement': {'subject': 'coastal restoration volunteers'},
          },
        ],
      };

      final images = await generateImagesForOutline(
        outline: outline,
        configuration: const DeckGenerationImageConfiguration(
          styleTreatment: 'soft watercolor washes',
          backgroundColor: '#001122',
        ),
        generator: generator,
        onProgress: (completed, total) => progress.add((completed, total)),
      );

      expect(images, hasLength(3));
      expect(generator.requests, hasLength(3));
      expect(generator.maximumActive, 2);
      expect(generator.requests.map((request) => request.aspectRatio).toSet(), {
        GeneratedImageAspectRatio.slide3x4,
      });
      expect(images.map((image) => image.assetKey), [
        'slide-01-opening-wave-illustration.png',
        'slide-03-reef-risk-illustration.png',
        'slide-04-future-action-illustration.png',
      ]);
      expect(images[0].status, GeneratedImageStatus.ready);
      expect(images[1].status, GeneratedImageStatus.failed);
      expect(images[1].error, contains('safety'));
      expect(progress.first, (0, 3));
      expect(progress.last, (3, 3));
    },
  );

  test(
    'final prompt requires failed keys so manual retry needs no rewrite',
    () {
      const failed = GeneratedImageAsset.failure(
        assetKey: 'slide-02-risk-illustration.png',
        slideKey: 'risk',
        subject: 'a fragile bridge',
        prompt: 'prompt',
        aspectRatio: GeneratedImageAspectRatio.slide3x4,
        error: 'Provider unavailable',
      );

      final prompt = formatGeneratedImagesForPrompt([failed]);

      expect(prompt, contains('slide-02-risk-illustration.png'));
      expect(prompt, contains('(failed)'));
      expect(prompt, contains('broken placeholders'));
    },
  );

  test(
    'final slides retain failed references even when the model omits them',
    () {
      const failed = GeneratedImageAsset.failure(
        assetKey: 'slide-01-risk-illustration.png',
        slideKey: 'risk',
        subject: 'a fragile [bridge]',
        prompt: 'prompt',
        aspectRatio: GeneratedImageAspectRatio.slide3x4,
        error: 'Provider unavailable',
      );
      final slides = <Map<String, dynamic>>[
        {
          'key': 'risk',
          'sections': [
            {
              'type': 'section',
              'blocks': [
                {'type': 'block', 'content': '## The risk'},
              ],
            },
          ],
        },
      ];

      ensureGeneratedImageReferences(slides, [failed]);
      ensureGeneratedImageReferences(slides, [failed]);

      final blocks =
          ((slides.single['sections'] as List).single as Map)['blocks'] as List;
      expect(blocks, hasLength(2));
      expect(
        (blocks.last as Map)['content'],
        r'![a fragile \[bridge\]](slide-01-risk-illustration.png)',
      );
    },
  );

  test('asset keys are deterministic and safe for cache storage', () {
    expect(
      buildGeneratedAssetKey(8, '  Launch / Results!  '),
      'slide-09-launch-results-illustration.png',
    );
    final longKey = List.filled(300, 'a').join();
    expect(buildGeneratedAssetKey(0, longKey).length, lessThan(100));
  });
}
