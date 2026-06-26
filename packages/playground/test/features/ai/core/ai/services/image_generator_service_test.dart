import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:playground/features/ai/core/ai/services/image_generator_service.dart';
import 'package:playground/features/ai/core/ai/services/retry_policy.dart';
import 'package:playground/features/ai/core/constants/gemini_models.dart';

void main() {
  group('ImageGeneratorService interactions API', () {
    test('posts to interactions endpoint and decodes image bytes', () async {
      final imageBytes = [1, 2, 3, 4, 5];
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.host, 'generativelanguage.googleapis.com');
        expect(request.url.path, '/v1beta/interactions');
        expect(request.headers['x-goog-api-key'], 'test-key');

        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['model'], GeminiModelNames.gemini31FlashImagePreview);
        expect(body['input'], 'draw a circle');
        final responseFormat = body['response_format'] as Map<String, Object?>;
        expect(responseFormat, containsPair('aspect_ratio', '3:4'));
        expect(responseFormat, containsPair('image_size', '512'));

        return http.Response(
          jsonEncode({
            'status': 'completed',
            'steps': [
              {'type': 'signature', 'signature': 'ignored'},
              {
                'type': 'output',
                'content': [
                  {
                    'type': 'image',
                    'mime_type': 'image/jpeg',
                    'data': base64Encode(imageBytes),
                  },
                ],
              },
            ],
          }),
          200,
        );
      });

      final service = ImageGeneratorService(
        apiKey: 'test-key',
        aspectRatio: '3:4',
        httpClient: client,
        retryPolicy: RetryPolicy(maxAttempts: 1),
      );
      addTearDown(service.dispose);

      final result = await service.generateImage('draw a circle');

      expect(result.success, isTrue);
      expect(result.bytes, orderedEquals(imageBytes));
    });

    test('returns provider error message for interactions failures', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'message': 'You do not have enough quota to make this request.',
              'code': 'too_many_requests',
            },
          }),
          429,
        );
      });

      final service = ImageGeneratorService(
        apiKey: 'test-key',
        httpClient: client,
        retryPolicy: RetryPolicy(maxAttempts: 1),
      );
      addTearDown(service.dispose);

      final result = await service.generateImage('draw a circle');

      expect(result.success, isFalse);
      expect(
        result.error,
        'You do not have enough quota to make this request.',
      );
    });
  });
}
