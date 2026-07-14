import 'package:superdeck_builder/superdeck_builder.dart';

import '../../../../../core/command.dart';
import '../../../../../core/result.dart';
import '../../../../editor/domain/files/deck_file.dart';
import '../../../../editor/domain/files/deck_file_repository.dart';
import '../../../image_generation/image_generator.dart';
import '../../../quick_agent/core/debug_logger.dart';
import '../../../quick_agent/core/engine/services/deck_generator_service.dart';
import '../../../quick_agent/core/engine/services/generation_progress.dart';
import '../../../quick_agent/core/env_config.dart';
import '../../../quick_agent/domain/commands/generate_deck_command.dart';
import '../../core/ai/prompts/image_style_prompts.dart';
import '../../core/ai/services/prompt_builder.dart';
import '../../core/ai/wizard_context.dart';

typedef WizardDeckGeneratorFactory = DeckGeneratorService Function();

/// Generates, saves, and selects a complete Wizard-created deck.
class CreateWizardDeckCommand
    extends Command1<DeckFileSnapshot, WizardContext> {
  CreateWizardDeckCommand({
    required DeckFileRepository repository,
    required ImageGenerator imageGenerator,
    String? apiKey,
    WizardDeckGeneratorFactory? generatorFactory,
  }) : _repository = repository,
       _imageGenerator = imageGenerator,
       _apiKey =
           apiKey ??
           (EnvConfig.hasGeminiApiKey ? EnvConfig.geminiApiKey : null),
       _generatorFactory = generatorFactory;

  final DeckFileRepository _repository;
  final ImageGenerator _imageGenerator;
  final String? _apiKey;
  final WizardDeckGeneratorFactory? _generatorFactory;

  GenerationPhase _phase = GenerationPhase.idle;
  int _completedImages = 0;
  int _totalImages = 0;

  GenerationPhase get phase => _phase;
  int get completedImages => _completedImages;
  int get totalImages => _totalImages;

  String get progressLabel {
    if (_phase == GenerationPhase.generatingImages && _totalImages > 0) {
      return 'Creating slide artwork $_completedImages of $_totalImages…';
    }
    return _phase.label;
  }

  String? get errorMessage => switch (result) {
    Failure(:final error) => error.toString(),
    _ => null,
  };

  @override
  Future<Result<DeckFileSnapshot>> action(WizardContext context) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return const Result.error(
        GenerationException(
          'No Gemini API key configured. Set GOOGLE_AI_API_KEY via '
          '--dart-define.',
        ),
      );
    }
    final topic = context.topic?.trim();
    if (topic == null || topic.isEmpty) {
      return const Result.error(
        GenerationException('The presentation topic is missing.'),
      );
    }
    final imageStyle = ImageStyle.fromId(context.imageStyleId ?? '');
    if (imageStyle == null) {
      return const Result.error(
        GenerationException('Choose an artwork style before generating.'),
      );
    }

    _completedImages = 0;
    _totalImages = 0;
    _updatePhase(GenerationPhase.generatingOutline);
    try {
      final generator =
          _generatorFactory?.call() ??
          DeckGeneratorService(apiKey: apiKey, imageGenerator: _imageGenerator);
      final generation = await generator.generate(
        buildPromptFromWizardContext(context),
        imageConfiguration: DeckGenerationImageConfiguration(
          styleTreatment: imageStyle.treatment,
          backgroundColor: context.colors?.firstOrNull,
        ),
        onProgress: _updatePhase,
        onImageProgress: _updateImageProgress,
      );
      if (!generation.success) {
        return Result.error(
          GenerationException(
            generation.error ?? 'Presentation generation failed.',
          ),
        );
      }
      if (generation.slides.isEmpty) {
        return const Result.error(
          GenerationException('No slides were generated. Please try again.'),
        );
      }

      _updatePhase(GenerationPhase.finalizing);
      final markdown = const SlideSerializer().serialize(generation.slides);
      final created = await _repository.createGeneratedDeck(
        name: topic,
        markdown: markdown,
        images: generation.generatedImages,
      );
      if (created case Ok(:final value)) {
        debugLog.log(
          'WIZARD',
          'Created ${value.reference.path} with '
              '${generation.generatedImages.length} planned images.',
        );
      }
      return created;
    } catch (_, stackTrace) {
      debugLog.error(
        'WIZARD',
        'Unexpected Wizard generation failure',
        stackTrace,
      );
      return Result.error(
        GenerationException('An unexpected error occurred. Please try again.'),
      );
    } finally {
      _updatePhase(GenerationPhase.idle);
    }
  }

  void _updatePhase(GenerationPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  void _updateImageProgress(int completed, int total) {
    _completedImages = completed;
    _totalImages = total;
    notifyListeners();
  }
}
