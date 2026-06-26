import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:signals/signals_flutter.dart';
import '../../../chat/chat_message.dart';
import '../../../chat/view/widgets/model_select.dart';
import '../prompts/prompt_registry.dart';
import 'error_classifier.dart';
import '../../debug_logger.dart';
import '../../env_config.dart';
import '../../viewmodel_scope.dart';

/// Builder for creating GenUI conversations.
///
/// Allows tests to inject a mock conversation without extra abstractions.
typedef GenUiConversationBuilder =
    GenUiConversation Function({
      required ContentGenerator contentGenerator,
      required A2uiMessageProcessor a2uiMessageProcessor,
      required ValueChanged<String>? onTextResponse,
      required ValueChanged<ContentGeneratorError>? onError,
      required ValueChanged<SurfaceAdded>? onSurfaceAdded,
      required ValueChanged<SurfaceUpdated>? onSurfaceUpdated,
      required ValueChanged<SurfaceRemoved>? onSurfaceDeleted,
    });

abstract class GenUiConversationViewModel implements Disposable {
  GenUiConversationViewModel({
    required this.catalog,
    required this.promptName,
    required this.promptLoadErrorMessage,
    Iterable<AiTool<Map<String, dynamic>>> additionalTools = const [],
    GenUiConversationBuilder? conversationBuilder,
  }) : _additionalTools = List.unmodifiable(additionalTools),
       _conversationBuilder = conversationBuilder ?? GenUiConversation.new;

  @protected
  final Catalog catalog;

  @protected
  final String promptName;

  @protected
  final String promptLoadErrorMessage;

  final GenUiConversationBuilder _conversationBuilder;
  final List<AiTool<Map<String, dynamic>>> _additionalTools;
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
    _isProcessingBridge.value = null;

    final apiKey = _readApiKey();
    if (apiKey == null) return false;

    try {
      final processor = A2uiMessageProcessor(catalogs: [catalog]);
      final systemInstruction = _loadSystemInstruction();
      if (systemInstruction == null) return false;

      final contentGenerator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        systemInstruction: systemInstruction,
        apiKey: apiKey,
        modelName: model.value.modelPath,
        additionalTools: _additionalTools,
      );

      _bindOnSubmit(processor);
      _conversation.value = _createConversation(
        processor: processor,
        contentGenerator: contentGenerator,
      );

      _isProcessingBridge.value = _conversation.value!.isProcessing.toSignal();
      return true;
    } catch (e, stack) {
      _onSubmitSubscription?.cancel();
      _onSubmitSubscription = null;
      debugLog.error('CONV', _sanitizeError(e), stack);
      _messages.add(
        const SuperdeckAiMessage(
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
        const SuperdeckAiMessage(
          'Unable to start conversation. Please check your API key configuration.',
        ),
      );
      return null;
    }
  }

  String? _loadSystemInstruction() {
    try {
      return PromptRegistry.instance.render(promptName);
    } on StateError catch (e) {
      debugLog.error('PROMPT', e.message);
      _messages.add(SuperdeckAiMessage(promptLoadErrorMessage));
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
    debugLog.error('GenUI', _sanitizeError(value.error));
    _messages.add(SuperdeckAiMessage(_getErrorMessage(value.error)));
  }

  void _handleSurfaceAdded(SurfaceAdded value) {
    _logElapsed('SURFACE_ADDED: ${value.surfaceId}');
    debugLog.surface('ADDED', value.surfaceId);
    if (!surfaceIds.value.contains(value.surfaceId)) {
      surfaceIds.value = [...surfaceIds.value, value.surfaceId];
      _addDebugMessage('Surface added: ${value.surfaceId}');
    }
  }

  void _handleSurfaceUpdated(SurfaceUpdated value) {
    _logElapsed('SURFACE_UPDATED: ${value.surfaceId}');
    debugLog.surface('UPDATED', value.surfaceId);
    if (!surfaceIds.value.contains(value.surfaceId)) {
      surfaceIds.value = [...surfaceIds.value, value.surfaceId];
      _addDebugMessage('Surface added via update: ${value.surfaceId}');
    }
    _addDebugMessage('Surface updated: ${value.surfaceId}');
  }

  void _handleSurfaceDeleted(SurfaceRemoved value) {
    _logElapsed('SURFACE_DELETED: ${value.surfaceId}');
    debugLog.surface('DELETED', value.surfaceId);
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
    return str.replaceAll(RegExp(r'[A-Za-z0-9_-]{20,}'), '[REDACTED]');
  }
}
