import 'dart:typed_data';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';

final class _FakeMediaModel
    extends MediaGenerationModel<GoogleMediaGenerationModelOptions> {
  _FakeMediaModel(this.results)
    : super(
        name: 'fake-image-model',
        defaultOptions: const GoogleMediaGenerationModelOptions(),
      );

  final Stream<MediaGenerationResult> results;
  bool disposed = false;
  GoogleMediaGenerationModelOptions? receivedOptions;
  List<String>? receivedMimeTypes;

  @override
  Stream<MediaGenerationResult> generateMediaStream(
    String prompt, {
    required List<String> mimeTypes,
    List<ChatMessage> history = const [],
    List<Part> attachments = const [],
    GoogleMediaGenerationModelOptions? options,
    Schema? outputSchema,
  }) {
    receivedMimeTypes = mimeTypes;
    receivedOptions = options;
    return results;
  }

  @override
  void dispose() => disposed = true;
}

void main() {
  test('returns PNG bytes with the requested model and aspect ratio', () async {
    final model = _FakeMediaModel(
      Stream.value(
        MediaGenerationResult(
          assets: [
            DataPart(Uint8List.fromList([1, 2, 3]), mimeType: 'image/png'),
          ],
          isComplete: true,
        ),
      ),
    );
    String? createdModelName;
    GoogleMediaGenerationModelOptions? createdOptions;
    final generator = DartanticImageGenerator(
      apiKey: 'test-key',
      modelFactory: ({required apiKey, required modelName, required options}) {
        createdModelName = modelName;
        createdOptions = options;
        return model;
      },
    );

    final result = await generator.generate(
      const ImageGenerationRequest(
        prompt: 'provider-options-success',
        aspectRatio: GeneratedImageAspectRatio.preview16x9,
      ),
    );

    expect(result, isA<ImageGenerationSuccess>());
    expect((result as ImageGenerationSuccess).bytes, [1, 2, 3]);
    expect(createdModelName, geminiImageGenerationModel);
    expect(createdOptions?.aspectRatio, '16:9');
    expect(createdOptions?.responseMimeType, 'image/png');
    expect(createdOptions?.responseModalities, ['IMAGE']);
    expect(model.receivedMimeTypes, ['image/png']);
    expect(model.disposed, isTrue);
  });

  test('returns a retryable failure when no image asset is emitted', () async {
    final model = _FakeMediaModel(
      Stream.value(MediaGenerationResult(isComplete: true)),
    );
    final generator = DartanticImageGenerator(
      apiKey: 'test-key',
      modelFactory: ({required apiKey, required modelName, required options}) =>
          model,
    );

    final result = await generator.generate(
      const ImageGenerationRequest(
        prompt: 'missing-image-result',
        aspectRatio: GeneratedImageAspectRatio.slide3x4,
      ),
    );

    expect(
      result,
      isA<ImageGenerationFailure>().having(
        (failure) => failure.message,
        'message',
        contains('no image'),
      ),
    );
    expect(model.disposed, isTrue);
  });

  test('translates provider errors and always disposes the model', () async {
    final model = _FakeMediaModel(
      Stream.error(Exception('RESOURCE_EXHAUSTED quota 429')),
    );
    final generator = DartanticImageGenerator(
      apiKey: 'test-key',
      modelFactory: ({required apiKey, required modelName, required options}) =>
          model,
    );

    final result = await generator.generate(
      const ImageGenerationRequest(
        prompt: 'provider-error-result',
        aspectRatio: GeneratedImageAspectRatio.slide3x4,
      ),
    );

    expect(
      result,
      isA<ImageGenerationFailure>().having(
        (failure) => failure.message,
        'message',
        contains('overloaded'),
      ),
    );
    expect(model.disposed, isTrue);
  });

  test('translates model-construction errors into typed failures', () async {
    final generator = DartanticImageGenerator(
      apiKey: 'test-key',
      modelFactory: ({required apiKey, required modelName, required options}) {
        throw StateError('invalid api key provider detail');
      },
    );

    final result = await generator.generate(
      const ImageGenerationRequest(
        prompt: 'model-construction-error',
        aspectRatio: GeneratedImageAspectRatio.preview16x9,
      ),
    );

    expect(
      result,
      isA<ImageGenerationFailure>().having(
        (failure) => failure.message,
        'message',
        contains('API key'),
      ),
    );
    expect(
      (result as ImageGenerationFailure).message,
      isNot(contains('detail')),
    );
  });

  test('presentation prompt excludes text and carries the background', () {
    final prompt = buildPresentationImagePrompt(
      'A friendly robot in flat vector style.',
      backgroundColor: '#101828',
    );

    expect(prompt, contains('friendly robot'));
    expect(prompt, contains('#101828'));
    expect(prompt, contains('Do not include\nreadable text'));
  });
}
