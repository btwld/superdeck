import '../../../../../core/command.dart';
import '../../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../../../core/data/data_sources/memory_asset_cache_store.dart';
import '../../../../../core/result.dart';
import '../../../../editor/domain/stores/deck_document_store.dart';
import '../../../../../core/domain/stores/deck_customization_store.dart';
import '../../core/debug_logger.dart';
import '../../core/engine/services/deck_generation_request.dart';
import '../../core/engine/services/deck_generator_service.dart';
import '../../core/engine/services/generation_progress.dart';
import '../../core/env_config.dart';
import '../generated_deck_result_applier.dart';

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
  final GeneratedDeckResultApplier _resultApplier;

  final DeckGeneratorService? _service;
  GenerationProgress _progress = const GenerationProgress(GenerationPhase.idle);

  String? _completionNotice;
  bool _cancelled = false;
  bool _disposed = false;
  GenerateDeckCommand({
    required DeckDocumentStore documentStore,
    required DeckCustomizationStore customizationStore,
    MemoryDeckLoader? deckLoader,
    MemoryAssetCacheStore? assetCacheStore,
    DeckGeneratorService? service,
  }) : _resultApplier = GeneratedDeckResultApplier(
         documentStore: documentStore,
         deckLoader: deckLoader,
         assetCacheStore: assetCacheStore,
         customizationStore: customizationStore,
       ),
       _service = service;

  void _onProgress(GenerationProgress progress) {
    if (_cancelled) return;
    _progress = progress;
    notifyListeners();
  }

  /// The pipeline stage currently running (outline → deck).
  GenerationPhase get phase => _progress.phase;

  GenerationProgress get progress => _progress;

  /// Non-blocking detail for a completed partial generation.
  String? get completionNotice => _completionNotice;

  @override
  Future<Result<void>> action(DeckGenerationRequest request) async {
    if (_service == null && !EnvConfig.hasGeminiApiKey) {
      return const Result.error(
        GenerationException(
          'No Gemini API key configured. '
          'Set GOOGLE_AI_API_KEY via --dart-define.',
        ),
      );
    }

    _cancelled = false;
    _completionNotice = null;
    _progress = const GenerationProgress(GenerationPhase.generatingOutline);
    notifyListeners();

    try {
      final service =
          _service ?? DeckGeneratorService(apiKey: EnvConfig.geminiApiKey);
      final result = await service.generate(
        request,
        onProgress: _onProgress,
        isCancelled: () => _cancelled,
      );

      if (!result.success && !result.isPartial) {
        return Result.error(
          GenerationException(result.error ?? 'Unknown generation error.'),
        );
      }
      if (result.slides.isEmpty) {
        return const Result.error(
          GenerationException('No slides were generated. Please try again.'),
        );
      }
      if (_cancelled) {
        return const Result.error(GenerationException('Generation cancelled.'));
      }

      await _resultApplier.apply(result);
      if (result.isPartial) {
        _completionNotice = result.error;
      } else if (result.hasImageFailures) {
        _completionNotice =
            'Created ${result.generatedImageCount} of '
            '${result.generatedImages.length} planned artworks; '
            '${result.failedImageCount} used a text-first fallback.';
      }
      debugLog.log(
        'GENERATE_DECK',
        'Loaded ${result.slides.length} slides into editor'
            '${result.isPartial ? ' with ${result.slideFailures.length} unresolved' : ''}.',
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

  @override
  void clearResult() {
    _completionNotice = null;
    super.clearResult();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _cancelled = true;
    _disposed = true;
    super.dispose();
  }
}
