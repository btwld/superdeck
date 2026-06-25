import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:playground/features/ai/core/ai/catalog/catalog.dart';
import 'package:playground/features/ai/core/ai/wizard_context.dart';
import 'package:playground/features/ai/core/ai/services/deck_generator_service.dart';
import 'package:playground/features/ai/core/ai/services/generation_progress.dart';
import 'package:playground/features/ai/core/ai/services/genui_conversation_viewmodel.dart';
import 'package:playground/features/ai/core/ai/services/prompt_builder.dart';
import 'package:playground/features/ai/core/env_config.dart';
import 'package:playground/features/ai/core/constants/paths.dart';
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

    // Save generation metadata before starting pipeline so regeneration
    // works even if this attempt fails.
    await _saveGenerationMetadata(prompt, imageStyleId, backgroundColor);

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

  /// Regenerates presentation from the last saved prompt and parameters.
  Future<DeckGenerationResult> regenerateFromLastPrompt(
    GenerationProgressCallback? onProgress, {
    bool Function()? isCancelled,
  }) async {
    final service = DeckGeneratorService(apiKey: EnvConfig.geminiApiKey);
    return service.regenerateFromLastPrompt(
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }

  /// Persists generation parameters so regeneration works even after failure.
  Future<void> _saveGenerationMetadata(
    String prompt,
    String? imageStyleId,
    String? backgroundColor,
  ) async {
    if (kIsWeb) {
      debugLog.log(
        'GEN',
        'Skipping local metadata persistence on web runtime.',
      );
      return;
    }

    try {
      final metadata = <String, dynamic>{
        'prompt': prompt,
        if (imageStyleId case final styleId?) 'imageStyleId': styleId,
        if (backgroundColor case final bgColor?) 'backgroundColor': bgColor,
      };
      await Directory(Paths.superdeckDir).create(recursive: true);
      final metadataFile = File(Paths.lastGenerationPath);
      await metadataFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
      );
      // Also save plain prompt for human readability
      await File(Paths.lastPromptPath).writeAsString(prompt);
    } catch (e) {
      debugLog.log(
        'GEN',
        'Failed to save generation metadata '
            '(${Paths.lastGenerationPath}, ${Paths.lastPromptPath}): $e',
      );
    }
  }
}
