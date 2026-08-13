import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_model_call_executor.dart';

void main() {
  test('caps provider requests across a generation run', () {
    final budget = GenerationRunBudget(
      maxModelRequests: 1,
      maxRepairRequests: 10,
      timeout: const Duration(minutes: 1),
    );

    budget.beginTransportRequest(requestTimeout: const Duration(seconds: 10));

    expect(
      () => budget.beginTransportRequest(
        requestTimeout: const Duration(seconds: 10),
      ),
      throwsA(
        isA<GenerationBudgetExceededException>().having(
          (error) => error.message,
          'message',
          contains('request budget'),
        ),
      ),
    );
  });

  test('caps semantic repairs independently from transport retries', () {
    final budget = GenerationRunBudget(
      maxModelRequests: 10,
      maxRepairRequests: 1,
      timeout: const Duration(minutes: 1),
    );

    budget.beginSemanticRequest(isRepair: true);

    expect(
      () => budget.beginSemanticRequest(isRepair: true),
      throwsA(
        isA<GenerationBudgetExceededException>().having(
          (error) => error.message,
          'message',
          contains('repair budget'),
        ),
      ),
    );
  });

  test('caps wall-clock time across all generation phases', () {
    final budget = GenerationRunBudget(
      maxModelRequests: 10,
      maxRepairRequests: 10,
      timeout: Duration.zero,
    );

    expect(
      () => budget.beginSemanticRequest(isRepair: false),
      throwsA(
        isA<GenerationBudgetExceededException>().having(
          (error) => error.message,
          'message',
          contains('time budget'),
        ),
      ),
    );
  });
}
