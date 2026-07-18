/// Centralized access to environment configuration.
///
/// API keys are injected at build time with `--dart-define` or
/// `--dart-define-from-file`.
abstract final class EnvConfig {
  /// Final artwork is on for local/debug demos and off by default in release.
  /// Release builds can opt in explicitly after smoke validation.
  static const wizardImageGenerationEnabled = bool.fromEnvironment(
    'SUPERDECK_WIZARD_IMAGE_GENERATION',
    defaultValue: !_isReleaseMode,
  );

  /// API key from --dart-define (compile-time injection).
  static const _dartDefineKey = String.fromEnvironment('GOOGLE_AI_API_KEY');

  static const _isReleaseMode = bool.fromEnvironment('dart.vm.product');

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
