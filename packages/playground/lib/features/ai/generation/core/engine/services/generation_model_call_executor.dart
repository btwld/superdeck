import 'dart:async';

import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;

import 'generation_model_client.dart';
import 'generation_trace.dart';
import 'retry_policy.dart';

/// Executes generation requests under one run-wide cancellation and budget.
final class GenerationModelCallExecutor {
  final GenerationModelClient _client;
  final RetryPolicy _retryPolicy;
  final GenerationTraceEmitter _trace;
  final Duration _requestTimeout;
  final bool Function() _isCancelled;
  final GenerationRunBudget _budget;

  GenerationModelCallExecutor({
    required GenerationModelClient client,
    required RetryPolicy retryPolicy,
    required GenerationTraceEmitter trace,
    required Duration requestTimeout,
    required bool Function() isCancelled,
    required int maxModelRequests,
    required int maxRepairRequests,
    required Duration runTimeout,
  }) : _client = client,
       _retryPolicy = retryPolicy,
       _trace = trace,
       _requestTimeout = requestTimeout,
       _isCancelled = isCancelled,
       _budget = GenerationRunBudget(
         maxModelRequests: maxModelRequests,
         maxRepairRequests: maxRepairRequests,
         timeout: runTimeout,
       );

  void _throwIfCancelled() {
    if (_isCancelled()) throw const GenerationCancelledException();
  }

  bool get hasRepairCapacity => _budget.hasRepairCapacity;

  Future<google_ai.GenerateContentResponse> execute({
    required google_ai.GenerateContentRequest request,
    required GenerationTracePhase phase,
    required String model,
    required String prompt,
    required int semanticAttempt,
    required bool isRepair,
    required String timeoutMessage,
    int? slideIndex,
    int? slideCount,
  }) async {
    _throwIfCancelled();
    _budget.beginSemanticRequest(isRepair: isRepair);

    var successfulTransportAttempt = 1;
    final response = await _retryPolicy.runWithAttempt((transportAttempt) {
      _throwIfCancelled();
      final timeout = _budget.beginTransportRequest(
        requestTimeout: _requestTimeout,
      );
      successfulTransportAttempt = transportAttempt;
      _trace.emit(
        kind: .request,
        phase: phase,
        model: model,
        attempt: semanticAttempt,
        transportAttempt: transportAttempt,
        slideIndex: slideIndex,
        slideCount: slideCount,
        prompt: prompt,
      );

      return _client
          .generateContent(request)
          .timeout(
            timeout,
            onTimeout: () => throw TimeoutException(timeoutMessage),
          );
    });

    _throwIfCancelled();
    _trace.emit(
      kind: .response,
      phase: phase,
      model: model,
      attempt: semanticAttempt,
      transportAttempt: successfulTransportAttempt,
      slideIndex: slideIndex,
      slideCount: slideCount,
      response: generationResponseText(response),
    );

    return response;
  }
}

/// Tracks limits shared by outline, local repair, and slide requests.
final class GenerationRunBudget {
  final int maxModelRequests;
  final int maxRepairRequests;
  final Duration timeout;
  final Stopwatch _stopwatch;

  var _modelRequests = 0;
  var _repairRequests = 0;

  GenerationRunBudget({
    required this.maxModelRequests,
    required this.maxRepairRequests,
    required this.timeout,
  }) : _stopwatch = Stopwatch()..start();

  void _throwIfTimedOut() {
    if (_stopwatch.elapsed >= timeout) {
      throw GenerationBudgetExceededException(
        'Generation time budget exhausted after ${timeout.inSeconds} seconds.',
      );
    }
  }

  bool get hasRepairCapacity {
    _throwIfTimedOut();

    return _repairRequests < maxRepairRequests;
  }

  void beginSemanticRequest({required bool isRepair}) {
    _throwIfTimedOut();
    if (!isRepair) return;
    if (_repairRequests >= maxRepairRequests) {
      throw GenerationBudgetExceededException(
        'Generation repair budget exhausted after '
        '$maxRepairRequests repair requests.',
      );
    }
    _repairRequests++;
  }

  Duration beginTransportRequest({required Duration requestTimeout}) {
    _throwIfTimedOut();
    if (_modelRequests >= maxModelRequests) {
      throw GenerationBudgetExceededException(
        'Generation request budget exhausted after '
        '$maxModelRequests model requests.',
      );
    }
    _modelRequests++;

    final remaining = timeout - _stopwatch.elapsed;

    return remaining < requestTimeout ? remaining : requestTimeout;
  }
}

final class GenerationCancelledException implements Exception {
  const GenerationCancelledException();

  @override
  String toString() => 'Generation cancelled.';
}

final class GenerationBudgetExceededException implements Exception {
  final String message;

  const GenerationBudgetExceededException(this.message);

  @override
  String toString() => message;
}

String? generationResponseText(google_ai.GenerateContentResponse response) {
  if (response.candidates.isEmpty) return null;
  final textParts = response.candidates.first.content?.parts
      .where((part) => part.text != null)
      .map((part) => part.text!)
      .toList();
  if (textParts == null || textParts.isEmpty) return null;

  return textParts.join();
}
