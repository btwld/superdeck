import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck_ai/chat/chat_message.dart';
import 'package:superdeck_ai/chat/view/widgets/model_select.dart';
import 'package:superdeck_ai/core/ai/catalog/catalog.dart';
import 'package:superdeck_ai/core/ai/wizard_context.dart';
import 'package:superdeck_ai/core/ai/prompts/prompt_registry.dart';
import 'package:superdeck_ai/core/ai/services/deck_generator_service.dart';
import 'package:superdeck_ai/core/ai/services/error_classifier.dart';
import 'package:superdeck_ai/core/ai/services/generation_progress.dart';
import 'package:superdeck_ai/core/ai/services/prompt_builder.dart';
import 'package:superdeck_ai/core/env_config.dart';
import 'package:superdeck_ai/core/constants/paths.dart';
import 'package:superdeck_ai/core/viewmodel_scope.dart';
import 'package:superdeck_ai/core/debug_logger.dart';

// Re-export message types for consumers of ChatViewModel
export 'package:superdeck_ai/chat/chat_message.dart';

/// Builder for creating GenUI conversations.
///
/// Allows tests to inject a mock conversation without extra abstractions.
typedef ConversationBuilder =
    GenUiConversation Function({
      required ContentGenerator contentGenerator,
      required A2uiMessageProcessor a2uiMessageProcessor,
      required ValueChanged<String>? onTextResponse,
      required ValueChanged<ContentGeneratorError>? onError,
      required ValueChanged<SurfaceAdded>? onSurfaceAdded,
      required ValueChanged<SurfaceUpdated>? onSurfaceUpdated,
      required ValueChanged<SurfaceRemoved>? onSurfaceDeleted,
    });

class ChatViewModel implements Disposable {
  /// Creates a ChatViewModel with optional dependency injection for testing.
  ///
  /// [conversationBuilder] - Builder for creating conversations. Defaults to
  /// [GenUiConversation.new] which creates real GenUI conversations.
  ChatViewModel({@visibleForTesting ConversationBuilder? conversationBuilder})
    : _conversationBuilder = conversationBuilder ?? GenUiConversation.new;

  final ConversationBuilder _conversationBuilder;
  final model = Signal<GeminiModels>(GeminiModels.defaultValue);
  final surfaceIds = Signal<List<String>>([]);
  final _conversation = Signal<GenUiConversation?>(null);
  final debugMode = Signal<bool>(false);
  final showChat = Signal<bool>(true);
  final Signal<List<SuperdeckChatMessage>> _messages = signal([]);

  /// Signal holding the isProcessing bridge from the current conversation.
  final _isProcessingBridge = Signal<ReadonlySignal<bool>?>(null);

  /// Subscription for user action events from the message processor.
  StreamSubscription<UserUiInteractionMessage>? _onSubmitSubscription;

  GenUiHost? get host => _conversation.value?.host;
  A2uiMessageProcessor? get processor =>
      _conversation.value?.a2uiMessageProcessor;

  /// Whether the AI is currently processing a response.
  late final Computed<bool> isThinking = computed(() {
    return _isProcessingBridge.value?.value ?? false;
  });

  /// Filtered messages based on debug mode.
  late final Computed<List<SuperdeckChatMessage>> messages = computed(() {
    if (debugMode.value) {
      return _messages.value;
    }

    return _messages.value.where((e) {
      return e is SuperdeckUserMessage || e is SuperdeckAiMessage;
    }).toList();
  });

  /// Whether a conversation has been successfully initialized.
  ///
  /// Derived from conversation existence, not message history, so that
  /// error messages (e.g., missing API key) don't lock model selection.
  late final Computed<bool> hasConversationStarted = computed(
    () => _conversation.value != null,
  );

