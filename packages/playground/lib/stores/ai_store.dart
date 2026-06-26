import 'package:signals/signals_flutter.dart';
import 'package:superdeck_builder/superdeck_builder.dart';

import '../features/ai/core/ai/services/deck_generator_service.dart';
import '../features/ai/core/ai/services/generation_progress.dart';
import '../features/ai/core/debug_logger.dart';
import '../features/ai/core/env_config.dart';
import '../utils/memory_asset_cache_store.dart';
import '../utils/memory_deck_loader.dart';
import '../utils/text_editor_controller.dart';
import 'deck_customization_store.dart';

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
    // Ignore re-entrant calls (e.g. a double-tap) so concurrent runs can't
    // interleave their writes to the shared asset cache / editor / loader.
    if (isGenerating.value) return;

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

      if (result.slides.isEmpty) {
        error.value = 'No slides were generated. Please try again.';
        return;
      }

      // Write image bytes to the in-memory asset cache, capturing the data:
      // URI each one resolves to.
      final imageUris = <String, String>{};
      for (final entry in result.images.entries) {
        final uri = await _assetCacheStore.write(entry.key, entry.value);
        if (uri != null) imageUris[entry.key] = uri.toString();
        debugLog.log('AI_STORE', 'Cached image: ${entry.key}');
      }

      // Serialize slides to markdown. The markdown image renderer does not
      // consult the in-memory asset cache, so inline the data: URIs in place of
      // the bare asset-key references the model emitted (e.g.
      // `slide-x-illustration.png`) so generated images actually render.
      var markdown = const SlideSerializer().serialize(result.slides);
      imageUris.forEach((key, uri) {
        markdown = markdown.replaceAll(key, uri);
      });

      // Push to editor + loader.
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

