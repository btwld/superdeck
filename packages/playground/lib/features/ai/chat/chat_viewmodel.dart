import 'package:flutter/foundation.dart';
import 'package:playground/features/ai/core/ai/catalog/catalog.dart';
import 'package:playground/features/ai/core/ai/wizard_context.dart';
import 'package:playground/features/ai/core/ai/services/deck_generator_service.dart';
import 'package:playground/features/ai/core/ai/services/generation_progress.dart';
import 'package:playground/features/ai/core/ai/services/genui_conversation_viewmodel.dart';
import 'package:playground/features/ai/core/ai/services/prompt_builder.dart';
import 'package:playground/features/ai/core/env_config.dart';
import 'package:playground/features/ai/core/debug_logger.dart';

// Re-export message types for consumers of ChatViewModel.
export 'package:playground/features/ai/chat/chat_message.dart';

class ChatViewModel extends GenUiConversationViewModel {
  /// Creates a ChatViewModel with optional dependency injection for testing.
  ///
  /// [conversationBuilder] - Builder for creating conversations. Defaults to
  /// [GenUiConversation.new] which creates real GenUI conversations.
  ChatViewModel({@visibleForTesting super.conversationBuilder})
    : super(
        catalog: chatCatalog,
        promptName: 'wizard_system',
        promptLoadErrorMessage:
            'Unable to load conversation prompts. Please restart the app.',
      );

  // In-memory storage of last generation params (no disk).
  String? _lastPrompt;
  String? _lastImageStyleId;
  String? _lastBackgroundColor;

  /// Generates presentation directly from wizard context.
  ///
  /// This bypasses the GenUI AI tool flow and calls DeckGeneratorService directly.
  /// Progress updates are reported via [onProgress] if provided.
  Future<DeckGenerationResult> generateFromContext(
    WizardContext context,
    GenerationProgressCallback? onProgress, {
    bool Function()? isCancelled,
  }) async {
    debugLog.log(
      'GEN',
      'generateFromContext called with context: ${context.toMap()}',
    );
    final prompt = buildPromptFromWizardContext(context);
    debugLog.log('GEN', 'Built prompt:\n$prompt');
    // Uses Pro with thinking by default for better quality generation
    final service = DeckGeneratorService(apiKey: EnvConfig.geminiApiKey);
    debugLog.log('GEN', 'Calling DeckGeneratorService.generate()...');
    final imageStyleId = context.imageStyleId;
    final backgroundColor = context.colors?.firstOrNull;

    // Store generation metadata in-memory for potential regeneration.
    _lastPrompt = prompt;
    _lastImageStyleId = imageStyleId;
    _lastBackgroundColor = backgroundColor;

    final result = await service.generate(
      prompt,
      imageStyleId: imageStyleId,
      backgroundColor: backgroundColor,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
    debugLog.log('GEN', 'Generation result - success: ${result.success}');
    return result;
  }

  /// Regenerates presentation from the last in-memory prompt and parameters.
  Future<DeckGenerationResult> regenerateFromLastPrompt(
    GenerationProgressCallback? onProgress, {
    bool Function()? isCancelled,
  }) async {
    final prompt = _lastPrompt;
    if (prompt == null || prompt.trim().isEmpty) {
      return DeckGenerationResult.failure(
        'No previous prompt found. Complete the wizard at least once.',
      );
    }

    final service = DeckGeneratorService(apiKey: EnvConfig.geminiApiKey);
    return service.generate(
      prompt,
      imageStyleId: _lastImageStyleId,
      backgroundColor: _lastBackgroundColor,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }
}
