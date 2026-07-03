/// Centralized file path constants for bundled Flutter assets.
abstract final class Paths {
  // ---------------------------------------------------------------------------
  // File names - for reference only
  // ---------------------------------------------------------------------------

  /// Assets subdirectory name.
  static const assetsDir = 'assets';

  /// Main deck JSON output file name.
  static const deckJsonFile = 'superdeck.json';

  /// App-specific metadata file name.
  static const aiMetadataFile = 'superdeck_ai_metadata.json';

  /// SuperDeck build status file name.
  static const buildStatusFile = 'build_status.json';

  /// Debug file for the last prompt sent to the AI.
  static const lastPromptFile = 'last_prompt.txt';

  /// Debug log file name.
  static const debugLogFile = 'debug.log';

  // ---------------------------------------------------------------------------
  // Asset paths - bundled in Flutter, remain static constants
  // These are used for AssetManifest lookups and must match pubspec.yaml entries
  // ---------------------------------------------------------------------------

  /// Directory for prompt templates (Flutter assets).
  static const promptsDir = 'assets/ai_prompts/';

  /// Directory for example prompt/result pairs (Flutter assets).
  /// Used for AssetManifest lookups - NOT for filesystem I/O.
  static const examplesAssetsDir = 'assets/ai_examples/';
}
