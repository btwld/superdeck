import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' as genui;
import 'package:signals/signals_flutter.dart';

import '../../../../quick_agent/core/constants/gemini_models.dart';
import '../../../chat/chat_message.dart';
import '../../debug_logger.dart';
import '../../viewmodel_scope.dart';
import 'ai_conversation_profile.dart';
import 'error_classifier.dart';
import 'genui_conversation_session.dart';
import 'superdeck_a2ui_transport.dart';
import 'superdeck_agent_client.dart';

@visibleForTesting
enum MissingSurfaceAction { none, recover, showError }

@visibleForTesting
MissingSurfaceAction decideMissingSurfaceAction({
  required bool hasError,
  required bool hasController,
  required bool requestProducedSurface,
  required int recoveryAttempts,
}) {
  if (hasError || !hasController || requestProducedSurface) {
    return MissingSurfaceAction.none;
  }
  return recoveryAttempts == 0
      ? MissingSurfaceAction.recover
      : MissingSurfaceAction.showError;
}

final class AiConversationViewModel extends ChangeNotifier
    implements Disposable {
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

  /// The Wizard favors the current Flash Lite model for short, structured
  /// surface turns. There is intentionally no in-wizard model picker.
  static const _modelName = GeminiModelNames.gemini31FlashLite;
  static const _missingSurfaceRecoveryPrompt = '''
The previous response did not include a renderable Wizard surface. Continue
from the current Wizard state and return exactly one valid surface for the next
unanswered step. Use the registered catalog ID, include a submit control, and
do not answer with text only.
''';
  static const _missingSurfaceError =
      'I couldn\'t prepare the next step. Add a detail below to try again.';

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
  String? _errorMessage;
  var _surfaceRecoveryAttempts = 0;
  var _requestProducedSurface = false;
  var _disposed = false;

  genui.SurfaceController? get controller => _controller.value;

  String? get errorMessage => _errorMessage;

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
      _notifyView();
      return true;
    }

    final message = result.message;
    if (message != null && !_disposed) {
      _messages.add(SuperdeckAiMessage(message));
      _errorMessage = message;
      _notifyView();
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

    _surfaceRecoveryAttempts = 0;
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
    _errorMessage = null;
    _surfaceRecoveryAttempts = 0;
    _requestProducedSurface = false;
    _messages.value = [];
    surfaceIds.value = [];
    _notifyView();
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
    super.dispose();
  }

  Future<void> _enqueueRequest(genui.ChatMessage message) {
    return _session.sendRequest(message);
  }

  void _handleRequestStarted() {
    _lastRequestTime = DateTime.now();
    _streamingAiResponse = '';
    _streamingAiMessageIndex = null;
    _errorMessage = null;
    _requestProducedSurface = false;
    _isProcessing.value = true;
    _notifyView();
    debugLog.log(
      'TIMING',
      'Request started at ${_lastRequestTime!.toIso8601String()}',
    );
  }

  void _handleRequestFinished() {
    _logElapsed('REQUEST_FINISHED');

    switch (decideMissingSurfaceAction(
      hasError: _errorMessage != null,
      hasController: _controller.value != null,
      requestProducedSurface: _requestProducedSurface,
      recoveryAttempts: _surfaceRecoveryAttempts,
    )) {
      case MissingSurfaceAction.recover:
        _surfaceRecoveryAttempts++;
        debugLog.log(
          'CONV',
          'Response had no Wizard surface; requesting one recovery turn',
        );
        unawaited(
          _enqueueRequest(
            genui.ChatMessage.user(_missingSurfaceRecoveryPrompt),
          ),
        );
        return;
      case MissingSurfaceAction.showError:
        _errorMessage = _missingSurfaceError;
        break;
      case MissingSurfaceAction.none:
        break;
    }

    _isProcessing.value = false;
    _notifyView();
  }

  void _handleUiSubmit(genui.ChatMessage message) {
    _surfaceRecoveryAttempts = 0;
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

    _notifyView();
    unawaited(_enqueueRequest(message));
  }

  void _handleTextResponse(String value) {
    _logElapsed('TEXT_RESPONSE received');
    debugLog.aiResponse('TEXT', value);
    _streamingAiResponse = mergeFinalOutputSegments(
      _streamingAiResponse,
      value,
    );

    final next = [..._messages.value];
    final index = _streamingAiMessageIndex;
    if (index != null && index >= 0 && index < next.length) {
      next[index] = SuperdeckAiMessage(_streamingAiResponse);
    } else {
      _streamingAiMessageIndex = next.length;
      next.add(SuperdeckAiMessage(_streamingAiResponse));
    }
    _messages.value = next;
    _notifyView();
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
    _requestProducedSurface = true;
    if (!surfaceIds.value.contains(surfaceId)) {
      _errorMessage = null;
      _surfaceRecoveryAttempts = 0;
      surfaceIds.value = [...surfaceIds.value, surfaceId];
      _addDebugMessage('Surface added: $surfaceId');
      _notifyView();
    }
  }

  void _handleSurfaceUpdated(String surfaceId) {
    _logElapsed('SURFACE_UPDATED: $surfaceId');
    debugLog.surface('UPDATED', surfaceId);
    _requestProducedSurface = true;
    _errorMessage = null;
    _surfaceRecoveryAttempts = 0;
    if (!surfaceIds.value.contains(surfaceId)) {
      surfaceIds.value = [...surfaceIds.value, surfaceId];
      _addDebugMessage('Surface added via update: $surfaceId');
    }
    _addDebugMessage('Surface updated: $surfaceId');
    _notifyView();
  }

  void _handleSurfaceDeleted(String surfaceId) {
    _logElapsed('SURFACE_DELETED: $surfaceId');
    debugLog.surface('DELETED', surfaceId);
    surfaceIds.value = surfaceIds.value.where((id) => id != surfaceId).toList();
    _addDebugMessage('Surface deleted: $surfaceId');
    _notifyView();
  }

  void _handleTransportError(Object error, StackTrace stackTrace) {
    _logElapsed('ERROR received');
    debugLog.error('GenUI', _sanitizeError(error), stackTrace);
    _errorMessage = _getErrorMessage(error);
    _messages.add(SuperdeckAiMessage(_errorMessage!));
    _isProcessing.value = false;
    _streamingAiMessageIndex = null;
    _notifyView();
  }

  void _notifyView() {
    if (!_disposed) notifyListeners();
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

/// Joins complete final-output segments without collapsing their word boundary.
///
/// The A2UI adapter can emit one final sentence as multiple decoded text
/// segments with leading whitespace removed. Punctuation still joins directly.
@visibleForTesting
String mergeFinalOutputSegments(String existing, String next) {
  if (existing.isEmpty || next.isEmpty) return '$existing$next';
  if (RegExp(r'\s$').hasMatch(existing) || RegExp(r'^\s').hasMatch(next)) {
    return '$existing$next';
  }
  const punctuation = ''',.;:!?)]}'"”’''';
  if (punctuation.contains(next[0])) {
    return '$existing$next';
  }
  return '$existing $next';
}
