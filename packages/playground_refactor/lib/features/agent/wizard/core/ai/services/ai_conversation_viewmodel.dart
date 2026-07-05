import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' as genui;
import 'package:signals/signals_flutter.dart';

import '../../../../core/constants/gemini_models.dart';
import '../../../chat/chat_message.dart';
import '../../debug_logger.dart';
import '../../viewmodel_scope.dart';
import 'ai_conversation_profile.dart';
import 'error_classifier.dart';
import 'genui_conversation_session.dart';
import 'superdeck_a2ui_transport.dart';
import 'superdeck_agent_client.dart';

final class AiConversationViewModel implements Disposable {
  AiConversationViewModel({
    required AiConversationProfile profile,
    @visibleForTesting SuperdeckTransportFactory? transportFactory,
    SuperdeckAgentClientFactory agentClientFactory =
        DartanticSuperdeckAgentClient.new,
  }) {
    _session = GenUiConversationSession(
      profile: profile,
      transportFactory: transportFactory,
      agentClientFactory: agentClientFactory,
      handlers: ConversationSessionHandlers(
        onRequestStarted: _handleRequestStarted,
        onRequestFinished: _handleRequestFinished,
        onUiSubmit: _handleUiSubmit,
        onSurfaceUpdate: _handleSurfaceUpdate,
        onTextResponse: _handleTextResponse,
        onError: _handleTransportError,
      ),
    );
  }

  /// Model is hardcoded for v1 (no in-wizard model picker — decision #5).
  static const _modelName = GeminiModelNames.gemini25Flash;

  final surfaceIds = Signal<List<String>>([]);
  final _controller = Signal<genui.SurfaceController?>(null);
  final debugMode = Signal<bool>(false);
  final showChat = Signal<bool>(true);
  final Signal<List<SuperdeckChatMessage>> _messages = signal([]);
  final _isProcessing = Signal<bool>(false);

  late final GenUiConversationSession _session;
  DateTime? _lastRequestTime;
  String _streamingAiResponse = '';
  int? _streamingAiMessageIndex;
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

  Future<bool> ensureConversationStarted() async {
    if (_disposed) return false;

    final result = await _session.ensureStarted(modelName: _modelName);
    if (result.started) {
      _controller.value = _session.controller;
      return true;
    }

    final message = result.message;
    if (message != null && !_disposed) {
      _messages.add(SuperdeckAiMessage(message));
    }
    return false;
  }

  Future<void> sendMessage(String raw) async {
    final message = raw.trim();
    if (message.isEmpty || _disposed) return;

    debugLog.userAction('SEND_MESSAGE', {'message': message});
    debugLog.section('New Message');

    if (!hasConversationStarted.value) {
      debugLog.log('CONV', 'Building new conversation');
      final ok = await ensureConversationStarted();
      if (!ok) return;
    }

    if (!_session.hasActiveSession) return;

    _messages.add(SuperdeckUserMessage(message));
    await _enqueueRequest(genui.ChatMessage.user(message));
  }

  void restartConversation() {
    debugLog.section('Conversation Restarted');
    _session.restart();
    _controller.value = null;
    _isProcessing.value = false;
    _streamingAiResponse = '';
    _streamingAiMessageIndex = null;
    _messages.value = [];
    surfaceIds.value = [];
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _session.dispose();

    surfaceIds.dispose();
    _controller.dispose();
    debugMode.dispose();
    showChat.dispose();
    _messages.dispose();
    _isProcessing.dispose();
    isThinking.dispose();
    messages.dispose();
    hasConversationStarted.dispose();
  }

  Future<void> _enqueueRequest(genui.ChatMessage message) {
    return _session.sendRequest(message);
  }

  void _handleRequestStarted() {
    _lastRequestTime = DateTime.now();
    _streamingAiResponse = '';
    _streamingAiMessageIndex = null;
    _isProcessing.value = true;
    debugLog.log(
      'TIMING',
      'Request started at ${_lastRequestTime!.toIso8601String()}',
    );
  }

  void _handleRequestFinished() {
    _isProcessing.value = false;
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

  void _handleTransportError(Object error, StackTrace stackTrace) {
    _logElapsed('ERROR received');
    debugLog.error('GenUI', _sanitizeError(error), stackTrace);
    _messages.add(SuperdeckAiMessage(_getErrorMessage(error)));
    _isProcessing.value = false;
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
