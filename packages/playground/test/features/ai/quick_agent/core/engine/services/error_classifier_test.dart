import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/error_classifier.dart';

void main() {
  const classifier = ErrorClassifier();

  group('classify', () {
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
