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

typedef ApplyWizardDeckResult =
    FutureOr<void> Function(DeckGenerationResult result);

/// Owns the deterministic plan → review → compose lifecycle for the Wizard.
final class WizardGenerationController extends ChangeNotifier {
  /// Booth-demo performance target used by live smoke tests and reporting.
  ///
  /// This is deliberately not a runtime deadline. The generation service owns
  /// request and run safety timeouts, while the Wizard keeps showing progress
  /// when a healthy provider call takes longer than the target.
  static const generationBudget = Duration(seconds: 30);

  final DeckGeneratorService _service;
  final ApplyWizardDeckResult _applyResult;

  WizardGenerationStage _stage = .setup;

  WizardGenerationPhase? _failedPhase;
  DeckGenerationRequest? _request;
  DeckPlanType? _plan;
  DeckGenerationResult? _result;
  String? _errorMessage;
  GenerationProgress _progress = const GenerationProgress(.idle);
  Duration _elapsed = .zero;
  DateTime? _stageStartedAt;
  var _cancelled = false;
  var _disposed = false;
  var _operationEpoch = 0;
  var _planRevision = 0;
  WizardGenerationController({
    required DeckGeneratorService service,
    required ApplyWizardDeckResult applyResult,
  }) : _service = service,
       _applyResult = applyResult;

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
      _elapsed = .zero;
    }
    _result = null;
    _errorMessage = null;
    _failedPhase = null;
    _cancelled = false;
    _beginStage(.planning);
    _progress = const GenerationProgress(.generatingOutline);
    _notify();

    final DeckPlanningResult planning;
    try {
      planning = await _service.plan(
        request,
        onProgress: (progress) => _setProgress(operation, progress),
        isCancelled: () => _isOperationCancelled(operation),
      );
    } catch (error) {
      _finishTiming();
      if (!_isCurrentOperation(operation)) return;
      _fail(.planning, 'Could not create the outline: $error');

      return;
    }
    _finishTiming();
    if (!_isCurrentOperation(operation) || _disposed) return;
    if (_cancelled) return;
    if (!planning.success || planning.plan == null) {
      _fail(.planning, planning.error ?? 'Could not create the outline.');

      return;
    }

    _plan = planning.plan;
    _planRevision++;
    _stage = .outlineReview;
    _progress = const GenerationProgress(.idle);
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
    }
    _stageStartedAt = null;
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
    _stage = .failed;
    _progress = const GenerationProgress(.idle);
    _notify();
  }

  Future<void> _completeComposition(DeckGenerationResult generated) async {
    try {
      await _applyResult(generated);
    } catch (error) {
      _fail(
        .composition,
        'Slides were generated but could not be loaded: $error',
      );

      return;
    }
    _result = generated;
    _stage = .completed;
    _progress = const GenerationProgress(.idle);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

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

  bool get isBusy => _stage == .planning || _stage == .composing;

  Future<void> createOutline(DeckGenerationRequest request) async {
    await _createOutline(request, preserveCurrentPlan: false);
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
    if (_stage != .outlineReview || currentPlan == null) {
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
      imageStyleCatalog: _service.imageStyleCatalog,
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
    if (_stage != .outlineReview ||
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
    _beginStage(.composing);
    _progress = const GenerationProgress(.composingSlides);
    _notify();

    final DeckGenerationResult generated;
    try {
      generated = await _service.generateFromPlan(
        currentRequest,
        currentPlan,
        onProgress: (progress) => _setProgress(operation, progress),
        isCancelled: () => _isOperationCancelled(operation),
      );
    } catch (error) {
      _finishTiming();
      if (!_isCurrentOperation(operation)) return;
      _fail(.composition, 'Could not compose the slides: $error');

      return;
    }
    _finishTiming();
    if (!_isCurrentOperation(operation) || _disposed || _cancelled) return;
    if ((!generated.success && !generated.isPartial) ||
        generated.slides.isEmpty) {
      _fail(.composition, generated.error ?? 'Could not compose the slides.');

      return;
    }

    await _completeComposition(generated);
  }

  Future<void> retryFailedSlides() async {
    final currentRequest = _request;
    final currentResult = _result;
    if (_stage != .completed ||
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
    _beginStage(.composing);
    _progress = const GenerationProgress(.composingSlides);
    _notify();

    final DeckGenerationResult generated;
    try {
      generated = await _service.retryFailedSlides(
        currentRequest,
        currentResult,
        onProgress: (progress) => _setProgress(operation, progress),
        isCancelled: () => _isOperationCancelled(operation),
      );
    } catch (error) {
      _finishTiming();
      if (!_isCurrentOperation(operation)) return;
      _fail(.composition, 'Could not retry the unresolved slides: $error');

      return;
    }
    _finishTiming();
    if (!_isCurrentOperation(operation) || _disposed || _cancelled) return;
    if ((!generated.success && !generated.isPartial) ||
        generated.slides.isEmpty) {
      _fail(
        .composition,
        generated.error ?? 'Could not retry the unresolved slides.',
      );

      return;
    }

    await _completeComposition(generated);
  }

  Future<void> retry() async {
    switch (_failedPhase) {
      case .planning:
        await regenerateOutline();
      case .composition:
        if (_result?.isPartial == true) {
          _stage = .completed;
          await retryFailedSlides();
        } else {
          returnToOutline();
          await generateSlides();
        }
      case null:
    }
  }

  void returnToOutline() {
    if (_plan == null || _stage != .failed) {
      return;
    }
    _errorMessage = null;
    _failedPhase = null;
    _stage = .outlineReview;
    _progress = const GenerationProgress(.idle);
    _notify();
  }

  void editOutline() {
    if (_plan == null || _stage != .completed) return;
    _stage = .outlineReview;
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
    _progress = const GenerationProgress(.idle);
    _elapsed = .zero;
    _stageStartedAt = null;
    _stage = .setup;
    _notify();
  }

  void cancel() {
    if (!isBusy || _cancelled) return;
    _cancelled = true;
    _operationEpoch++;
    _finishTiming();
    _stage = _result?.isPartial == true
        ? .completed
        : _plan == null
        ? .setup
        : .outlineReview;
    _progress = const GenerationProgress(.idle);
    _notify();
  }

  @override
  void dispose() {
    _cancelled = true;
    _disposed = true;
    super.dispose();
  }
}
