import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/core/result.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_progress.dart';
import 'package:playground/features/ai/wizard/core/ai/wizard_context.dart';
import 'package:playground/features/ai/wizard/domain/commands/create_wizard_deck_command.dart';
import 'package:playground/features/editor/domain/files/deck_file.dart';
import 'package:superdeck_core/superdeck_core.dart'
    show ContentBlock, SectionBlock, Slide;

import '../../../../../helpers/fake_deck_file_repository.dart';

final class _FakeDeckGenerator extends DeckGeneratorService {
  _FakeDeckGenerator(this.output) : super(apiKey: 'fake-key');

  final DeckGenerationResult output;
  DeckGenerationImageConfiguration? receivedConfiguration;

  @override
  Future<DeckGenerationResult> generate(
    String prompt, {
    GenerationProgressCallback? onProgress,
    DeckGenerationImageConfiguration? imageConfiguration,
    ImageGenerationProgressCallback? onImageProgress,
    bool Function()? isCancelled,
  }) async {
    receivedConfiguration = imageConfiguration;
    onProgress?.call(GenerationPhase.generatingOutline);
    onProgress?.call(GenerationPhase.generatingImages);
    onImageProgress?.call(0, 2);
    onImageProgress?.call(2, 2);
    onProgress?.call(GenerationPhase.finalizing);
    return output;
  }
}

void main() {
  test(
    'creates a persistent topic-named deck despite partial image failure',
    () async {
      final repository = FakeDeckFileRepository();
      final output = DeckGenerationResult.success(
        slides: [
          Slide(
            key: 'opening',
            sections: [
              SectionBlock([ContentBlock('# Opening')]),
            ],
          ),
        ],
        generatedImages: const [
          GeneratedImageAsset.failure(
            assetKey: 'slide-01-opening-illustration.png',
            slideKey: 'opening',
            subject: 'a bright launch',
            prompt: 'paint a bright launch',
            aspectRatio: GeneratedImageAspectRatio.slide3x4,
            error: 'Provider unavailable',
          ),
        ],
      );
      final generator = _FakeDeckGenerator(output);
      final command = CreateWizardDeckCommand(
        repository: repository,
        imageGenerator: const UnavailableImageGenerator(),
        apiKey: 'fake-key',
        generatorFactory: () => generator,
      );
      addTearDown(command.dispose);

      await command(
        const WizardContext(
          topic: 'Future of Work',
          colors: ['#101828'],
          imageStyleId: 'watercolor',
        ),
      );

      expect(command.completed, isTrue);
      final snapshot = (command.result as Ok<DeckFileSnapshot>).value;
      expect(snapshot.reference.path, '/decks/future-of-work.md');
      expect(repository.files[snapshot.reference.path], contains('# Opening'));
      expect(
        generator.receivedConfiguration?.styleTreatment,
        contains('watercolor'),
      );
      expect(generator.receivedConfiguration?.backgroundColor, '#101828');
      expect(command.completedImages, 2);
      expect(command.totalImages, 2);
    },
  );

  test('requires a curated artwork choice before generation', () async {
    final repository = FakeDeckFileRepository();
    final command = CreateWizardDeckCommand(
      repository: repository,
      imageGenerator: const UnavailableImageGenerator(),
      apiKey: 'fake-key',
      generatorFactory: () => _FakeDeckGenerator(
        DeckGenerationResult.success(slides: [Slide(key: 'unused')]),
      ),
    );
    addTearDown(command.dispose);

    await command(const WizardContext(topic: 'No Style'));

    expect(command.error, isTrue);
    expect(command.errorMessage, contains('artwork style'));
    expect(repository.files, isEmpty);
  });
}
