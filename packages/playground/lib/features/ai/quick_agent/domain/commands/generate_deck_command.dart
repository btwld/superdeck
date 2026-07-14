import 'package:flutter/widgets.dart';
import 'package:superdeck_builder/superdeck_builder.dart';

import '../../../../../core/command.dart';
import '../../../../../core/result.dart';
import '../../../../editor/domain/stores/deck_document_store.dart';
import '../../../../../core/domain/stores/deck_customization_store.dart';
import '../../core/debug_logger.dart';
import '../../core/engine/services/deck_generation_request.dart';
import '../../core/engine/services/deck_generator_service.dart';
import '../../core/engine/services/generation_progress.dart';
import '../../core/env_config.dart';

/// Failure raised by [GenerateDeckCommand]. Its [toString] is the user-facing
/// message (no `Exception:` prefix), so the panel can surface it directly.
class GenerationException implements Exception {
  const GenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Generates a presentation from a natural-language prompt and loads it into the
/// editor.
///
/// Running / error / result come from [Command1]; [phase] adds the pipeline's
/// intermediate progress, which the base command's binary running state doesn't
/// model. On success it serializes the slides to Markdown and replaces the
/// shared [DeckDocumentStore].
class GenerateDeckCommand extends Command1<void, DeckGenerationRequest> {
  GenerateDeckCommand({
    required DeckDocumentStore documentStore,
    required DeckCustomizationStore customizationStore,
  }) : _documentStore = documentStore,
       _customizationStore = customizationStore;

  final DeckDocumentStore _documentStore;
  final DeckCustomizationStore _customizationStore;

  GenerationProgress _progress = const GenerationProgress(GenerationPhase.idle);

  /// The pipeline stage currently running (outline → deck).
  GenerationPhase get phase => _progress.phase;

  GenerationProgress get progress => _progress;

  @override
  Future<Result<void>> action(DeckGenerationRequest request) async {
    if (!EnvConfig.hasGeminiApiKey) {
      return const Result.error(
        GenerationException(
          'No Gemini API key configured. '
          'Set GOOGLE_AI_API_KEY via --dart-define.',
        ),
      );
    }

    _progress = const GenerationProgress(GenerationPhase.generatingOutline);
    notifyListeners();

    try {
      final service = DeckGeneratorService(apiKey: EnvConfig.geminiApiKey);
      final result = await service.generate(request, onProgress: _onProgress);

      if (!result.success) {
        return Result.error(
          GenerationException(result.error ?? 'Unknown generation error.'),
        );
      }
      if (result.slides.isEmpty) {
        return const Result.error(
          GenerationException('No slides were generated. Please try again.'),
        );
      }

      final markdown = const SlideSerializer().serialize(result.slides);
      _documentStore.replaceMarkdown(markdown);
      if (result.style case final style?) {
        _customizationStore.applyGeneratedStyle(
          GeneratedDeckStyle(
            background: _colorFromHex(style.colors.background),
            surface: _colorFromHex(style.colors.surface),
            surfaceAlt: _colorFromHex(style.colors.surfaceAlt),
            heading: _colorFromHex(style.colors.heading),
            body: _colorFromHex(style.colors.body),
            accent: _colorFromHex(style.colors.accent),
            accentContrast: _colorFromHex(style.colors.accentContrast),
            headlineFamily: style.fonts.headline,
            bodyFamily: style.fonts.body,
            direction: style.direction,
            density: style.density,
            typeScale: style.typeScale,
          ),
        );
      }
      debugLog.log(
        'GENERATE_DECK',
        'Loaded ${result.slides.length} slides into editor.',
      );

      return const Result.ok(null);
    } catch (e, stack) {
      debugLog.error(
        'GENERATE_DECK',
        'Unexpected error during generation',
        stack,
      );
      return Result.error(
        GenerationException('An unexpected error occurred: $e'),
      );
    } finally {
      _progress = const GenerationProgress(GenerationPhase.idle);
      notifyListeners();
    }
  }

  void _onProgress(GenerationProgress progress) {
    _progress = progress;
    notifyListeners();
  }
}

Color _colorFromHex(String value) {
  final hex = value.replaceFirst('#', '');
  return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
}
