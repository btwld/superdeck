import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../ai/prompts/examples_loader.dart';
import '../ai/prompts/prompt_registry.dart';
import '../debug_logger.dart';
import '../env_config.dart';
import '../path_service.dart';

/// Public initializer for the GenUI package.
///
/// Call this at app startup when integrating screens manually.
/// Route-based integrations via `genUiRoutes()` initialize automatically.
Future<void> initializeGenUi({
  bool loadDotEnv = true,
  String dotenvFileName = '.env',
}) {
  return GenUiBootstrap.ensureInitialized(
    loadDotEnv: loadDotEnv,
    dotenvFileName: dotenvFileName,
  );
}

/// Internal bootstrap coordinator for runtime dependencies.
///
/// Initializes:
/// - [PathService] runtime paths
/// - Optional `.env` loading (for development)
/// - Prompt and example asset registries
/// - Debug logger
abstract final class GenUiBootstrap {
  static bool _initialized = false;
  static Future<void>? _initializing;

  static bool get isInitialized => _initialized;

  static Future<void> ensureInitialized({
    bool loadDotEnv = true,
    String dotenvFileName = '.env',
  }) {
    if (_initialized) {
      return Future.value();
    }

    if (_initializing case final initializing?) {
      return initializing;
    }

    final future = _initialize(
      loadDotEnv: loadDotEnv,
      dotenvFileName: dotenvFileName,
    );

    _initializing = future;
    return future;
  }

  static Future<void> _initialize({
    required bool loadDotEnv,
    required String dotenvFileName,
  }) async {
    try {
      await PathService.instance.initialize();

      if (loadDotEnv) {
        await _loadDotEnvIfNeeded(dotenvFileName: dotenvFileName);
      }

      await PromptRegistry.instance.load();
      await ExamplesLoader.instance.load();
      await debugLog.init();

      _initialized = true;
      _initializing = null;
    } catch (error) {
      _initialized = false;
      _initializing = null;
      rethrow;
    }
  }

  static Future<void> _loadDotEnvIfNeeded({
    required String dotenvFileName,
  }) async {
    if (EnvConfig.hasGeminiApiKey) {
      return;
    }

    try {
      await dotenv.load(fileName: dotenvFileName);
    } catch (_) {
      // Dotenv is optional; missing files should not block startup.
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _initialized = false;
    _initializing = null;
  }
}

/// Async bootstrap guard for embedding GenUI screens directly.
class GenUiBootstrapScope extends StatefulWidget {
  final Widget child;
  final bool loadDotEnv;
  final String dotenvFileName;
  final Widget? loading;

  const GenUiBootstrapScope({
    super.key,
    required this.child,
    this.loadDotEnv = true,
    this.dotenvFileName = '.env',
    this.loading,
  });

  @override
  State<GenUiBootstrapScope> createState() => _GenUiBootstrapScopeState();
}

class _GenUiBootstrapScopeState extends State<GenUiBootstrapScope> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() {
    return GenUiBootstrap.ensureInitialized(
      loadDotEnv: widget.loadDotEnv,
      dotenvFileName: widget.dotenvFileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loading ??
              const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Failed to initialize SuperDeck GenUI.'),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _bootstrapFuture = _bootstrap();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return widget.child;
      },
    );
  }
}