  /// Initializes a new GenUI conversation.
  ///
  /// Returns true if conversation was successfully created, false otherwise.
  bool buildConversation() {
    // Reset bridge when building new conversation
    _isProcessingBridge.value = null;

    final apiKey = _readApiKey();
    if (apiKey == null) return false;

    try {
      final processor = A2uiMessageProcessor(catalogs: [chatCatalog]);
      final systemInstruction = _loadSystemInstruction();
      if (systemInstruction == null) return false;

      final contentGenerator = GoogleGenerativeAiContentGenerator(
        catalog: chatCatalog,
        systemInstruction: systemInstruction,
        apiKey: apiKey,
        modelName: model.value.modelPath,
        additionalTools: [],
      );

      _bindOnSubmit(processor);
      _conversation.value = _createConversation(
        processor: processor,
        contentGenerator: contentGenerator,
      );

      // Set the signal bridge for isProcessing
      _isProcessingBridge.value = _conversation.value!.isProcessing.toSignal();
      return true;
    } catch (e, stack) {
      debugLog.error('CONV', _sanitizeError(e), stack);
      _messages.add(
        SuperdeckAiMessage(
          'Failed to initialize conversation. Please try again.',
        ),
      );
      return false;
    }
  }

  String? _readApiKey() {
    try {
      return EnvConfig.geminiApiKey;
    } on StateError {
      _messages.add(
        SuperdeckAiMessage(
          'Unable to start conversation. Please check your API key configuration.',
        ),
      );
      return null;
    }
  }

  String? _loadSystemInstruction() {
    try {
      return PromptRegistry.instance.render('wizard_system');
    } on StateError catch (e) {
      debugLog.error('PROMPT', e.message);
      _messages.add(
        SuperdeckAiMessage(
          'Unable to load conversation prompts. Please restart the app.',
        ),
      );
      return null;
    }
  }

  void _bindOnSubmit(A2uiMessageProcessor processor) {
    _onSubmitSubscription = processor.onSubmit.listen((message) {
      final parsed = UserActionPayload.tryParse(message.text);
      if (parsed == null) {
        debugLog.log('USER', 'Failed to parse user action: ${message.text}');
        _addDebugMessage('Received unexpected action format');
        return;
      }
      _messages.add(SuperdeckUserMessage(parsed.displayMessage));
      _addJsonDebugMessage(message.text);
    });
  }

  GenUiConversation _createConversation({
    required ContentGenerator contentGenerator,
    required A2uiMessageProcessor processor,
  }) {
    return _conversationBuilder(
      contentGenerator: contentGenerator,
      a2uiMessageProcessor: processor,
      onTextResponse: _handleTextResponse,
      onError: _handleConversationError,
      onSurfaceAdded: _handleSurfaceAdded,
      onSurfaceUpdated: _handleSurfaceUpdated,
      onSurfaceDeleted: _handleSurfaceDeleted,
    );
  }

  void _handleTextResponse(String value) {
    _logElapsed('TEXT_RESPONSE received');
    debugLog.aiResponse('TEXT', value);
    _messages.add(SuperdeckAiMessage(value));
  }

  void _handleConversationError(ContentGeneratorError value) {
    _logElapsed('ERROR received');
    // Log sanitized error to avoid exposing API keys
    debugLog.error('GenUI', _sanitizeError(value.error));
    _messages.add(SuperdeckAiMessage(_getErrorMessage(value.error)));
  }

  void _handleSurfaceAdded(SurfaceAdded value) {
    _logElapsed('SURFACE_ADDED: ${value.surfaceId}');
    debugLog.surface('ADDED', value.surfaceId);
    // Only add if not already present (prevent duplicate keys)
    if (!surfaceIds.value.contains(value.surfaceId)) {
      surfaceIds.value = [...surfaceIds.value, value.surfaceId];
      _addDebugMessage('Surface added: ${value.surfaceId}');
    }
  }

  void _handleSurfaceUpdated(SurfaceUpdated value) {
    _logElapsed('SURFACE_UPDATED: ${value.surfaceId}');
    debugLog.surface('UPDATED', value.surfaceId);
    // Add surface if missing (handles race conditions or reused IDs)
    if (!surfaceIds.value.contains(value.surfaceId)) {
      surfaceIds.value = [...surfaceIds.value, value.surfaceId];
      _addDebugMessage('Surface added via update: ${value.surfaceId}');
    }
    _addDebugMessage('Surface updated: ${value.surfaceId}');
    // GenUiSurface handles per-surface updates via internal ValueNotifier
  }

