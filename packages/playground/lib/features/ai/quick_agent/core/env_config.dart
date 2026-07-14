/// Centralized access to environment configuration.
///
/// API keys are injected at build time with `--dart-define` or
/// `--dart-define-from-file`.
abstract final class EnvConfig {
  /// API key from --dart-define (compile-time injection).
  static const _dartDefineKey = String.fromEnvironment('GOOGLE_AI_API_KEY');

  static String get geminiApiKey {
    // Prefer build-time injection (--dart-define)
    if (_dartDefineKey.isNotEmpty) {
      return _dartDefineKey;
    }

    throw StateError(
      'GOOGLE_AI_API_KEY not configured. '
      'Launch the playground with '
      '--dart-define-from-file=../../.env.',
    );
  }

  /// Check if the API key is configured.
  static bool get hasGeminiApiKey => _dartDefineKey.isNotEmpty;
}
