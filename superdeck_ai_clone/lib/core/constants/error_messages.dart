/// Centralized user-facing error messages.
///
/// All user-visible error messages should be defined here to ensure:
/// - Consistent messaging across the application
/// - Easy localization in the future
/// - Single source of truth for error text
abstract final class ErrorMessages {
  // ---------------------------------------------------------------------------
  // Configuration Errors
  // ---------------------------------------------------------------------------

  /// API key is missing or not configured.
  static const apiKeyMissing =
      'Unable to start conversation. Please check your API key configuration.';

  /// API key configuration help message (for developers).
  static const apiKeyHelp =
      'GOOGLE_AI_API_KEY not configured. Use --dart-define=GOOGLE_AI_API_KEY=xxx or create .env file.';

  /// API key not configured (short form).
  static const apiKeyNotConfigured = 'API key not configured';

  // ---------------------------------------------------------------------------
  // Initialization Errors
  // ---------------------------------------------------------------------------

  /// Prompt assets failed to load.
  static const promptLoadFailed =
      'Unable to load conversation prompts. Please restart the app.';

  /// Generic conversation initialization failure.
  static const conversationInitFailed =
      'Failed to initialize conversation. Please try again.';

  // ---------------------------------------------------------------------------
  // Generation Errors
  // ---------------------------------------------------------------------------

  /// Outline generation failed.
  static const outlineGenerationFailed =
      'Failed to generate presentation outline. Please try again.';

  /// Final deck generation failed.
  static const deckGenerationFailed =
      'Failed to generate final presentation. Please try again.';

  /// No slides were generated.
  static const noSlidesGenerated = 'No slides generated';

  /// Generic generation failure.
  static const generationFailed = 'Generation failed. Please try again.';

  /// Image preview generation failed.
  static const imagePreviewFailed = 'Failed to generate previews';

  // ---------------------------------------------------------------------------
  // Regeneration Errors
  // ---------------------------------------------------------------------------

  /// No previous prompt exists for regeneration.
  static const noPreviousPrompt =
      'No previous prompt found. Complete the wizard at least once.';

  /// Previous prompt file is empty.
  static const emptyPromptFile = 'Previous prompt file is empty.';

  // ---------------------------------------------------------------------------
  // Fallback Messages
  // ---------------------------------------------------------------------------

  /// Generic unexpected error fallback.
  static const unexpectedError = 'An unexpected error occurred';

  /// Unknown error fallback.
  static const unknownError = 'Unknown error';
}
