import 'package:superdeck_builder/superdeck_builder.dart';

import '../../../../core/command.dart';
import '../../../../core/data/data_sources/memory_asset_cache_store.dart';
import '../../../../core/result.dart';
import '../../../editor/domain/stores/editor_store.dart';
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
/// Running / error / result come from [Command1]; [phase] and [imageProgress]
/// add the pipeline's intermediate progress, which the base command's binary
/// running state doesn't model. On success it writes any generated image bytes
/// to the asset cache, serializes the slides to markdown, and loads that into
/// the [EditorStore] (which forwards it to the deck loader for live preview).
class GenerateDeckCommand extends Command1<void, String> {
  GenerateDeckCommand({
    required EditorStore editorStore,
    required MemoryAssetCacheStore assetCacheStore,
  }) : _editorStore = editorStore,
       _assetCacheStore = assetCacheStore;

  final EditorStore _editorStore;
  final MemoryAssetCacheStore _assetCacheStore;

  GenerationPhase _phase = GenerationPhase.idle;
  ImageGenerationProgress? _imageProgress;

  /// The pipeline stage currently running (outline → images → deck).
  GenerationPhase get phase => _phase;

  /// Progress of the image-generation stage, or null outside it.
  ImageGenerationProgress? get imageProgress => _imageProgress;

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
    _imageProgress = null;
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

      // Write image bytes to the in-memory asset cache, keyed by the bare
      // filename the model references (e.g. `slide-x-illustration.png`). The
      // slide renderer resolves those keys back through the same cache, so the
      // editor markdown keeps clean `![](slide-x-illustration.png)` refs.
      for (final entry in result.images.entries) {
        await _assetCacheStore.write(entry.key, entry.value);
        debugLog.log('GENERATE_DECK', 'Cached image: ${entry.key}');
      }

      final markdown = const SlideSerializer().serialize(result.slides);
      _editorStore.loadMarkdown(markdown);
      debugLog.log(
        'GENERATE_DECK',
        'Loaded ${result.slides.length} slides into editor.',
      );

      return const Result.ok(null);
    } catch (e, stack) {
      debugLog.error('GENERATE_DECK', 'Unexpected error during generation', stack);
      return Result.error(GenerationException('An unexpected error occurred: $e'));
    } finally {
      _phase = GenerationPhase.idle;
      notifyListeners();
    }
  }

  void _onProgress(
    GenerationPhase newPhase,
    ImageGenerationProgress? progress,
  ) {
    _phase = newPhase;
    if (progress != null) _imageProgress = progress;
    notifyListeners();
  }
}
