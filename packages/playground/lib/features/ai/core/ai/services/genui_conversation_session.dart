import 'dart:async';

import 'package:genui/genui.dart' as genui;

import '../../debug_logger.dart';
import '../../env_config.dart';
import '../prompts/prompt_registry.dart';
import 'ai_conversation_profile.dart';
import 'superdeck_a2ui_transport.dart';
import 'superdeck_agent_client.dart';

final class ConversationStartResult {
  const ConversationStartResult._({
    required this.started,
    this.message,
    this.error,
    this.stackTrace,
  });

  const ConversationStartResult.started() : this._(started: true);

  const ConversationStartResult.cancelled() : this._(started: false);

  const ConversationStartResult.failed(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) : this._(
         started: false,
         message: message,
         error: error,
         stackTrace: stackTrace,
       );

  final bool started;
  final String? message;
  final Object? error;
  final StackTrace? stackTrace;
}

final class ConversationSessionHandlers {
  const ConversationSessionHandlers({
    required this.onRequestStarted,
    required this.onRequestFinished,
    required this.onUiSubmit,
    required this.onSurfaceUpdate,
    required this.onTextResponse,
    required this.onError,
  });

  final void Function() onRequestStarted;
  final void Function() onRequestFinished;
  final void Function(genui.ChatMessage message) onUiSubmit;
  final void Function(genui.SurfaceUpdate update) onSurfaceUpdate;
  final void Function(String value) onTextResponse;
  final void Function(Object error, StackTrace stackTrace) onError;
}

final class _SessionBindings {
  const _SessionBindings({
    required this.onSubmitSubscription,
    required this.surfaceSubscription,
    required this.a2uiMessageSubscription,
    required this.textSubscription,
  });

  final StreamSubscription<genui.ChatMessage> onSubmitSubscription;
  final StreamSubscription<genui.SurfaceUpdate> surfaceSubscription;
  final StreamSubscription<genui.A2uiMessage> a2uiMessageSubscription;
  final StreamSubscription<String> textSubscription;

  void cancel() {
    unawaited(onSubmitSubscription.cancel());
    unawaited(surfaceSubscription.cancel());
    unawaited(a2uiMessageSubscription.cancel());
    unawaited(textSubscription.cancel());
  }
}

final class GenUiConversationSession {
  GenUiConversationSession({
    required AiConversationProfile profile,
    required ConversationSessionHandlers handlers,
    SuperdeckTransportFactory? transportFactory,
    SuperdeckAgentClientFactory agentClientFactory =
        DartanticSuperdeckAgentClient.new,
  }) : _profile = profile,
       _handlers = handlers,
       _transportFactory = transportFactory ?? SuperdeckA2uiTransport.new,
       _agentClientFactory = agentClientFactory;

  final AiConversationProfile _profile;
  final ConversationSessionHandlers _handlers;
  final SuperdeckTransportFactory _transportFactory;
  final SuperdeckAgentClientFactory _agentClientFactory;

  genui.SurfaceController? _controller;
  SuperdeckA2uiTransport? _transport;
  StreamSubscription<genui.ChatMessage>? _onSubmitSubscription;
  StreamSubscription<genui.SurfaceUpdate>? _surfaceSubscription;
  StreamSubscription<genui.A2uiMessage>? _a2uiMessageSubscription;
  StreamSubscription<String>? _textSubscription;
  Future<ConversationStartResult>? _startingConversation;
  Future<void> _requestQueue = Future<void>.value();
  var _sessionEpoch = 0;
  var _disposed = false;

  genui.SurfaceController? get controller => _controller;

  bool get hasActiveSession {
    return !_disposed && _controller != null && _transport != null;
  }

  Future<ConversationStartResult> ensureStarted({required String modelName}) {
    if (_disposed) {
      return Future.value(const ConversationStartResult.cancelled());
    }
    if (_controller != null) {
      return Future.value(const ConversationStartResult.started());
    }

    final starting = _startingConversation;
    if (starting != null) return starting;

    late final Future<ConversationStartResult> future;
    future = _start(modelName: modelName).whenComplete(() {
      if (identical(_startingConversation, future)) {
        _startingConversation = null;
      }
    });
    _startingConversation = future;
    return future;
  }

  Future<void> sendRequest(genui.ChatMessage message) {
    final epoch = _sessionEpoch;
    final queued = _requestQueue
        .catchError(_handleRequestQueueError)
        .then((_) => _sendRequest(message, sessionEpoch: epoch));
    _requestQueue = queued;
    return queued;
  }

  void restart() {
    _disposeSession();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _disposeSession();
  }

