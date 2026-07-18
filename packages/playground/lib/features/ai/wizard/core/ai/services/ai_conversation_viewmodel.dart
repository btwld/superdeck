import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' as genui;
import 'package:signals/signals_flutter.dart';

import '../../../../quick_agent/core/constants/gemini_models.dart';
import '../../../../image_generation/image_style_preview_coordinator.dart';
import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../schemas/user_action_payload.dart';
import '../wizard_session_state.dart';
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
    return .none;
  }

  return recoveryAttempts == 0 ? .recover : .showError;
}

@visibleForTesting
String? expectedWizardComponentType(WizardStep step) => switch (step) {
  .audience || .approach => 'AskUserRadio',
  .emphasis => 'AskUserCheckbox',
  .slideCount => 'AskUserSlider',
  .theme => 'AskUserStyle',
  .imageStyle => 'AskUserImageStyle',
  .topic || .review => null,
};

@visibleForTesting
bool isExpectedWizardSurface(
  genui.SurfaceDefinition definition,
  WizardStep step,
) {
  final expectedType = expectedWizardComponentType(step);

  return expectedType != null &&
      definition.components['root']?.type == expectedType;
}

final class AiConversationViewModel extends ChangeNotifier
    implements Disposable {
  final PresentationImageStyleCatalog imageStyleCatalog;

  final PresentationThemeCatalog themeCatalog;
  final bool imageStyleEnabled;

  final surfaceIds = Signal<List<String>>([]);
  late final Computed<bool> isThinking = computed(() {
    return _isProcessing.value;
  });
  late final Computed<bool> hasConversationStarted = computed(
    () => _controller.value != null,
  );

  /// The Wizard favors the current Flash Lite model for short, structured
  /// surface turns. There is intentionally no in-wizard model picker.
  static const _modelName = GeminiModelNames.gemini31FlashLite;
  static const _missingSurfaceError =
      'I couldn\'t prepare the next step. Add a detail below to try again.';
  final _controller = Signal<genui.SurfaceController?>(null);
  final _isProcessing = Signal<bool>(false);

  final ImageStylePreviewCoordinator? _imageStylePreviews;
  late final GenUiConversationSession _session;
  DateTime? _lastRequestTime;
  String? _errorMessage;
  String? _surfaceRecoveryReason;
  var _surfaceRecoveryAttempts = 0;
  var _requestProducedSurface = false;
  var _disposed = false;

  WizardSessionState _wizardState;

  static const _errorClassifier = ErrorClassifier();

  AiConversationViewModel({
    required AiConversationProfile profile,
    @visibleForTesting SuperdeckTransportFactory? transportFactory,
    @visibleForTesting String? apiKey,
    ImageStylePreviewCoordinator? imageStylePreviews,
    this.imageStyleEnabled = true,
    SuperdeckAgentClientFactory agentClientFactory =
        DartanticSuperdeckAgentClient.new,
  }) : imageStyleCatalog = profile.imageStyleCatalog,
       themeCatalog = profile.themeCatalog,
       _imageStylePreviews = imageStylePreviews,
       _wizardState = WizardSessionState.initial(
         imageStyleEnabled: imageStyleEnabled,
       ) {
    _session = GenUiConversationSession(
      profile: profile,
      handlers: ConversationSessionHandlers(
        onRequestStarted: _handleRequestStarted,
        onRequestFinished: _handleRequestFinished,
        onUiSubmit: _handleUiSubmit,
        onSurfaceUpdate: _handleSurfaceUpdate,
        onTextResponse: _handleTextResponse,
        onError: _handleTransportError,
      ),
      apiKey: apiKey,
      transportFactory: transportFactory,
      agentClientFactory: agentClientFactory,
    );
  }

  Future<void> _enqueueRequest(genui.ChatMessage message) {
    return _session.sendRequest(message);
  }

  void _handleRequestStarted() {
    _lastRequestTime = DateTime.now();
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
      case .recover:
        _surfaceRecoveryAttempts++;
        final recoveryPrompt = _buildSurfaceRecoveryPrompt();
        _surfaceRecoveryReason = null;
        debugLog.log(
          'CONV',
          'Response did not produce the expected Wizard surface; '
              'requesting one recovery turn',
        );
        unawaited(_enqueueRequest(genui.ChatMessage.user(recoveryPrompt)));

        return;
      case .showError:
        _errorMessage = _missingSurfaceError;
        break;
      case .none:
        break;
    }

    _isProcessing.value = false;
    _notifyView();
  }

  void _handleUiSubmit(genui.ChatMessage message) {
    if (_isProcessing.value) {
      debugLog.log('USER', 'Ignored a duplicate Wizard interaction.');

      return;
    }
    _surfaceRecoveryAttempts = 0;
    final interactionParts = message.parts.uiInteractionParts.toList();
    if (interactionParts.length != 1) {
      _rejectUiAction('Expected exactly one Wizard interaction.');

      return;
    }

    final rawJson = interactionParts.single.interaction;
    final parsed = UserActionPayload.tryParse(rawJson);
    if (parsed == null || parsed.actionName != 'submit_answer') {
      _rejectUiAction('Received an invalid Wizard action.');

      return;
    }

    final previousStep = _wizardState.step;
    final nextState = _wizardState.advance(parsed.context);
    if (nextState == null) {
      _rejectUiAction(
        'That selection does not match the current ${previousStep.name} step.',
      );

      return;
    }

    _wizardState = nextState;
    debugLog.userAction('UI_ACTION', parsed.context);

    if (nextState.step == .review) {
      _notifyView();

      return;
    }

    _isProcessing.value = true;
    _notifyView();

    unawaited(
      _enqueueRequest(
        genui.ChatMessage.user(
          buildWizardTurnPrompt(
            userInput:
                'The user completed ${previousStep.name} with '
                '${jsonEncode(parsed.context)}.',
            state: nextState,
          ),
        ),
      ),
    );
  }

  void _rejectUiAction(String reason) {
    debugLog.log('USER', reason);
    _errorMessage = 'That choice could not be applied. Please try again.';
    _notifyView();
  }

  void _handleTextResponse(String value) {
    _logElapsed('TEXT_RESPONSE received');
    debugLog.aiResponse('TEXT', value);
  }

  void _handleSurfaceUpdate(genui.SurfaceUpdate value) {
    switch (value) {
      case genui.SurfaceAdded(:final surfaceId, :final definition):
        _handleSurfaceAdded(surfaceId, definition);
      case genui.ComponentsUpdated(:final surfaceId, :final definition):
        _handleSurfaceUpdated(surfaceId, definition);
      case genui.SurfaceRemoved(:final surfaceId):
        _handleSurfaceDeleted(surfaceId);
    }
  }

  void _handleSurfaceAdded(
    String surfaceId,
    genui.SurfaceDefinition definition,
  ) {
    _logElapsed('SURFACE_ADDED: $surfaceId');
    debugLog.surface('ADDED', surfaceId);
    if (!_acceptSurfaceForCurrentStep(surfaceId, definition)) return;
    _requestProducedSurface = true;
    if (!surfaceIds.value.contains(surfaceId)) {
      _errorMessage = null;
      _surfaceRecoveryAttempts = 0;
      surfaceIds.value = [...surfaceIds.value, surfaceId];
      _notifyView();
    }
  }

  void _handleSurfaceUpdated(
    String surfaceId,
    genui.SurfaceDefinition definition,
  ) {
    _logElapsed('SURFACE_UPDATED: $surfaceId');
    debugLog.surface('UPDATED', surfaceId);
    if (!_acceptSurfaceForCurrentStep(surfaceId, definition)) return;
    _requestProducedSurface = true;
    _errorMessage = null;
    _surfaceRecoveryAttempts = 0;
    if (!surfaceIds.value.contains(surfaceId)) {
      surfaceIds.value = [...surfaceIds.value, surfaceId];
    }
    _notifyView();
  }

  bool _acceptSurfaceForCurrentStep(
    String surfaceId,
    genui.SurfaceDefinition definition,
  ) {
    if (isExpectedWizardSurface(definition, _wizardState.step)) {
      _surfaceRecoveryReason = null;
      return true;
    }

    final expectedType = expectedWizardComponentType(_wizardState.step);
    final actualType = definition.components['root']?.type;
    final expectedLabel = expectedType ?? 'no generated component';
    final actualLabel = actualType ?? 'no root component';
    _surfaceRecoveryReason =
        'The previous response rendered $actualLabel, '
        'but the canonical ${_wizardState.step.name} step requires '
        '$expectedLabel.';
    surfaceIds.value = surfaceIds.value.where((id) => id != surfaceId).toList();
    debugLog.log(
      'CONV',
      'Rejected mismatched Wizard surface: '
          'expected=$expectedLabel, actual=$actualLabel',
    );
    _notifyView();
    return false;
  }

  String _buildSurfaceRecoveryPrompt() {
    final reason =
        _surfaceRecoveryReason ??
        'The previous response did not include a renderable Wizard surface.';

    return buildWizardTurnPrompt(
      userInput:
          '$reason Return the registered component for the next unanswered '
          'step with a submit action; do not answer with text.',
      state: _wizardState,
    );
  }

  void _handleSurfaceDeleted(String surfaceId) {
    _logElapsed('SURFACE_DELETED: $surfaceId');
    debugLog.surface('DELETED', surfaceId);
    surfaceIds.value = surfaceIds.value.where((id) => id != surfaceId).toList();
    _notifyView();
  }

  void _handleTransportError(Object error, StackTrace stackTrace) {
    _logElapsed('ERROR received');
    debugLog.error('GenUI', _sanitizeError(error), stackTrace);
    _errorMessage = _getErrorMessage(error);
    _isProcessing.value = false;
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

  String _getErrorMessage(Object error) =>
      _errorClassifier.getUserMessage(error);

  String _sanitizeError(Object error) {
    final str = error.toString();
    return str.replaceAll(RegExp(r'[A-Za-z0-9_-]{20,}'), '[REDACTED]');
  }

  genui.SurfaceController? get controller => _controller.value;

  String? get errorMessage => _errorMessage;

  WizardSessionState get wizardState => _wizardState;

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
      _errorMessage = message;
      _notifyView();
    }
    return false;
  }

  Future<void> sendMessage(String raw) async {
    final message = raw.trim();
    if (message.isEmpty || _disposed || _isProcessing.value) return;

    _isProcessing.value = true;
    _notifyView();

    debugLog.userAction('SEND_MESSAGE', {'message': message});
    debugLog.section('New Message');

    final isFirstTurn = !hasConversationStarted.value;
    WizardSessionState? topicState;
    if (isFirstTurn) {
      topicState = _wizardState.startTopic(message);
      if (topicState == null) {
        _isProcessing.value = false;
        _notifyView();

        return;
      }
      _imageStylePreviews?.prefetch(message);
      debugLog.log('CONV', 'Building new conversation');
      final ok = await ensureConversationStarted();
      if (!ok) {
        _isProcessing.value = false;
        _notifyView();

        return;
      }
      _wizardState = topicState;
    }

    if (!_session.hasActiveSession || _wizardState.step == .review) {
      _isProcessing.value = false;
      _notifyView();

      return;
    }

    _surfaceRecoveryAttempts = 0;
    await _enqueueRequest(
      genui.ChatMessage.user(
        buildWizardTurnPrompt(
          userInput: isFirstTurn
              ? 'Presentation topic: $message'
              : 'User request for the current step: $message',
          state: _wizardState,
        ),
      ),
    );
  }

  void restartConversation() {
    debugLog.section('Conversation Restarted');
    _session.restart();
    _controller.value = null;
    _isProcessing.value = false;
    _errorMessage = null;
    _surfaceRecoveryReason = null;
    _surfaceRecoveryAttempts = 0;
    _requestProducedSurface = false;
    _wizardState = WizardSessionState.initial(
      imageStyleEnabled: imageStyleEnabled,
    );
    _imageStylePreviews?.reset();
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
    _isProcessing.dispose();
    isThinking.dispose();
    hasConversationStarted.dispose();
    super.dispose();
  }
}

@visibleForTesting
String buildWizardTurnPrompt({
  required String userInput,
  required WizardSessionState state,
}) {
  return '''
$userInput

Canonical selections: ${jsonEncode(state.context.toMap())}
Expected next step: ${state.step.name}

Generate exactly one ${state.step.name} surface. Keep every canonical selection
unchanged and emit surface messages only.
''';
}
