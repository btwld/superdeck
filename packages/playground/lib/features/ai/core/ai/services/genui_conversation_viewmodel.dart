import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' as genui;
import 'package:signals/signals_flutter.dart';

import '../../../chat/chat_message.dart';
import '../../../chat/view/widgets/model_select.dart';
import '../../debug_logger.dart';
import '../../env_config.dart';
import '../../viewmodel_scope.dart';
import '../prompts/prompt_registry.dart';
import 'error_classifier.dart';
import 'superdeck_a2ui_transport.dart';
import 'superdeck_agent_client.dart';

abstract class GenUiConversationViewModel implements Disposable {
  GenUiConversationViewModel({
    required this.catalog,
    required this.promptName,
    required this.promptLoadErrorMessage,
    Iterable<dartantic.Tool> tools = const [],
    SuperdeckTransportFactory? transportFactory,
    SuperdeckAgentClientFactory agentClientFactory =
        DartanticSuperdeckAgentClient.new,
  }) : _tools = List.unmodifiable(tools),
       _transportFactory = transportFactory ?? SuperdeckA2uiTransport.new,
       _agentClientFactory = agentClientFactory;

  @protected
  final genui.Catalog catalog;

  @protected
  final String promptName;

  @protected
  final String promptLoadErrorMessage;

  final List<dartantic.Tool> _tools;
  final SuperdeckTransportFactory _transportFactory;
  final SuperdeckAgentClientFactory _agentClientFactory;
  final model = Signal<GeminiModels>(GeminiModels.defaultValue);
  final surfaceIds = Signal<List<String>>([]);
  final _controller = Signal<genui.SurfaceController?>(null);
  final _transport = Signal<SuperdeckA2uiTransport?>(null);
  final debugMode = Signal<bool>(false);
  final showChat = Signal<bool>(true);
  final Signal<List<SuperdeckChatMessage>> _messages = signal([]);
  final _isProcessing = Signal<bool>(false);

  StreamSubscription<genui.ChatMessage>? _onSubmitSubscription;
  StreamSubscription<genui.SurfaceUpdate>? _surfaceSubscription;
  StreamSubscription<genui.A2uiMessage>? _a2uiMessageSubscription;
  StreamSubscription<String>? _textSubscription;

  DateTime? _lastRequestTime;
  String _streamingAiResponse = '';
  int? _streamingAiMessageIndex;

  genui.SurfaceController? get controller => _controller.value;

  late final Computed<bool> isThinking = computed(() {
    return _isProcessing.value;
  });

  late final Computed<List<SuperdeckChatMessage>> messages = computed(() {
    if (debugMode.value) {
      return _messages.value;
    }

    return _messages.value.where((e) {
      return e is SuperdeckUserMessage || e is SuperdeckAiMessage;
    }).toList();
  });

  late final Computed<bool> hasConversationStarted = computed(
    () => _controller.value != null,
  );

  bool buildConversation() {
    if (_controller.value != null) return true;

    final apiKey = _readApiKey();
    if (apiKey == null) return false;

    try {
      final systemInstruction = _loadSystemInstruction();
      if (systemInstruction == null) return false;

      final controller = genui.SurfaceController(catalogs: [catalog]);
      final transport = _transportFactory(
        apiKey: apiKey,
        modelName: model.value.modelPath,
        systemPrompt: _buildSystemPrompt(systemInstruction),
        tools: _tools,
        agentClientFactory: _agentClientFactory,
      );

      _bindSession(controller: controller, transport: transport);
      _controller.value = controller;
      _transport.value = transport;
      return true;
    } catch (e, stack) {
      _disposeSession();
      debugLog.error('CONV', _sanitizeError(e), stack);
      _messages.add(
        const SuperdeckAiMessage(
          'Failed to initialize conversation. Please try again.',
        ),
      );
      return false;
    }
  }

