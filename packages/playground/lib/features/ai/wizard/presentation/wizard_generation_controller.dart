import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../quick_agent/core/engine/schemas/outline_schema.dart';
import '../../quick_agent/core/engine/services/deck_generation_request.dart';
import '../../quick_agent/core/engine/services/deck_generator_service.dart';
import '../../quick_agent/core/engine/services/deck_plan_validator.dart';
import '../../quick_agent/core/engine/services/generation_progress.dart';
import '../../quick_agent/core/engine/services/generation_validation_issue.dart';

enum WizardGenerationStage {
  setup,
  planning,
  outlineReview,
  composing,
  completed,
  failed,
}

enum WizardGenerationPhase { planning, composition }

typedef ApplyWizardDeckResult = void Function(DeckGenerationResult result);

/// Owns the deterministic plan → review → compose lifecycle for the Wizard.
final class WizardGenerationController extends ChangeNotifier {
  WizardGenerationController({
    required DeckGeneratorService service,
    required ApplyWizardDeckResult applyResult,
  }) : _service = service,
       _applyResult = applyResult;

  final DeckGeneratorService _service;
  final ApplyWizardDeckResult _applyResult;

  static const generationBudget = Duration(seconds: 30);

  WizardGenerationStage _stage = WizardGenerationStage.setup;
  WizardGenerationPhase? _failedPhase;
  DeckGenerationRequest? _request;
  DeckPlanType? _plan;
  DeckGenerationResult? _result;
  String? _errorMessage;
  GenerationProgress _progress = const GenerationProgress(GenerationPhase.idle);
  Duration _elapsed = Duration.zero;
  Duration _budgetElapsed = Duration.zero;
  DateTime? _stageStartedAt;
  var _cancelled = false;
  var _disposed = false;
  var _operationEpoch = 0;
  var _planRevision = 0;

  WizardGenerationStage get stage => _stage;
  WizardGenerationPhase? get failedPhase => _failedPhase;
  DeckPlanType? get plan => _plan;
  int get planRevision => _planRevision;
  DeckGenerationResult? get result => _result;
  String? get errorMessage => _errorMessage;
  GenerationProgress get progress => _progress;
  Duration get elapsed =>
      _elapsed +
      (_stageStartedAt == null
          ? Duration.zero
          : DateTime.now().difference(_stageStartedAt!));
  bool get isBusy =>
      _stage == WizardGenerationStage.planning ||
      _stage == WizardGenerationStage.composing;

  Future<void> createOutline(DeckGenerationRequest request) async {
    await _createOutline(request, preserveCurrentPlan: false);
  }

  Future<void> _createOutline(
    DeckGenerationRequest request, {
    required bool preserveCurrentPlan,
  }) async {
    if (isBusy || _disposed) return;

    final operation = ++_operationEpoch;
    _request = request;
    if (!preserveCurrentPlan) {
      _plan = null;
      _planRevision = 0;
      _elapsed = Duration.zero;
    }
    _budgetElapsed = Duration.zero;
    _result = null;
    _errorMessage = null;
    _failedPhase = null;
    _cancelled = false;
    _beginStage(WizardGenerationStage.planning);
    _progress = const GenerationProgress(GenerationPhase.generatingOutline);
    _notify();

    final DeckPlanningResult planning;
    try {
      planning = await _service
          .plan(
            request,
            onProgress: (progress) => _setProgress(operation, progress),
            isCancelled: () => _isOperationCancelled(operation),
          )
          .timeout(_remainingBudget);
    } on TimeoutException {
      _finishTiming();
      if (!_isCurrentOperation(operation)) return;
      _cancelled = true;
      _fail(
        WizardGenerationPhase.planning,
        'Outline creation exceeded the 30-second demo budget. Try again.',
      );
      return;
    } catch (error) {
      _finishTiming();
      if (!_isCurrentOperation(operation)) return;
      _fail(
        WizardGenerationPhase.planning,
        'Could not create the outline: $error',
      );
      return;
    }
    _finishTiming();
    if (!_isCurrentOperation(operation) || _disposed) return;
    if (_cancelled) return;
    if (!planning.success || planning.plan == null) {
      _fail(
        WizardGenerationPhase.planning,
        planning.error ?? 'Could not create the outline.',
      );
      return;
    }

    _plan = planning.plan;
    _planRevision++;
    _stage = WizardGenerationStage.outlineReview;
    _progress = const GenerationProgress(GenerationPhase.idle);
    _notify();
  }

