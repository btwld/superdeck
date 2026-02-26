import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_ai/core/ai/services/error_classifier.dart';

void main() {
  const classifier = ErrorClassifier();

  group('ErrorClassifier', () {
    group('rate limit errors', () {
      test('classifies quota errors', () {
        expect(
          classifier.classify(Exception('Quota exceeded')),
          ErrorCategory.rateLimit,
        );
      });

      test('classifies rate limit errors', () {
        expect(
          classifier.classify('Rate limit exceeded'),
          ErrorCategory.rateLimit,
        );
      });

      test('classifies 429 status', () {
        expect(
          classifier.classify('HTTP 429 Too Many Requests'),
          ErrorCategory.rateLimit,
        );
      });

      test('classifies resource_exhausted', () {
        expect(
          classifier.classify('RESOURCE_EXHAUSTED: quota exceeded'),
          ErrorCategory.rateLimit,
        );
      });

      test('classifies overloaded', () {
        expect(
          classifier.classify('Service overloaded, try again later'),
          ErrorCategory.rateLimit,
        );
      });
    });

    group('authentication errors', () {
      test('classifies 401 status', () {
        expect(
          classifier.classify('HTTP 401 Unauthorized'),
          ErrorCategory.authentication,
        );
      });

      test('classifies 403 status', () {
        expect(
          classifier.classify('HTTP 403 Forbidden'),
          ErrorCategory.authentication,
        );
      });

      test('classifies unauthorized errors', () {
        expect(
          classifier.classify('Request unauthorized'),
          ErrorCategory.authentication,
        );
      });

      test('classifies invalid api key errors', () {
        expect(
          classifier.classify('Invalid API key provided'),
          ErrorCategory.authentication,
        );
      });

      test('classifies api key not valid errors', () {
        expect(
          classifier.classify('API key not valid for this operation'),
          ErrorCategory.authentication,
        );
      });
    });

    group('network errors', () {
      test('classifies socket exceptions', () {
        expect(
          classifier.classify(const SocketException('Connection refused')),
          ErrorCategory.network,
        );
      });

      test('classifies connection errors', () {
        expect(
          classifier.classify('Connection reset by peer'),
          ErrorCategory.network,
        );
      });

      test('classifies network errors', () {
        expect(
          classifier.classify('Network is unreachable'),
          ErrorCategory.network,
        );
      });

      test('classifies timeout errors', () {
        expect(
          classifier.classify('Request timeout after 30 seconds'),
          ErrorCategory.network,
        );
      });

      test('classifies failed host lookup', () {
        expect(
          classifier.classify('Failed host lookup: api.example.com'),
          ErrorCategory.network,
        );
      });
    });

    group('safety filter errors', () {
      test('classifies blocked content', () {
        expect(
          classifier.classify('Content blocked by safety filters'),
          ErrorCategory.safetyFilter,
        );
      });

      test('classifies safety errors', () {
        expect(
          classifier.classify('Safety check failed'),
          ErrorCategory.safetyFilter,
        );
      });

      test('classifies harmful content errors', () {
        expect(
          classifier.classify('Request contains harmful content'),
          ErrorCategory.safetyFilter,
        );
      });
    });

    group('unknown errors', () {
      test('returns unknown category for unrecognized patterns', () {
        expect(
          classifier.classify('Some random error xyz'),
          ErrorCategory.unknown,
        );
      });

      test('returns unknown category for empty string', () {
        expect(classifier.classify(''), ErrorCategory.unknown);
      });

      test('returns unknown category for generic exception', () {
        expect(
          classifier.classify(Exception('Something happened')),
          ErrorCategory.unknown,
        );
      });
    });

    group('case insensitivity', () {
      test('matches uppercase patterns', () {
        expect(classifier.classify('QUOTA EXCEEDED'), ErrorCategory.rateLimit);
      });

      test('matches mixed case patterns', () {
        expect(
          classifier.classify('Rate Limit Exceeded'),
          ErrorCategory.rateLimit,
        );
      });

      test('matches lowercase patterns', () {
        expect(
          classifier.classify('rate limit exceeded'),
          ErrorCategory.rateLimit,
        );
      });
    });

    group('getUserMessage', () {
      test('returns correct message for rate limit', () {
        expect(
          classifier.getUserMessage('Quota exceeded'),
          equals(
            'The model is overloaded. Please wait a moment and try again.',
          ),
        );
      });

      test('returns correct message for auth error', () {
        expect(
          classifier.getUserMessage('401 Unauthorized'),
          equals(
            'API key is invalid or expired. Please check your configuration.',
          ),
        );
      });

      test('returns correct message for network error', () {
        expect(
          classifier.getUserMessage('Connection refused'),
          equals('Connection issue. Please check your internet and try again.'),
        );
      });

      test('returns correct message for safety error', () {
        expect(
          classifier.getUserMessage('Content blocked'),
          equals(
            'The request was blocked by safety filters. Please try rephrasing.',
          ),
        );
      });

      test('returns correct message for unknown error', () {
        expect(
          classifier.getUserMessage('random error'),
          equals('Sorry, something went wrong. Please try again.'),
        );
      });
    });

    group('userMessage property', () {
      test('each category has a non-empty message', () {
        expect(ErrorCategory.rateLimit.userMessage, isNotEmpty);
        expect(ErrorCategory.authentication.userMessage, isNotEmpty);
        expect(ErrorCategory.network.userMessage, isNotEmpty);
        expect(ErrorCategory.safetyFilter.userMessage, isNotEmpty);
        expect(ErrorCategory.unknown.userMessage, isNotEmpty);
      });

      test('messages do not contain technical jargon', () {
        // User messages should be friendly, not technical
        final messages = [
          ErrorCategory.rateLimit.userMessage,
          ErrorCategory.authentication.userMessage,
          ErrorCategory.network.userMessage,
          ErrorCategory.safetyFilter.userMessage,
          ErrorCategory.unknown.userMessage,
        ];

        for (final message in messages) {
          expect(message.toLowerCase(), isNot(contains('exception')));
          expect(message.toLowerCase(), isNot(contains('error code')));
          expect(message.toLowerCase(), isNot(contains('stack trace')));
        }
      });
    });

    group('exhaustive pattern matching', () {
      test('can use switch expression on all categories', () {
        // This test verifies the enum supports exhaustive matching
        String describeError(ErrorCategory category) {
          return switch (category) {
            ErrorCategory.rateLimit => 'rate',
            ErrorCategory.authentication => 'auth',
            ErrorCategory.network => 'network',
            ErrorCategory.safetyFilter => 'safety',
            ErrorCategory.unknown => 'unknown',
          };
        }

        expect(describeError(classifier.classify('quota')), 'rate');
        expect(describeError(classifier.classify('401')), 'auth');
        expect(describeError(classifier.classify('timeout')), 'network');
        expect(describeError(classifier.classify('blocked')), 'safety');
        expect(describeError(classifier.classify('xyz')), 'unknown');
      });
    });
  });
}
