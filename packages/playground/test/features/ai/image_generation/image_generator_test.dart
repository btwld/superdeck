import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';

void main() {
  test('uses separate preview and final-generation deadlines', () {
    final preview = DartanticImageGenerator(apiKey: 'test-key');
    final finalGeneration = DartanticImageGenerator(
      apiKey: 'test-key',
      modelName: geminiImageGenerationModel,
    );

    expect(preview.timeout, imagePreviewTimeout);
    expect(finalGeneration.timeout, imageGenerationTimeout);
  });

  test('applies the timeout to total image-generation wall time', () async {
    final model = _ProgressOnlyMediaModel();
    final generator = DartanticImageGenerator(
      apiKey: 'test-key',
      timeout: const Duration(milliseconds: 40),
      modelFactory: ({required apiKey, required modelName, required options}) =>
          model,
    );
    final timer = Stopwatch()..start();

    final result = await generator.generate(
      const ImageGenerationRequest(
        prompt: 'A presentation-safe abstract illustration',
        aspectRatio: GeneratedImageAspectRatio.landscape16x9,
      ),
    );
    timer.stop();

    expect(result, isA<ImageGenerationFailure>());
    expect(
      (result as ImageGenerationFailure).message,
      'Image preview took too long. Try again.',
    );
    expect(timer.elapsed, lessThan(const Duration(milliseconds: 200)));
    expect(model.disposed, isTrue);
    expect(model.cancelled, isTrue);
  });

  test('labels final-generation timeouts accurately', () async {
    final generator = DartanticImageGenerator(
      apiKey: 'test-key',
      modelName: geminiImageGenerationModel,
      timeout: const Duration(milliseconds: 40),
      modelFactory: ({required apiKey, required modelName, required options}) =>
          _ProgressOnlyMediaModel(),
    );

    final result = await generator.generate(
      const ImageGenerationRequest(
        prompt: 'A presentation-safe abstract illustration',
        aspectRatio: GeneratedImageAspectRatio.landscape16x9,
      ),
    );

    expect(result, isA<ImageGenerationFailure>());
    expect(
      (result as ImageGenerationFailure).message,
      'Image generation took too long. Try again.',
    );
  });
}

final class _ProgressOnlyMediaModel
    extends MediaGenerationModel<GoogleMediaGenerationModelOptions> {
  _ProgressOnlyMediaModel()
    : super(
        name: 'progress-only',
        defaultOptions: const GoogleMediaGenerationModelOptions(),
      );

  var disposed = false;
  var cancelled = false;

  @override
  Stream<MediaGenerationResult> generateMediaStream(
    String prompt, {
    required List<String> mimeTypes,
    List<ChatMessage> history = const [],
    List<Part> attachments = const [],
    GoogleMediaGenerationModelOptions? options,
    outputSchema,
  }) async* {
    try {
      while (true) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        yield MediaGenerationResult();
      }
    } finally {
      cancelled = true;
    }
  }

  @override
  void dispose() => disposed = true;
}