  void _handleSurfaceDeleted(SurfaceRemoved value) {
    _logElapsed('SURFACE_DELETED: ${value.surfaceId}');
    debugLog.surface('DELETED', value.surfaceId);
    // Use value assignment for reactivity (not .remove() which mutates)
    surfaceIds.value = surfaceIds.value
        .where((id) => id != value.surfaceId)
        .toList();
    _addDebugMessage('Surface deleted: ${value.surfaceId}');
  }

  /// Tracks when the last request was sent for latency measurement.
  DateTime? _lastRequestTime;

  void sendMessage(String raw) {
    final message = raw.trim();
    if (message.isEmpty) return;

    _lastRequestTime = DateTime.now();
    debugLog.userAction('SEND_MESSAGE', {'message': message});
    debugLog.section('New Message');
    debugLog.log(
      'TIMING',
      'Request started at ${_lastRequestTime!.toIso8601String()}',
    );

    // Build conversation if not started; abort if initialization fails
    if (!hasConversationStarted.value) {
      debugLog.log('CONV', 'Building new conversation');
      final ok = buildConversation();
      if (!ok) return;
    }

    _messages.add(SuperdeckUserMessage(message));
    _conversation.value?.sendRequest(UserMessage.text(message));
  }

  /// Logs elapsed time since request started.
  void _logElapsed(String event) {
    if (_lastRequestTime == null) return;
    final elapsed = DateTime.now().difference(_lastRequestTime!);
    debugLog.log('TIMING', '$event at +${elapsed.inMilliseconds}ms');
  }

  void restartConversation() {
    debugLog.section('Conversation Restarted');
    _onSubmitSubscription?.cancel();
    _onSubmitSubscription = null;
    _conversation.value?.dispose();
    _conversation.value = null;
    _isProcessingBridge.value = null;

    _messages.clear();
    surfaceIds.clear();
  }

  @override
  void dispose() {
    _onSubmitSubscription?.cancel();
    _onSubmitSubscription = null;
    _conversation.value?.dispose();

    // Dispose signals and computeds
    model.dispose();
    surfaceIds.dispose();
    _conversation.dispose();
    debugMode.dispose();
    showChat.dispose();
    _messages.dispose();
    _isProcessingBridge.dispose();
    isThinking.dispose();
    messages.dispose();
    hasConversationStarted.dispose();
  }

  /// Generates presentation directly from wizard context.
  ///
  /// This bypasses the GenUI AI tool flow and calls DeckGeneratorService directly.
  /// Progress updates are reported via [onProgress] if provided.
  Future<DeckGenerationResult> generateFromContext(
    WizardContext context,
    GenerationProgressCallback? onProgress,
  ) async {
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
    );
    debugLog.log('GEN', 'Generation result - success: ${result.success}');
    return result;
  }

  /// Regenerates presentation from the last saved prompt and parameters.
  Future<DeckGenerationResult> regenerateFromLastPrompt(
    GenerationProgressCallback? onProgress,
  ) async {
    final service = DeckGeneratorService(apiKey: EnvConfig.geminiApiKey);
    return service.regenerateFromLastPrompt(onProgress: onProgress);
  }

  /// Persists generation parameters so regeneration works even after failure.
  Future<void> _saveGenerationMetadata(
    String prompt,
    String? imageStyleId,
    String? backgroundColor,
  ) async {
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

  void _addDebugMessage(String message) {
    _messages.add(SuperdeckDebugMessage(message));
  }

  void _addJsonDebugMessage(String json) {
    _messages.add(SuperdeckJsonDebugMessage(json));
  }

  /// Error classifier for converting errors to user-friendly messages.
  static const _errorClassifier = ErrorClassifier();

  /// Maps error objects to user-friendly messages based on error type/content.
  String _getErrorMessage(Object error) =>
      _errorClassifier.getUserMessage(error);

  /// Sanitizes error messages to avoid exposing API keys in logs.
  ///
  /// Redacts any string that looks like an API key (long alphanumeric tokens).
  String _sanitizeError(Object error) {
    final str = error.toString();
    // Redact long alphanumeric tokens (potential API keys)
    return str.replaceAll(RegExp(r'[A-Za-z0-9_-]{20,}'), '[REDACTED]');
  }
}
