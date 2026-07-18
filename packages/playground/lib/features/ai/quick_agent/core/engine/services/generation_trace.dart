import 'generation_validation_issue.dart';

/// Logical stages represented in generation trace artifacts.
enum GenerationTracePhase { outline, image, composition, slide, finalize }

/// Observable event types emitted by the generation pipeline.
enum GenerationTraceKind {
  phaseStarted,
  request,
  response,
  validation,
  phaseDone,
}

/// One structured, secret-free event from a deck-generation run.
final class GenerationTraceEvent {
  final GenerationTraceKind kind;
  final GenerationTracePhase phase;
  final Duration elapsed;
  final String? model;
  final int attempt;
  final int transportAttempt;
  final int? slideIndex;
  final int? slideCount;
  final String? prompt;
  final String? response;
  final List<String> validationErrors;
  final List<GenerationValidationIssue> validationIssues;

  const GenerationTraceEvent({
    required this.kind,
    required this.phase,
    required this.elapsed,
    this.model,
    this.attempt = 1,
    this.transportAttempt = 1,
    this.slideIndex,
    this.slideCount,
    this.prompt,
    this.response,
    this.validationErrors = const [],
    this.validationIssues = const [],
  });

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'phase': phase.name,
    'elapsedMs': elapsed.inMilliseconds,
    if (model != null) 'model': model,
    'attempt': attempt,
    'semanticAttempt': attempt,
    'transportAttempt': transportAttempt,
    if (slideIndex != null) 'slideIndex': slideIndex,
    if (slideCount != null) 'slideCount': slideCount,
    if (prompt != null) 'prompt': prompt,
    if (response != null) 'response': response,
    if (validationErrors.isNotEmpty) 'validationErrors': validationErrors,
    if (validationIssues.isNotEmpty)
      'validationIssues': [
        for (final issue in validationIssues) issue.toJson(),
      ],
  };
}

typedef GenerationTraceCallback = void Function(GenerationTraceEvent event);

/// Emits run-relative trace events when a callback is configured.
final class GenerationTraceEmitter {
  final GenerationTraceCallback? _callback;
  final DateTime _startedAt;

  GenerationTraceEmitter(GenerationTraceCallback? callback)
    : _callback = callback,
      _startedAt = DateTime.now();

  void emit({
    required GenerationTraceKind kind,
    required GenerationTracePhase phase,
    String? model,
    int attempt = 1,
    int transportAttempt = 1,
    int? slideIndex,
    int? slideCount,
    String? prompt,
    String? response,
    List<String> validationErrors = const [],
    List<GenerationValidationIssue> validationIssues = const [],
  }) {
    _callback?.call(
      GenerationTraceEvent(
        kind: kind,
        phase: phase,
        elapsed: DateTime.now().difference(_startedAt),
        model: model,
        attempt: attempt,
        transportAttempt: transportAttempt,
        slideIndex: slideIndex,
        slideCount: slideCount,
        prompt: prompt,
        response: response,
        validationErrors: List.unmodifiable(validationErrors),
        validationIssues: List.unmodifiable(validationIssues),
      ),
    );
  }
}
