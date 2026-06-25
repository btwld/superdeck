import 'package:signals/signals_flutter.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:playground/features/ai/core/ai/services/deck_generator_service.dart';
import 'package:playground/features/ai/core/ai/services/generation_progress.dart';
import 'package:playground/features/ai/core/debug_logger.dart';
import 'package:playground/features/ai/core/env_config.dart';
import 'package:playground/stores/deck_customization_store.dart';
import 'package:playground/utils/memory_asset_cache_store.dart';
import 'package:playground/utils/memory_deck_loader.dart';
import 'package:playground/utils/text_editor_controller.dart';

/// Orchestration store for AI presentation generation.
///
/// Wires together [DeckGeneratorService], [MemoryDeckLoader],
/// [MemoryAssetCacheStore], [DeckCustomizationStore], and
/// [TextEditorController] to produce a full in-memory generation flow.
class AiStore {
  AiStore({
    required MemoryDeckLoader deckLoader,
    required MemoryAssetCacheStore assetCacheStore,
    required DeckCustomizationStore customizationStore,
    required TextEditorController textEditorController,
  }) : _deckLoader = deckLoader,
       _assetCacheStore = assetCacheStore,
       _customizationStore = customizationStore,
       _textEditorController = textEditorController;

  final MemoryDeckLoader _deckLoader;
  final MemoryAssetCacheStore _assetCacheStore;
  final DeckCustomizationStore _customizationStore;
  final TextEditorController _textEditorController;

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------

  final isGenerating = signal<bool>(false);
  final phase = signal<GenerationPhase>(GenerationPhase.idle);
  final prompt = signal<String>('');
  final error = signal<String?>(null);
  final imageProgress = signal<ImageGenerationProgress?>(null);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Generates a presentation from [userPrompt].
  ///
  /// Updates reactive signals throughout the pipeline. On success, writes
  /// image bytes to the asset cache, serializes slides to markdown, and pushes
  /// the markdown into the editor and deck loader. Applies style if present.
  Future<void> generate(
    String userPrompt, {
    String? imageStyleId,
    String? backgroundColor,
  }) async {
    if (!EnvConfig.hasGeminiApiKey) {
      error.value =
          'No Gemini API key configured. '
          'Set GOOGLE_AI_API_KEY via --dart-define or .env file.';
      return;
    }

    isGenerating.value = true;
    error.value = null;
    phase.value = GenerationPhase.generatingOutline;
    imageProgress.value = null;
    prompt.value = userPrompt;

    try {
      final service = DeckGeneratorService(apiKey: EnvConfig.geminiApiKey);

      final result = await service.generate(
        userPrompt,
        imageStyleId: imageStyleId,
        backgroundColor: backgroundColor,
        onProgress: _onProgress,
      );

      if (!result.success) {
        error.value = result.error ?? 'Unknown generation error.';
        return;
      }

      // Write image bytes to the in-memory asset cache.
      for (final entry in result.images.entries) {
        await _assetCacheStore.write(entry.key, entry.value);
        debugLog.log('AI_STORE', 'Cached image: ${entry.key}');
      }

      // Serialize slides to markdown and push to editor + loader.
      final markdown = const SlideSerializer().serialize(result.slides);
      _textEditorController.loadMarkdown(markdown);
      _deckLoader.updateMarkdown(markdown);
      debugLog.log(
        'AI_STORE',
        'Loaded ${result.slides.length} slides into editor.',
      );

      // Apply AI style to customization store if provided.
      if (result.style != null) {
        _customizationStore.applyFromAiStyle(result.style!);
        debugLog.log('AI_STORE', 'Applied AI style to customization store.');
      }
    } catch (e, stack) {
      debugLog.error('AI_STORE', 'Unexpected error during generation', stack);
      error.value = 'An unexpected error occurred: $e';
    } finally {
      isGenerating.value = false;
      phase.value = GenerationPhase.idle;
    }
  }

  void _onProgress(
    GenerationPhase newPhase,
    ImageGenerationProgress? progress,
  ) {
    phase.value = newPhase;
    if (progress != null) {
      imageProgress.value = progress;
    }
  }

  void dispose() {
    isGenerating.dispose();
    phase.dispose();
    prompt.dispose();
    error.dispose();
    imageProgress.dispose();
  }
}

