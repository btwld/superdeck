import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_image_style_catalog.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';

void main() {
  test(
    'generates concurrently and removes failed visual dependencies',
    () async {
      final generator = _TrackingImageGenerator();
      final progress = <(int, int)>[];

      final result = await generateImagesForPlan(
        plan: _plan(),
        imageStyle: PresentationImageStyleCatalog.withDefaults().resolve(
          id: 'watercolor',
          version: 1,
        ),
        generator: generator,
        runId: 'run-42',
        backgroundColor: '#BASE00',
        backgroundColorsByTreatment: const {'visual': '#VISUAL'},
        onProgress: (completed, total) => progress.add((completed, total)),
      );

      expect(generator.requests, hasLength(3));
      expect(generator.maximumActive, 3);
      expect(
        generator.requests.map((request) => request.prompt),
        everyElement(allOf(contains('#VISUAL'), isNot(contains('#BASE00')))),
      );
      expect(result.assets, hasLength(3));
      expect(result.assets.map((asset) => asset.assetKey), [
        'wizard-run-42-slide-01-opening-wave.png',
        'wizard-run-42-slide-03-reef-risk.png',
        'wizard-run-42-slide-04-future-action.png',
      ]);
      expect(result.assets[1].error, contains('safety'));
      expect(progress.first, (0, 3));
      expect(progress.last, (3, 3));

      final successfulElement = result.plan.slides.first.elements!.single;
      expect(successfulElement.source, result.assets.first.assetKey);
      expect(successfulElement.generationPrompt, isNull);

      final failedSlide = result.plan.slides[2];
      expect(failedSlide.elements, isEmpty);
      expect(failedSlide.composition, 'content');
      expect(failedSlide.treatment, 'content');
    },
  );

  test('run IDs isolate asset keys across successive demos', () async {
    final style = PresentationImageStyleCatalog.withDefaults().resolve(
      id: 'minimalist',
      version: 1,
    );
    final first = await generateImagesForPlan(
      plan: _plan(),
      imageStyle: style,
      generator: _SuccessfulImageGenerator(),
      runId: 'first',
    );
    final second = await generateImagesForPlan(
      plan: _plan(),
      imageStyle: style,
      generator: _SuccessfulImageGenerator(),
      runId: 'second',
    );

    expect(
      first.assets
          .map((asset) => asset.assetKey)
          .toSet()
          .intersection(second.assets.map((asset) => asset.assetKey).toSet()),
      isEmpty,
    );
  });
}

final class _TrackingImageGenerator implements ImageGenerator {
  int active = 0;
  int maximumActive = 0;
  final requests = <ImageGenerationRequest>[];

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) async {
    requests.add(request);
    active++;
    if (active > maximumActive) maximumActive = active;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    active--;
    if (request.prompt.toLowerCase().contains('blocked subject')) {
      return const ImageGenerationFailure('Blocked by safety filters.');
    }
    return ImageGenerationSuccess(Uint8List.fromList([1, requests.length]));
  }
}

final class _SuccessfulImageGenerator implements ImageGenerator {
  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) async {
    return ImageGenerationSuccess([1, 2, 3]);
  }
}

DeckPlan _plan() => DeckPlan.parse({
  'topic': 'Ocean systems',
  'story': 'Move from ocean risk to practical restoration.',
  'theme': {'id': 'technical-paper', 'version': 1, 'density': 'balanced'},
  'sections': [
    {
      'key': 'main',
      'title': 'Ocean systems',
      'purpose': 'Explain the system and action.',
      'transition': 'Move from risk to restoration.',
      'slideKeys': ['opening-wave', 'data-table', 'reef-risk', 'future-action'],
    },
  ],
  'slides': [
    _slide(
      key: 'opening-wave',
      composition: 'imageFullBleed',
      subject: 'a curling ocean wave',
    ),
    _slide(key: 'data-table', composition: 'table'),
    _slide(
      key: 'reef-risk',
      composition: 'imageLeft',
      subject: 'blocked subject near a coral reef',
    ),
    _slide(
      key: 'future-action',
      composition: 'imageRight',
      subject: 'coastal restoration volunteers',
    ),
  ],
});

Map<String, Object?> _slide({
  required String key,
  required String composition,
  String? subject,
}) => {
  'key': key,
  'title': 'Test title',
  'purpose': 'Advance the ocean story.',
  'sectionKey': 'main',
  'assertion': 'Ocean systems reward coordinated action.',
  'contentUnits': ['One concrete supporting point'],
  'narrativeRole': 'insight',
  'contentBrief': 'Explain one useful idea.',
  'continuity': 'Connect the surrounding ideas.',
  'composition': composition,
  'treatment': composition.startsWith('image') ? 'visual' : 'data',
  'density': 'balanced',
  'elements': subject == null
      ? <Object?>[]
      : [
          {
            'type': 'image',
            'purpose': 'Reinforce the slide assertion',
            'generationPrompt': subject,
          },
        ],
};
