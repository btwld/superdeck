import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Platform-aware path resolution service.
///
/// Resolves the SuperDeck storage directory to:
/// - Desktop: cwd/.superdeck (matches SuperDeck viewer's DeckConfiguration)
/// - Mobile/sandboxed: getApplicationSupportDirectory()/.superdeck
///
/// Must be initialized at app startup via [initialize()].
class PathService {
  PathService._();

  static final instance = PathService._();

  String? _baseDir;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initializes the service. Must be called at app startup.
  ///
  /// On desktop (macOS/Linux/Windows), uses CWD-relative `.superdeck/` to
  /// match the SuperDeck viewer's path resolution. On mobile/sandboxed
  /// platforms, uses Application Support directory.
  Future<void> initialize() async {
    if (_initialized) return;

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      _baseDir = '.superdeck';
    } else {
      try {
        final appSupportDir = await getApplicationSupportDirectory();
        _baseDir = p.join(appSupportDir.path, '.superdeck');
      } catch (_) {
        _baseDir = '.superdeck';
      }
    }

    _initialized = true;
  }

  /// Root directory for SuperDeck output files.
  String get superdeckDir {
    _ensureInitialized();
    return _baseDir!;
  }

  /// Full path to assets directory.
  String get assetsPath => p.join(superdeckDir, 'assets');

  /// Full path to deck JSON file.
  String get deckJsonPath => p.join(superdeckDir, 'superdeck.json');

  /// Full path to last prompt file.
  String get lastPromptPath => p.join(superdeckDir, 'last_prompt.txt');

  /// Full path to last generation metadata (prompt + parameters).
  String get lastGenerationPath => p.join(superdeckDir, 'last_generation.json');

  /// Full path to debug log.
  String get debugLogPath => p.join(superdeckDir, 'debug.log');

  /// Directory for example prompt/result pairs.
  String get examplesDir => p.join(superdeckDir, 'examples');

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'PathService not initialized. Call PathService.instance.initialize() at app startup.',
      );
    }
  }

  /// Resets for testing.
  void resetForTest() {
    _baseDir = null;
    _initialized = false;
  }

  /// Sets a custom base directory for testing.
  void setBaseDirForTest(String dir) {
    _baseDir = dir;
    _initialized = true;
  }
}