  Future<ConversationStartResult> _start({required String modelName}) async {
    final epoch = _sessionEpoch;
    final apiKey = _readApiKey();
    if (apiKey == null) {
      return const ConversationStartResult.failed(
        'Unable to start conversation. Please check your API key configuration.',
      );
    }

    genui.SurfaceController? controller;
    SuperdeckA2uiTransport? transport;
    _SessionBindings? bindings;

    try {
      final systemInstruction = await _loadSystemInstruction(epoch);
      if (!_isActiveEpoch(epoch)) {
        return const ConversationStartResult.cancelled();
      }
      if (systemInstruction == null) {
        return ConversationStartResult.failed(_profile.promptLoadErrorMessage);
      }

      controller = genui.SurfaceController(catalogs: [_profile.catalog]);
      transport = _transportFactory(
        apiKey: apiKey,
        modelName: modelName,
        systemPrompt: _buildSystemPrompt(systemInstruction),
        tools: _profile.tools,
        agentClientFactory: _agentClientFactory,
      );

      if (!_isActiveEpoch(epoch)) {
        controller.dispose();
        transport.dispose();
        return const ConversationStartResult.cancelled();
      }

      bindings = _bindSession(
        controller: controller,
        transport: transport,
        sessionEpoch: epoch,
      );

      if (!_isActiveEpoch(epoch)) {
        bindings.cancel();
        controller.dispose();
        transport.dispose();
        return const ConversationStartResult.cancelled();
      }

      _onSubmitSubscription = bindings.onSubmitSubscription;
      _surfaceSubscription = bindings.surfaceSubscription;
      _a2uiMessageSubscription = bindings.a2uiMessageSubscription;
      _textSubscription = bindings.textSubscription;
      _controller = controller;
      _transport = transport;
      return const ConversationStartResult.started();
    } catch (error, stackTrace) {
      bindings?.cancel();
      controller?.dispose();
      transport?.dispose();
      if (_isActiveEpoch(epoch)) {
        _disposeSession();
        debugLog.error('CONV', _sanitizeError(error), stackTrace);
      } else {
        return const ConversationStartResult.cancelled();
      }
      return ConversationStartResult.failed(
        'Failed to initialize conversation. Please try again.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String? _readApiKey() {
    try {
      return EnvConfig.geminiApiKey;
    } on StateError {
      return null;
    }
  }

  Future<String?> _loadSystemInstruction(int epoch) async {
    try {
      await PromptRegistry.instance.load();
      return PromptRegistry.instance.render(_profile.promptName);
    } on StateError catch (error) {
      if (_isActiveEpoch(epoch)) {
        debugLog.error('PROMPT', error.message);
      }
      return null;
    } catch (error, stackTrace) {
      if (_isActiveEpoch(epoch)) {
        debugLog.error('PROMPT', _sanitizeError(error), stackTrace);
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

    if (_profile.tools.isEmpty) {
      return genui.PromptBuilder.chat(
        catalog: _profile.catalog,
        systemPromptFragments: fragments,
      ).systemPromptJoined();
    }

    return genui.PromptBuilder.custom(
      catalog: _profile.catalog,
      allowedOperations: genui.SurfaceOperations.createOnly(dataModel: false),
      systemPromptFragments: fragments,
      technicalPossibilities: const genui.TechnicalPossibilities(
        toolCall: true,
      ),
    ).systemPromptJoined();
  }

  _SessionBindings _bindSession({
    required genui.SurfaceController controller,
    required SuperdeckA2uiTransport transport,
    required int sessionEpoch,
  }) {
    void handleError(Object error, StackTrace stackTrace) {
      if (_isActiveEpoch(sessionEpoch)) {
        _handlers.onError(error, stackTrace);
      }
    }

    final onSubmitSubscription = controller.onSubmit.listen((message) {
      if (_isActiveEpoch(sessionEpoch)) {
        _handlers.onUiSubmit(message);
      }
    }, onError: handleError);
    final surfaceSubscription = controller.surfaceUpdates.listen((update) {
      if (_isActiveEpoch(sessionEpoch)) {
        _handlers.onSurfaceUpdate(update);
      }
    }, onError: handleError);
    final a2uiMessageSubscription = transport.incomingMessages.listen((
      message,
    ) {
      if (_isActiveEpoch(sessionEpoch)) {
        controller.handleMessage(message);
      }
    }, onError: handleError);
    final textSubscription = transport.incomingText.listen((value) {
      if (_isActiveEpoch(sessionEpoch)) {
        _handlers.onTextResponse(value);
      }
    }, onError: handleError);

    return _SessionBindings(
      onSubmitSubscription: onSubmitSubscription,
      surfaceSubscription: surfaceSubscription,
      a2uiMessageSubscription: a2uiMessageSubscription,
      textSubscription: textSubscription,
    );
  }

  Future<void> _sendRequest(
    genui.ChatMessage message, {
    required int sessionEpoch,
  }) async {
    final transport = _transport;
    if (transport == null || !_isActiveEpoch(sessionEpoch)) return;

    _handlers.onRequestStarted();
    try {
      await transport.sendRequest(message);
    } catch (error, stackTrace) {
      if (_isActiveEpoch(sessionEpoch)) {
        _handlers.onError(error, stackTrace);
      }
    } finally {
      if (_isActiveEpoch(sessionEpoch)) {
        _handlers.onRequestFinished();
      }
    }
  }

  void _handleRequestQueueError(Object error, StackTrace stackTrace) {
    if (_disposed) return;
    debugLog.error('GenUI queue', _sanitizeError(error), stackTrace);
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

    _controller?.dispose();
    _controller = null;
    _transport?.dispose();
    _transport = null;
  }

  bool _isActiveEpoch(int epoch) {
    return !_disposed && epoch == _sessionEpoch;
  }

  String _sanitizeError(Object error) {
    final str = error.toString();
    return str.replaceAll(RegExp(r'[A-Za-z0-9_-]{20,}'), '[REDACTED]');
  }
}
