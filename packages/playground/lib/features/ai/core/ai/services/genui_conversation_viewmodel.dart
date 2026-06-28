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
  Future<bool>? _startingConversation;
  Future<void> _requestQueue = Future<void>.value();
  String _streamingAiResponse = '';
  int? _streamingAiMessageIndex;
  var _sessionEpoch = 0;
  var _disposed = false;

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

  Future<bool> buildConversation() {
    if (_disposed) return Future.value(false);
    if (_controller.value != null) return Future.value(true);

    final starting = _startingConversation;
    if (starting != null) return starting;

    late final Future<bool> future;
    future = _buildConversation().whenComplete(() {
      if (identical(_startingConversation, future)) {
        _startingConversation = null;
      }
    });
    _startingConversation = future;
    return future;
  }

  Future<bool> _buildConversation() async {
    final epoch = _sessionEpoch;

    final apiKey = _readApiKey();
    if (apiKey == null) return false;

    try {
      final systemInstruction = await _loadSystemInstruction(epoch);
      if (systemInstruction == null || !_isActiveEpoch(epoch)) return false;

      final controller = genui.SurfaceController(catalogs: [catalog]);
      final transport = _transportFactory(
        apiKey: apiKey,
        modelName: model.value.modelPath,
        systemPrompt: _buildSystemPrompt(systemInstruction),
        tools: _tools,
        agentClientFactory: _agentClientFactory,
      );

      if (!_isActiveEpoch(epoch)) {
        controller.dispose();
        transport.dispose();
        return false;
      }

      _bindSession(
        controller: controller,
        transport: transport,
        sessionEpoch: epoch,
      );
      _controller.value = controller;
      _transport.value = transport;
      return true;
    } catch (e, stack) {
      if (_isActiveEpoch(epoch)) {
        _disposeSession();
        debugLog.error('CONV', _sanitizeError(e), stack);
        _messages.add(
          const SuperdeckAiMessage(
            'Failed to initialize conversation. Please try again.',
          ),
        );
      }
      return false;
    }
  }

  void sendMessage(String raw) {
    final message = raw.trim();
    if (message.isEmpty) return;

    unawaited(_sendUserMessage(message));
  }

  Future<void> _sendUserMessage(String message) async {
    if (_disposed) return;

    debugLog.userAction('SEND_MESSAGE', {'message': message});
    debugLog.section('New Message');

    if (!hasConversationStarted.value) {
      debugLog.log('CONV', 'Building new conversation');
      final ok = await buildConversation();
      if (!ok) return;
    }

    if (!_hasActiveSession) return;

    _messages.add(SuperdeckUserMessage(message));
    await _enqueueRequest(genui.ChatMessage.user(message));
  }

  void restartConversation() {
    debugLog.section('Conversation Restarted');
    _disposeSession();
    _messages.value = [];
    surfaceIds.value = [];
  }

  @override
  void dispose() {
    _disposed = true;
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

  Future<String?> _loadSystemInstruction(int epoch) async {
    try {
      await PromptRegistry.instance.load();
      return PromptRegistry.instance.render(promptName);
    } on StateError catch (e) {
      if (_isActiveEpoch(epoch)) {
        debugLog.error('PROMPT', e.message);
        _messages.add(SuperdeckAiMessage(promptLoadErrorMessage));
      }
      return null;
    } catch (e, stack) {
      if (_isActiveEpoch(epoch)) {
        debugLog.error('PROMPT', _sanitizeError(e), stack);
        _messages.add(SuperdeckAiMessage(promptLoadErrorMessage));
      }
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
    required int sessionEpoch,
  }) {
    void handleError(Object error, StackTrace stack) {
      if (_isActiveEpoch(sessionEpoch)) {
        _handleTransportError(error, stack);
      }
    }

    _onSubmitSubscription = controller.onSubmit.listen((message) {
      if (_isActiveEpoch(sessionEpoch)) {
        _handleUiSubmit(message);
      }
    }, onError: handleError);
    _surfaceSubscription = controller.surfaceUpdates.listen((update) {
      if (_isActiveEpoch(sessionEpoch)) {
        _handleSurfaceUpdate(update);
      }
    }, onError: handleError);
    _a2uiMessageSubscription = transport.incomingMessages.listen((message) {
      if (_isActiveEpoch(sessionEpoch)) {
        controller.handleMessage(message);
      }
    }, onError: handleError);
    _textSubscription = transport.incomingText.listen((value) {
      if (_isActiveEpoch(sessionEpoch)) {
        _handleTextResponse(value);
      }
    }, onError: handleError);
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

    unawaited(_enqueueRequest(message));
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

  Future<void> _enqueueRequest(genui.ChatMessage message) {
    final epoch = _sessionEpoch;
    final queued = _requestQueue
        .catchError(_handleRequestQueueError)
        .then((_) => _sendRequest(message, sessionEpoch: epoch));
    _requestQueue = queued;
    return queued;
  }

  void _handleRequestQueueError(Object error, StackTrace stack) {
    if (_disposed) return;
    debugLog.error('GenUI queue', _sanitizeError(error), stack);
  }

  Future<void> _sendRequest(
    genui.ChatMessage message, {
    required int sessionEpoch,
  }) async {
    final transport = _transport.value;
    if (transport == null || !_isActiveEpoch(sessionEpoch)) return;

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
      if (!_isActiveEpoch(sessionEpoch)) return;
      debugLog.error('GenUI', _sanitizeError(e), stack);
      _messages.add(SuperdeckAiMessage(_getErrorMessage(e)));
    } finally {
      if (_isActiveEpoch(sessionEpoch)) {
        _isProcessing.value = false;
      }
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
    _sessionEpoch++;
    _startingConversation = null;
    _requestQueue = Future<void>.value();
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

  bool get _hasActiveSession {
    return !_disposed && _controller.value != null && _transport.value != null;
  }

  bool _isActiveEpoch(int epoch) {
    return !_disposed && epoch == _sessionEpoch;
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
