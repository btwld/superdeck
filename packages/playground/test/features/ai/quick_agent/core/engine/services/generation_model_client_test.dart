import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:playground/features/ai/quick_agent/core/constants/gemini_models.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/error_classifier.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_model_client.dart';

void main() {
  const classifier = ErrorClassifier();

  group('Google transport error messages', () {
    for (final (status, message, category) in const [
      (
        401,
        'Request had invalid authentication credentials.',
        ErrorCategory.authentication,
      ),
      (403, 'Permission denied.', ErrorCategory.authentication),
      (408, 'Deadline expired.', ErrorCategory.network),
      (429, 'Request rejected.', ErrorCategory.rateLimit),
      (
        504,
        'Deadline expired before operation could complete.',
        ErrorCategory.network,
      ),
      (400, 'Response blocked by safety filters.', ErrorCategory.safetyFilter),
      (503, 'The model is overloaded.', ErrorCategory.rateLimit),
      (503, 'The service is currently unavailable.', ErrorCategory.unknown),
    ]) {
      test('HTTP $status ($message) gives ${category.name} guidance', () async {
        await http.runWithClient(
          () async {
            final client = GoogleGenerationModelClient.fromApiKey('test-key');
            addTearDown(client.close);

            await expectLater(
              client.generateContent(
                google_ai.GenerateContentRequest(
                  model: GeminiModelNames.gemini37Flash,
                  contents: [
                    google_ai.Content(
                      role: 'user',
                      parts: [google_ai.Part(text: 'Generate a test outline.')],
                    ),
                  ],
                ),
              ),
              throwsA(
                isA<Exception>().having(
                  classifier.getUserMessage,
                  'user message',
                  category.userMessage,
                ),
              ),
            );
          },
          () => MockClient(
            (_) async => http.Response(
              jsonEncode({
                'error': {'code': status, 'message': message},
              }),
              status,
            ),
          ),
        );
      });
    }
  });
}
