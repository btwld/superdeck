import 'package:flutter_test/flutter_test.dart';
import 'package:googleai_dart/googleai_dart.dart' as google_ai;
import 'package:playground/features/ai/generation/core/engine/services/error_classifier.dart';

void main() {
  const classifier = ErrorClassifier();

  group('classify', () {
    test('uses SDK status codes before incidental message patterns', () {
      expect(
        classifier.classify(
          const google_ai.AuthenticationException(
            message: 'A connection could not be authenticated.',
          ),
        ),
        ErrorCategory.authentication,
      );
      expect(
        classifier.classify(
          const google_ai.ApiException(
            statusCode: 504,
            message: 'Deadline expired while processing 401 items.',
          ),
        ),
        ErrorCategory.network,
      );
    });

    test('detects rate-limit / overload errors', () {
      expect(
        classifier.classify('Error 429: quota exceeded'),
        ErrorCategory.rateLimit,
      );
      expect(
        classifier.classify('RESOURCE_EXHAUSTED'),
        ErrorCategory.rateLimit,
      );
      expect(
        classifier.classify('The model is overloaded'),
        ErrorCategory.rateLimit,
      );
    });

    test('detects authentication errors', () {
      expect(
        classifier.classify('401 Unauthorized'),
        ErrorCategory.authentication,
      );
      expect(
        classifier.classify('API key not valid'),
        ErrorCategory.authentication,
      );
      expect(
        classifier.classify('403 forbidden'),
        ErrorCategory.authentication,
      );
    });

    test('detects network errors', () {
      expect(
        classifier.classify('SocketException: failed'),
        ErrorCategory.network,
      );
      expect(classifier.classify('Connection timeout'), ErrorCategory.network);
      expect(classifier.classify('Failed host lookup'), ErrorCategory.network);
    });

    test('detects safety-filter errors', () {
      expect(
        classifier.classify('Response blocked by safety'),
        ErrorCategory.safetyFilter,
      );
      expect(
        classifier.classify('flagged as harmful'),
        ErrorCategory.safetyFilter,
      );
    });

    test('falls back to unknown', () {
      expect(
        classifier.classify('some unexpected failure'),
        ErrorCategory.unknown,
      );
    });

    test('is case-insensitive', () {
      expect(classifier.classify('QUOTA EXCEEDED'), ErrorCategory.rateLimit);
    });

    test('classifies non-string error objects via toString', () {
      expect(
        classifier.classify(Exception('429 rate limit')),
        ErrorCategory.rateLimit,
      );
    });

    test('matches status numbers only as whole numbers', () {
      expect(
        classifier.classify('retried after 14290 ms'),
        ErrorCategory.unknown,
      );
      expect(classifier.classify('job 1403 failed'), ErrorCategory.unknown);
    });

    group('ignores the request metadata an SDK error carries', () {
      // googleai_dart appends the request URL, a millisecond-timestamp request
      // ID, and the latency to toString(); their digits must not pick a
      // category.
      google_ai.ApiException apiError(int statusCode, String message) =>
          google_ai.ApiException(
            statusCode: statusCode,
            message: message,
            requestMetadata: google_ai.RequestMetadata(
              method: 'POST',
              url: Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/'
                'gemini:generateContent',
              ),
              headers: const {},
              correlationId: 'req_1790401403429',
              timestamp: DateTime(2026),
            ),
            responseMetadata: google_ai.ResponseMetadata(
              statusCode: statusCode,
              headers: const {},
              bodyExcerpt: '',
              latency: const Duration(milliseconds: 403),
            ),
          );

      test('a safety block stays a safety block', () {
        expect(
          classifier.classify(
            apiError(400, 'Response blocked by safety filters.'),
          ),
          ErrorCategory.safetyFilter,
        );
      });

      test('an unavailable service stays unknown', () {
        expect(
          classifier.classify(
            apiError(503, 'The service is currently unavailable.'),
          ),
          ErrorCategory.unknown,
        );
      });

      test('an invalid key is still recognised from the message', () {
        expect(
          classifier.classify(
            apiError(400, 'API key not valid. Please pass a valid API key.'),
          ),
          ErrorCategory.authentication,
        );
      });
    });

    test('applies patterns in priority order (rate limit before auth)', () {
      // Contains both a quota and a 403 marker; rate limit is checked first.
      expect(
        classifier.classify('quota exceeded (403)'),
        ErrorCategory.rateLimit,
      );
    });
  });

  group('getUserMessage', () {
    test('returns the category user message', () {
      expect(
        classifier.getUserMessage('429 quota'),
        ErrorCategory.rateLimit.userMessage,
      );
      expect(
        classifier.getUserMessage('mystery'),
        ErrorCategory.unknown.userMessage,
      );
    });
  });
}
