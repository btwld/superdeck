/// Classified error categories for user-facing messages.
enum ErrorCategory {
  /// Rate limiting, quota exhaustion, or service overload.
  rateLimit('The model is overloaded. Please wait a moment and try again.'),

  /// Invalid or expired API credentials.
  authentication(
    'API key is invalid or expired. Please check your configuration.',
  ),

  /// Network connectivity issues.
  network('Connection issue. Please check your internet and try again.'),

  /// Content blocked by safety filters.
  safetyFilter(
    'The request was blocked by safety filters. Please try rephrasing.',
  ),

  /// Unclassified or unknown error.
  unknown('Sorry, something went wrong. Please try again.');

  const ErrorCategory(this.userMessage);

  /// User-friendly message for this error category.
  final String userMessage;
}

/// Classifies errors into user-friendly categories.
///
/// Examines error messages and HTTP status codes to determine
/// the appropriate [ErrorCategory] for display to users.
///
/// ## Usage
/// ```dart
/// final classifier = ErrorClassifier();
/// final category = classifier.classify(error);
/// showMessage(category.userMessage);
/// ```
///
/// ## Pattern Matching
/// Use Dart's exhaustive switch for handling all categories:
/// ```dart
/// switch (classifier.classify(error)) {
///   case ErrorCategory.rateLimit: handleRateLimit();
///   case ErrorCategory.authentication: handleAuth();
///   case ErrorCategory.network: handleNetwork();
///   case ErrorCategory.safetyFilter: handleSafety();
///   case ErrorCategory.unknown: handleUnknown();
/// }
/// ```
class ErrorClassifier {
  const ErrorClassifier();

  /// Pattern definitions for each error category.
  ///
  /// Listed in priority order - first match wins.
  /// Categories are checked in the order defined in this map.
  static const _patterns = <ErrorCategory, List<String>>{
    ErrorCategory.rateLimit: [
      'quota',
      'rate limit',
      '429',
      'resource_exhausted',
      'overloaded',
    ],
    ErrorCategory.authentication: [
      '401',
      '403',
      'unauthorized',
      'forbidden',
      'invalid api key',
      'api key not valid',
    ],
    ErrorCategory.network: [
      'socketexception',
      'connection',
      'network',
      'timeout',
      'failed host lookup',
    ],
    ErrorCategory.safetyFilter: ['blocked', 'safety', 'harmful'],
  };

  /// Classifies an error into a user-friendly category.
  ///
  /// Examines the error's string representation (case-insensitive)
  /// for known patterns. Returns [ErrorCategory.unknown] if no patterns match.
  ErrorCategory classify(Object error) {
    final errorString = error.toString().toLowerCase();

    for (final entry in _patterns.entries) {
      for (final pattern in entry.value) {
        if (errorString.contains(pattern)) {
          return entry.key;
        }
      }
    }

    return ErrorCategory.unknown;
  }

  /// Returns the user-friendly message for the given error.
  ///
  /// Equivalent to `classify(error).userMessage`.
  String getUserMessage(Object error) => classify(error).userMessage;
}