  Future<void> regenerateOutline() async {
    final currentRequest = _request;
    if (currentRequest == null) return;
    await _createOutline(currentRequest, preserveCurrentPlan: true);
  }

  bool updateSlide(
    int index, {
    required String title,
    required String assertion,
  }) {
    final currentPlan = _plan;
    if (_stage != WizardGenerationStage.outlineReview || currentPlan == null) {
      return false;
    }
    final nextTitle = title.trim();
    final nextAssertion = assertion.trim();
    if (nextTitle.isEmpty || nextAssertion.isEmpty) return false;
    if (index < 0 || index >= currentPlan.slides.length) return false;

    final data = Map<String, Object?>.of(currentPlan);
    final slides = [
      for (final slide in currentPlan.slides) Map<String, Object?>.of(slide),
    ];
    slides[index]
      ..['title'] = nextTitle
      ..['assertion'] = nextAssertion;
    data['slides'] = slides;

    final candidate = DeckPlanType.parse(data);
    final blockingIssues = validateDeckPlanIssues(
      candidate,
      typographyCatalog: _service.typographyCatalog,
      themeCatalog: _service.themeCatalog,
      request: _request,
    ).blockingIssues;
    if (blockingIssues.isNotEmpty) return false;

    _plan = candidate;
    _notify();
    return true;
  }

  Future<void> generateSlides() async {
    final currentRequest = _request;
    final currentPlan = _plan;
    if (_stage != WizardGenerationStage.outlineReview ||
        currentRequest == null ||
        currentPlan == null ||
        _disposed) {
      return;
    }

    final operation = ++_operationEpoch;
    _result = null;
    _errorMessage = null;
    _failedPhase = null;
    _cancelled = false;
    _beginStage(WizardGenerationStage.composing);
    _progress = const GenerationProgress(GenerationPhase.composingSlides);
    _notify();

    final DeckGenerationResult generated;
    try {
      generated = await _service
          .generateFromPlan(
            currentRequest,
            currentPlan,
            onProgress: (progress) => _setProgress(operation, progress),
            isCancelled: () => _isOperationCancelled(operation),
          )
          .timeout(_remainingBudget);
    } on TimeoutException {
      _finishTiming();
      if (!_isCurrentOperation(operation)) return;
      _cancelled = true;
      _fail(
        WizardGenerationPhase.composition,
        'Slide generation exceeded the 30-second demo budget. Try again.',
      );
      return;
    } catch (error) {
      _finishTiming();
      if (!_isCurrentOperation(operation)) return;
      _fail(
        WizardGenerationPhase.composition,
        'Could not compose the slides: $error',
      );
      return;
    }
    _finishTiming();
    if (!_isCurrentOperation(operation) || _disposed || _cancelled) return;
    if ((!generated.success && !generated.isPartial) ||
        generated.slides.isEmpty) {
      _fail(
        WizardGenerationPhase.composition,
        generated.error ?? 'Could not compose the slides.',
      );
      return;
    }

    _completeComposition(generated);
  }

  Future<void> retryFailedSlides() async {
    final currentRequest = _request;
    final currentResult = _result;
    if (_stage != WizardGenerationStage.completed ||
        currentRequest == null ||
        currentResult == null ||
        !currentResult.isPartial ||
        _disposed) {
      return;
    }

    final operation = ++_operationEpoch;
    _errorMessage = null;
    _failedPhase = null;
    _cancelled = false;
    _budgetElapsed = Duration.zero;
    _beginStage(WizardGenerationStage.composing);
    _progress = const GenerationProgress(GenerationPhase.composingSlides);
    _notify();

    final DeckGenerationResult generated;
    try {
      generated = await _service
          .retryFailedSlides(
            currentRequest,
            currentResult,
            onProgress: (progress) => _setProgress(operation, progress),
            isCancelled: () => _isOperationCancelled(operation),
          )
          .timeout(_remainingBudget);
    } on TimeoutException {
      _finishTiming();
      if (!_isCurrentOperation(operation)) return;
      _cancelled = true;
      _fail(
        WizardGenerationPhase.composition,
        'Slide retry exceeded the 30-second demo budget. Try again.',
      );
      return;
    } catch (error) {
      _finishTiming();
      if (!_isCurrentOperation(operation)) return;
      _fail(
        WizardGenerationPhase.composition,
        'Could not retry the unresolved slides: $error',
      );
      return;
    }
    _finishTiming();
    if (!_isCurrentOperation(operation) || _disposed || _cancelled) return;
    if ((!generated.success && !generated.isPartial) ||
        generated.slides.isEmpty) {
      _fail(
        WizardGenerationPhase.composition,
        generated.error ?? 'Could not retry the unresolved slides.',
      );
      return;
    }

    _completeComposition(generated);
  }