  void sendMessage(String raw) {
    final message = raw.trim();
    if (message.isEmpty) return;

    debugLog.userAction('SEND_MESSAGE', {'message': message});
    debugLog.section('New Message');

    if (!hasConversationStarted.value) {
      debugLog.log('CONV', 'Building new conversation');
      final ok = buildConversation();
      if (!ok) return;
    }

    _messages.add(SuperdeckUserMessage(message));
    unawaited(_sendRequest(genui.ChatMessage.user(message)));
  }

  void restartConversation() {
    debugLog.section('Conversation Restarted');
    _disposeSession();
    _messages.value = [];
    surfaceIds.value = [];
  }

  @override
  void dispose() {
    _disposeSession();

    model.dispose();
    surfaceIds.dispose();
    _controller.dispose();
    _transport.dispose();
    debugMode.dispose();
    showChat.dispose();
    _messages.dispose();
    _isProcessing.dispose();
    isThinking.dispose();
    messages.dispose();
    hasConversationStarted.dispose();
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

  String _buildSystemPrompt(String systemInstruction) {
    final fragments = [
      systemInstruction,
      genui.PromptFragments.acknowledgeUser(),
      genui.PromptFragments.requireAtLeastOneSubmitElement(
        prefix: genui.PromptBuilder.defaultImportancePrefix,
      ),
      genui.PromptFragments.uiGenerationRestriction(
        prefix: genui.PromptBuilder.defaultImportancePrefix,
      ),
    ];

    if (_tools.isEmpty) {
      return genui.PromptBuilder.chat(
        catalog: catalog,
        systemPromptFragments: fragments,
      ).systemPromptJoined();
    }

    return genui.PromptBuilder.custom(
      catalog: catalog,
      allowedOperations: genui.SurfaceOperations.createOnly(dataModel: false),
      systemPromptFragments: fragments,
      technicalPossibilities: const genui.TechnicalPossibilities(
        toolCall: true,
      ),
    ).systemPromptJoined();
  }

  void _bindSession({
    required genui.SurfaceController controller,
    required SuperdeckA2uiTransport transport,
  }) {
    _onSubmitSubscription = controller.onSubmit.listen(
      _handleUiSubmit,
      onError: _handleTransportError,
    );
    _surfaceSubscription = controller.surfaceUpdates.listen(
      _handleSurfaceUpdate,
      onError: _handleTransportError,
    );
    _a2uiMessageSubscription = transport.incomingMessages.listen(
      controller.handleMessage,
      onError: _handleTransportError,
    );
    _textSubscription = transport.incomingText.listen(
      _handleTextResponse,
      onError: _handleTransportError,
    );
  }

  void _handleUiSubmit(genui.ChatMessage message) {
    final interactionParts = message.parts.uiInteractionParts.toList();
    if (interactionParts.isEmpty) {
      debugLog.log('USER', 'Received submit message without interaction part');
      _addDebugMessage('Received unexpected action format');
    }

    for (final part in interactionParts) {
      final rawJson = part.interaction;
      final parsed = UserActionPayload.tryParse(rawJson);
      if (parsed == null) {
        debugLog.log('USER', 'Failed to parse user action: $rawJson');
        _addDebugMessage('Received unexpected action format');
      } else {
        _messages.add(SuperdeckUserMessage(parsed.displayMessage));
      }
      _addJsonDebugMessage(rawJson);
      debugLog.userAction('UI_ACTION', parsed?.context ?? {'raw': rawJson});
    }

    unawaited(_sendRequest(message));
  }

  void _handleTextResponse(String value) {
    _logElapsed('TEXT_RESPONSE received');
    debugLog.aiResponse('TEXT', value);
    _streamingAiResponse += value;

    final next = [..._messages.value];
    final index = _streamingAiMessageIndex;
    if (index != null &&
        index >= 0 &&
        index < next.length &&
        next[index] is SuperdeckAiMessage) {
      next[index] = SuperdeckAiMessage(_streamingAiResponse);
    } else {
      _streamingAiMessageIndex = next.length;
      next.add(SuperdeckAiMessage(_streamingAiResponse));
    }
    _messages.value = next;
  }

  void _handleSurfaceUpdate(genui.SurfaceUpdate value) {
    switch (value) {
      case genui.SurfaceAdded(:final surfaceId):
        _handleSurfaceAdded(surfaceId);
      case genui.ComponentsUpdated(:final surfaceId):
        _handleSurfaceUpdated(surfaceId);
      case genui.SurfaceRemoved(:final surfaceId):
        _handleSurfaceDeleted(surfaceId);
    }
  }

  void _handleSurfaceAdded(String surfaceId) {
    _logElapsed('SURFACE_ADDED: $surfaceId');
    debugLog.surface('ADDED', surfaceId);
    if (!surfaceIds.value.contains(surfaceId)) {
      surfaceIds.value = [...surfaceIds.value, surfaceId];
      _addDebugMessage('Surface added: $surfaceId');
    }
  }

  void _handleSurfaceUpdated(String surfaceId) {
    _logElapsed('SURFACE_UPDATED: $surfaceId');
    debugLog.surface('UPDATED', surfaceId);
    if (!surfaceIds.value.contains(surfaceId)) {
      surfaceIds.value = [...surfaceIds.value, surfaceId];
      _addDebugMessage('Surface added via update: $surfaceId');
    }
    _addDebugMessage('Surface updated: $surfaceId');
  }

  void _handleSurfaceDeleted(String surfaceId) {
    _logElapsed('SURFACE_DELETED: $surfaceId');
    debugLog.surface('DELETED', surfaceId);
    surfaceIds.value = surfaceIds.value.where((id) => id != surfaceId).toList();
    _addDebugMessage('Surface deleted: $surfaceId');
  }

  Future<void> _sendRequest(genui.ChatMessage message) async {
    final transport = _transport.value;
    if (transport == null) return;

    _lastRequestTime = DateTime.now();
    _streamingAiResponse = '';
    _streamingAiMessageIndex = null;
    _isProcessing.value = true;
    debugLog.log(
      'TIMING',
      'Request started at ${_lastRequestTime!.toIso8601String()}',
    );

    try {
      await transport.sendRequest(message);
    } catch (e, stack) {
      debugLog.error('GenUI', _sanitizeError(e), stack);
      _messages.add(SuperdeckAiMessage(_getErrorMessage(e)));
    } finally {
      _isProcessing.value = false;
    }
  }

  void _handleTransportError(Object error, StackTrace stack) {
    _logElapsed('ERROR received');
    debugLog.error('GenUI', _sanitizeError(error), stack);
    _messages.add(SuperdeckAiMessage(_getErrorMessage(error)));
    _isProcessing.value = false;
    _streamingAiMessageIndex = null;
  }

  void _disposeSession() {
    unawaited(_onSubmitSubscription?.cancel());
    unawaited(_surfaceSubscription?.cancel());
    unawaited(_a2uiMessageSubscription?.cancel());
    unawaited(_textSubscription?.cancel());
    _onSubmitSubscription = null;
    _surfaceSubscription = null;
    _a2uiMessageSubscription = null;
    _textSubscription = null;

    _controller.value?.dispose();
    _controller.value = null;
    _transport.value?.dispose();
    _transport.value = null;
    _isProcessing.value = false;
    _streamingAiResponse = '';
    _streamingAiMessageIndex = null;
  }

  void _logElapsed(String event) {
    if (_lastRequestTime == null) return;
    final elapsed = DateTime.now().difference(_lastRequestTime!);
    debugLog.log('TIMING', '$event at +${elapsed.inMilliseconds}ms');
  }

  void _addDebugMessage(String message) {
    _messages.add(SuperdeckDebugMessage(message));
  }

  void _addJsonDebugMessage(String json) {
    _messages.add(SuperdeckJsonDebugMessage(json));
  }

  static const _errorClassifier = ErrorClassifier();

  String _getErrorMessage(Object error) =>
      _errorClassifier.getUserMessage(error);

  String _sanitizeError(Object error) {
    final str = error.toString();
    return str.replaceAll(RegExp(r'[A-Za-z0-9_-]{20,}'), '[REDACTED]');
  }
}
