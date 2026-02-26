import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment configuration.
///
/// Supports two configuration methods:
/// 1. Build-time: `--dart-define=GOOGLE_AI_API_KEY=xxx` (recommended for production)
/// 2. Runtime: `.env` file via flutter_dotenv (for development only)
///
/// Build-time configuration takes precedence over .env file.
abstract final class EnvConfig {
  /// API key from --dart-define (compile-time injection).
  static const _dartDefineKey = String.fromEnvironment('GOOGLE_AI_API_KEY');

  /// Google AI API key for Gemini models.
  ///
  /// Checks --dart-define first, then falls back to .env file.
  /// Throws if the key is not defined in either location.
  static String get geminiApiKey {
    // Prefer build-time injection (--dart-define)
    if (_dartDefineKey.isNotEmpty) {
      return _dartDefineKey;
    }

    // Fall back to .env file (development)
    try {
      final key = dotenv.env['GOOGLE_AI_API_KEY'];
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (_) {
      // dotenv not initialized - fall through to error
    }

    throw StateError(
      'GOOGLE_AI_API_KEY not configured. '
      'Use --dart-define=GOOGLE_AI_API_KEY=xxx or create .env file.',
    );
  }

  /// Check if the API key is configured.
  static bool get hasGeminiApiKey {
    if (_dartDefineKey.isNotEmpty) return true;
    try {
      final key = dotenv.env['GOOGLE_AI_API_KEY'];
      return key != null && key.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
