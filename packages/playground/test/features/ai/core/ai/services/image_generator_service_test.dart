import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:playground/features/ai/core/ai/services/image_generator_service.dart';
import 'package:playground/features/ai/core/ai/services/retry_policy.dart';
import 'package:playground/features/ai/core/constants/gemini_image_options.dart';
import 'package:playground/features/ai/core/constants/gemini_models.dart';

void main() {
  group('ImageGeneratorService interactions API', () {
    test('posts default typed options and decodes image bytes', () async {
      final imageBytes = [1, 2, 3, 4, 5];
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.host, 'generativelanguage.googleapis.com');
        expect(request.url.path, '/v1beta/interactions');
        expect(request.headers['x-goog-api-key'], 'test-key');

        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['model'], GeminiModelNames.gemini31FlashImage);
        expect(body['input'], 'draw a circle');
        final responseFormat = body['response_format'] as Map<String, Object?>;
        expect(responseFormat, containsPair('type', 'image'));
        expect(responseFormat, containsPair('aspect_ratio', '16:9'));
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
        httpClient: client,
        retryPolicy: RetryPolicy(maxAttempts: 1),
      );
      addTearDown(service.dispose);

      final result = await service.generateImage('draw a circle');

      expect(result.success, isTrue);
      expect(result.bytes, orderedEquals(imageBytes));
    });

    test('posts custom model, aspect ratio, and image size', () async {
      final imageBytes = [6, 7, 8];
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['model'], GeminiModelNames.gemini3ProImage);
        expect(body['input'], 'draw a diagram');
        final responseFormat = body['response_format'] as Map<String, Object?>;
        expect(responseFormat, containsPair('type', 'image'));
        expect(responseFormat, containsPair('aspect_ratio', '3:4'));
        expect(responseFormat, containsPair('image_size', '2K'));

        return http.Response(
          jsonEncode({
            'output_image': {
              'type': 'image',
              'mime_type': 'image/png',
              'data': base64Encode(imageBytes),
            },
          }),
          200,
        );
      });

      final service = ImageGeneratorService(
        apiKey: 'test-key',
        model: GeminiImageModel.gemini3ProImage,
        aspectRatio: GeminiImageAspectRatio.portrait3x4,
        imageSize: GeminiImageSize.k2,
        httpClient: client,
        retryPolicy: RetryPolicy(maxAttempts: 1),
      );
      addTearDown(service.dispose);

      final result = await service.generateImage('draw a diagram');

      expect(result.success, isTrue);
      expect(result.bytes, orderedEquals(imageBytes));
    });

    test('uses model-specific default image size', () async {
      final imageBytes = [9, 10, 11];
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['model'], GeminiModelNames.gemini3ProImage);
        final responseFormat = body['response_format'] as Map<String, Object?>;
        expect(responseFormat, containsPair('image_size', '1K'));

        return http.Response(
          jsonEncode({
            'output_image': {
              'type': 'image',
              'mime_type': 'image/png',
              'data': base64Encode(imageBytes),
            },
          }),
          200,
        );
      });

      final service = ImageGeneratorService(
        apiKey: 'test-key',
        model: GeminiImageModel.gemini3ProImage,
        httpClient: client,
        retryPolicy: RetryPolicy(maxAttempts: 1),
      );
      addTearDown(service.dispose);

      final result = await service.generateImage('draw with pro default size');

      expect(result.success, isTrue);
      expect(result.bytes, orderedEquals(imageBytes));
    });

    test('rejects unsupported model and image size combinations', () {
      expect(
        () => ImageGeneratorService(
          apiKey: 'test-key',
          model: GeminiImageModel.gemini3ProImage,
          imageSize: GeminiImageSize.px512,
        ),
        throwsArgumentError,
      );
    });

    test('rejects unsupported model and aspect ratio combinations', () {
      expect(
        () => ImageGeneratorService(
          apiKey: 'test-key',
          model: GeminiImageModel.gemini3ProImage,
          aspectRatio: GeminiImageAspectRatio.tall1x4,
        ),
        throwsArgumentError,
      );
    });

    test('cache key includes image size', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'output_image': {
              'type': 'image',
              'mime_type': 'image/png',
              'data': base64Encode([requestCount]),
            },
          }),
          200,
        );
      });

      final px512Service = ImageGeneratorService(
        apiKey: 'test-key',
        httpClient: client,
        retryPolicy: RetryPolicy(maxAttempts: 1),
      );
      final k1Service = ImageGeneratorService(
        apiKey: 'test-key',
        imageSize: GeminiImageSize.k1,
        httpClient: client,
        retryPolicy: RetryPolicy(maxAttempts: 1),
      );
      addTearDown(px512Service.dispose);
      addTearDown(k1Service.dispose);

      final prompt = 'cache key includes size prompt';
      final px512First = await px512Service.generateImage(prompt);
      final k1Result = await k1Service.generateImage(prompt);
      final px512Second = await px512Service.generateImage(prompt);

      expect(requestCount, 2);
      expect(px512First.bytes, orderedEquals([1]));
      expect(k1Result.bytes, orderedEquals([2]));
      expect(px512Second.bytes, orderedEquals([1]));
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

      final result = await service.generateImage('draw an error case');

      expect(result.success, isFalse);
      expect(
        result.error,
        'You do not have enough quota to make this request.',
      );
    });
  });
}
