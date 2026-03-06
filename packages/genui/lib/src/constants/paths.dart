import 'package:superdeck_core/superdeck_core.dart';

import '../path_service.dart';

/// Centralized file and directory path constants.
///
/// Runtime paths (for file I/O) delegate to [PathService] for platform-aware
/// resolution. Asset paths (bundled in Flutter) remain as static constants.
abstract final class Paths {
  // ---------------------------------------------------------------------------
  // Runtime paths - delegate to PathService for platform-aware resolution
  // ---------------------------------------------------------------------------

  /// Root directory for SuperDeck output files.
  static String get superdeckDir => PathService.instance.superdeckDir;

  /// Full path to assets directory.
  static String get superdeckAssetsPath => PathService.instance.assetsPath;

  /// Full path to deck JSON file.
  static String get deckJsonPath => PathService.instance.deckJsonPath;

  /// Full path to last prompt file.
  static String get lastPromptPath => PathService.instance.lastPromptPath;

  /// Full path to last generation metadata (prompt + parameters).
  static String get lastGenerationPath =>
      PathService.instance.lastGenerationPath;

  /// Full path to debug log.
  static String get debugLogPath => PathService.instance.debugLogPath;

  /// Runtime directory for example prompt/result pairs (filesystem I/O).
  /// For asset bundle lookups, use [examplesAssetsDir] instead.
  static String get examplesDir => PathService.instance.examplesDir;

  // ---------------------------------------------------------------------------
  // File names - for reference only
  // ---------------------------------------------------------------------------

  /// Assets subdirectory name.
  static const assetsDir = DeckArtifacts.assetsDir;

  /// Main deck JSON output file name.
  static const deckJsonFile = DeckArtifacts.deckJsonFile;

  /// Debug file for the last prompt sent to the AI.
  static const lastPromptFile = 'last_prompt.txt';

  /// Debug log file name.
  static const debugLogFile = 'debug.log';

  // ---------------------------------------------------------------------------
  // Asset paths - bundled in Flutter, remain static constants
  // These are used for AssetManifest lookups and must match pubspec.yaml entries
  // ---------------------------------------------------------------------------

  /// Directory for prompt templates (Flutter assets).
  /// Uses the `packages/` prefix required for assets bundled in Flutter packages.
  static const promptsDir = 'packages/superdeck_genui/assets/prompts/';

  /// Directory for example prompt/result pairs (Flutter assets).
  /// Used for AssetManifest lookups - NOT for filesystem I/O.
  /// Uses the `packages/` prefix required for assets bundled in Flutter packages.
  static const examplesAssetsDir = 'packages/superdeck_genui/assets/examples/';
}
