import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_image_style_catalog.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';
import 'package:playground/features/ai/image_generation/image_style_preview_coordinator.dart';

void main() {
  test('starts exactly three concurrent previews once per topic', () {
    final generator = _ControlledImageGenerator();
    final coordinator = ImageStylePreviewCoordinator(
      generator: generator,
      catalog: PresentationImageStyleCatalog.withDefaults(),
    );
    addTearDown(coordinator.dispose);

    coordinator.prefetch('Urban gardens');

    expect(generator.requests, hasLength(3));
    expect(coordinator.topic, 'Urban gardens');
    expect(coordinator.previews, hasLength(3));
    expect(
      coordinator.previews.map((preview) => preview.style.id),
      featuredPresentationImageStyleIds,
    );
    expect(
      coordinator.previews.map((preview) => preview.status),
      everyElement(ImageStylePreviewStatus.loading),
    );
    expect(
      generator.requests.map((request) => request.aspectRatio),
      everyElement(GeneratedImageAspectRatio.landscape16x9),
    );

    coordinator.prefetch('  Urban gardens  ');

    expect(generator.requests, hasLength(3));
  });

  test('ignores stale results after a new topic starts', () async {
    final generator = _ControlledImageGenerator();
    final coordinator = ImageStylePreviewCoordinator(
      generator: generator,
      catalog: PresentationImageStyleCatalog.withDefaults(),
    );
    addTearDown(coordinator.dispose);

    coordinator.prefetch('Urban gardens');
    coordinator.prefetch('Ocean restoration');
    expect(generator.requests, hasLength(6));

    generator.results[0].complete(ImageGenerationSuccess([1, 2, 3]));
    await _flushAsyncWork();

    expect(coordinator.topic, 'Ocean restoration');
    expect(
      coordinator.previews,
      everyElement(
        isA<ImageStylePreview>().having(
          (preview) => preview.status,
          'status',
          ImageStylePreviewStatus.loading,
        ),
      ),
    );
  });

  test('keeps failures selectable and retries only the failed style', () async {
    final generator = _ControlledImageGenerator();
    final coordinator = ImageStylePreviewCoordinator(
      generator: generator,
      catalog: PresentationImageStyleCatalog.withDefaults(),
    );
    addTearDown(coordinator.dispose);

    coordinator.prefetch('Urban gardens');
    generator.results.first.complete(
      const ImageGenerationFailure('Preview unavailable.'),
    );
    await _flushAsyncWork();

    final failed = coordinator.previews.first;
    expect(failed.status, ImageStylePreviewStatus.failed);
    expect(failed.error, 'Preview unavailable.');

    coordinator.retry(failed.style.id);

    expect(generator.requests, hasLength(4));
    expect(coordinator.previews.first.status, ImageStylePreviewStatus.loading);
  });

  test('reset invalidates in-flight previews', () async {
    final generator = _ControlledImageGenerator();
    final coordinator = ImageStylePreviewCoordinator(
      generator: generator,
      catalog: PresentationImageStyleCatalog.withDefaults(),
    );
    addTearDown(coordinator.dispose);

    coordinator.prefetch('Urban gardens');
    coordinator.reset();
    generator.results.first.complete(ImageGenerationSuccess([1, 2, 3]));
    await _flushAsyncWork();

    expect(coordinator.topic, isNull);
    expect(coordinator.previews, isEmpty);
  });
}

Future<void> _flushAsyncWork() => Future<void>.delayed(Duration.zero);

final class _ControlledImageGenerator implements ImageGenerator {
  final requests = <ImageGenerationRequest>[];
  final results = <Completer<ImageGenerationResult>>[];

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) {
    requests.add(request);
    final result = Completer<ImageGenerationResult>();
    results.add(result);
    return result.future;
  }
}