  Future<void> retry() async {
    switch (_failedPhase) {
      case WizardGenerationPhase.planning:
        await regenerateOutline();
      case WizardGenerationPhase.composition:
        if (_result?.isPartial == true) {
          _stage = WizardGenerationStage.completed;
          await retryFailedSlides();
        } else {
          returnToOutline();
          await generateSlides();
        }
      case null:
        return;
    }
  }

  void returnToOutline() {
    if (_plan == null || _stage != WizardGenerationStage.failed) {
      return;
    }
    _errorMessage = null;
    _failedPhase = null;
    _budgetElapsed = Duration.zero;
    _stage = WizardGenerationStage.outlineReview;
    _progress = const GenerationProgress(GenerationPhase.idle);
    _notify();
  }

  void editOutline() {
    if (_plan == null || _stage != WizardGenerationStage.completed) return;
    _budgetElapsed = Duration.zero;
    _stage = WizardGenerationStage.outlineReview;
    _notify();
  }

  void reset() {
    _operationEpoch++;
    _cancelled = true;
    _request = null;
    _plan = null;
    _planRevision = 0;
    _result = null;
    _errorMessage = null;
    _failedPhase = null;
    _progress = const GenerationProgress(GenerationPhase.idle);
    _elapsed = Duration.zero;
    _budgetElapsed = Duration.zero;
    _stageStartedAt = null;
    _stage = WizardGenerationStage.setup;
    _notify();
  }

  void cancel() {
    if (!isBusy || _cancelled) return;
    _cancelled = true;
    _operationEpoch++;
    _finishTiming();
    _stage = _result?.isPartial == true
        ? WizardGenerationStage.completed
        : _plan == null
        ? WizardGenerationStage.setup
        : WizardGenerationStage.outlineReview;
    _progress = const GenerationProgress(GenerationPhase.idle);
    _notify();
  }

  void _beginStage(WizardGenerationStage stage) {
    _stage = stage;
    _stageStartedAt = DateTime.now();
  }

  void _finishTiming() {
    final startedAt = _stageStartedAt;
    if (startedAt != null) {
      final duration = DateTime.now().difference(startedAt);
      _elapsed += duration;
      _budgetElapsed += duration;
    }
    _stageStartedAt = null;
  }

  Duration get _remainingBudget {
    final remaining = generationBudget - _budgetElapsed;
    return remaining > Duration.zero
        ? remaining
        : const Duration(microseconds: 1);
  }

  bool _isCurrentOperation(int operation) => operation == _operationEpoch;

  bool _isOperationCancelled(int operation) =>
      _cancelled || !_isCurrentOperation(operation);

  void _setProgress(int operation, GenerationProgress progress) {
    if (_isOperationCancelled(operation) || _disposed) return;
    _progress = progress;
    _notify();
  }

  void _fail(WizardGenerationPhase phase, String message) {
    _failedPhase = phase;
    _errorMessage = message;
    _stage = WizardGenerationStage.failed;
    _progress = const GenerationProgress(GenerationPhase.idle);
    _notify();
  }

  void _completeComposition(DeckGenerationResult generated) {
    try {
      _applyResult(generated);
    } catch (error) {
      _fail(
        WizardGenerationPhase.composition,
        'Slides were generated but could not be loaded: $error',
      );
      return;
    }
    _result = generated;
    _stage = WizardGenerationStage.completed;
    _progress = const GenerationProgress(GenerationPhase.idle);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _cancelled = true;
    _disposed = true;
    super.dispose();
  }
}
