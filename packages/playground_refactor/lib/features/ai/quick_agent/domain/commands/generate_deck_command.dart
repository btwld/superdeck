import 'package:superdeck_builder/superdeck_builder.dart';

import '../../../../../core/command.dart';
import '../../../../../core/result.dart';
import '../../../../editor/utils/markdown_editor.dart';
import '../../core/debug_logger.dart';
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
/// model. On success it serializes the slides to markdown and hands that to the
/// [MarkdownEditor] (which loads it and forwards to the deck loader for preview).
class GenerateDeckCommand extends Command1<void, String> {
  GenerateDeckCommand({required MarkdownEditor editor}) : _editor = editor;

  final MarkdownEditor _editor;

  GenerationPhase _phase = GenerationPhase.idle;

  /// The pipeline stage currently running (outline → deck).
  GenerationPhase get phase => _phase;

  @override
  Future<Result<void>> action(String prompt) async {
    if (!EnvConfig.hasGeminiApiKey) {
      return const Result.error(
        GenerationException(
          'No Gemini API key configured. '
          'Set GOOGLE_AI_API_KEY via --dart-define or .env file.',
        ),
      );
    }

    _phase = GenerationPhase.generatingOutline;
    notifyListeners();

    try {
      final service = DeckGeneratorService(apiKey: EnvConfig.geminiApiKey);
      final result = await service.generate(prompt, onProgress: _onProgress);

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
      _editor.replaceMarkdown(markdown);
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
      _phase = GenerationPhase.idle;
      notifyListeners();
    }
  }

  void _onProgress(GenerationPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }
}
