/// Logical stages represented in generation trace artifacts.
enum GenerationTracePhase { outline, composition, slide, finalize }

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
  const GenerationTraceEvent({
    required this.kind,
    required this.phase,
    required this.elapsed,
    this.model,
    this.attempt = 1,
    this.slideIndex,
    this.slideCount,
    this.prompt,
    this.response,
    this.validationErrors = const [],
  });

  final GenerationTraceKind kind;
  final GenerationTracePhase phase;
  final Duration elapsed;
  final String? model;
  final int attempt;
  final int? slideIndex;
  final int? slideCount;
  final String? prompt;
  final String? response;
  final List<String> validationErrors;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'phase': phase.name,
    'elapsedMs': elapsed.inMilliseconds,
    if (model != null) 'model': model,
    'attempt': attempt,
    if (slideIndex != null) 'slideIndex': slideIndex,
    if (slideCount != null) 'slideCount': slideCount,
    if (prompt != null) 'prompt': prompt,
    if (response != null) 'response': response,
    if (validationErrors.isNotEmpty) 'validationErrors': validationErrors,
  };
}

typedef GenerationTraceCallback = void Function(GenerationTraceEvent event);

/// Emits run-relative trace events when a callback is configured.
final class GenerationTraceEmitter {
  GenerationTraceEmitter(GenerationTraceCallback? callback)
    : _callback = callback,
      _startedAt = DateTime.now();

  final GenerationTraceCallback? _callback;
  final DateTime _startedAt;

  void emit({
    required GenerationTraceKind kind,
    required GenerationTracePhase phase,
    String? model,
    int attempt = 1,
    int? slideIndex,
    int? slideCount,
    String? prompt,
    String? response,
    List<String> validationErrors = const [],
  }) {
    _callback?.call(
      GenerationTraceEvent(
        kind: kind,
        phase: phase,
        elapsed: DateTime.now().difference(_startedAt),
        model: model,
        attempt: attempt,
        slideIndex: slideIndex,
        slideCount: slideCount,
        prompt: prompt,
        response: response,
        validationErrors: List.unmodifiable(validationErrors),
      ),
    );
  }
}
