import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart' hide logger, Logger, Level;

import '../utils/extensions.dart';
import '../utils/logger.dart';
import '../utils/update_pubspec.dart';
import 'base_command.dart';

/// Returns whether the process is running in a CI environment.
bool _isCI() {
  final env = Platform.environment;
  return env['CI'] == 'true' ||
      env['GITHUB_ACTIONS'] == 'true' ||
      env['GITLAB_CI'] == 'true' ||
      env['CIRCLECI'] == 'true' ||
      env['TRAVIS'] == 'true';
}

/// Creates a [DeckBuilder] with the standard CLI task pipeline.
DeckBuilder _createStandardBuilder({
  required DeckConfiguration configuration,
  required DeckBuildStore store,
}) {
  // In CI environments, Chrome needs --no-sandbox due to user namespace restrictions
  final browserLaunchOptions = _isCI()
      ? <String, dynamic>{
          'args': ['--no-sandbox', '--disable-setuid-sandbox'],
        }
      : null;

  return DeckBuilder(
    tasks: [
      DartFormatterTask(),
      AssetGenerationTask.withDefaults(
        store: store,
        browserLaunchOptions: browserLaunchOptions,
      ),
    ],
    configuration: configuration,
    store: store,
  );
}

/// Builds SuperDeck presentations from markdown.
///
/// Parses and processes the slides.md file, generating all required assets
/// and outputs for the presentation.
class BuildCommand extends SuperDeckCommand {
  /// Whether a build is currently in progress.
  bool _isRunning = false;

  /// Creates a new [BuildCommand].
  BuildCommand() {
    argParser
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Watch for changes and build the deck',
        negatable: false,
      )
      ..addFlag(
        'skip-pubspec',
        help: 'Skip updating pubspec assets',
        negatable: false,
      )
      ..addFlag(
        'force-rebuild',
        abbr: 'f',
        help: 'Force rebuild all assets',
        negatable: false,
      );
  }

  void _logBuildFailure(Object error, [StackTrace? stackTrace]) {
    if (error is DeckFormatException) {
      logger.formatError(error);
    } else {
      logger.err('${error.runtimeType}: $error');
    }

    if (stackTrace != null) {
      final trace = stackTrace.toString().trim();
      if (trace.isNotEmpty) {
        logger.err('Stack trace:');
        logger.err(trace);
      }
    }
  }

  /// Cleans all generated assets and runs a full rebuild.
  ///
  /// Uses the provided [builder] for the build, or creates and disposes a new
  /// one if not provided.
  Future<bool> _cleanAndRebuild(
    DeckBuildStore store,
    DeckConfiguration config, {
    DeckBuilder? builder,
  }) async {
    logger.info('Force rebuild: Clearing all generated assets...');

    // Delete and recreate assets directory
    if (await config.assetsDir.exists()) {
      await config.assetsDir.delete(recursive: true);
    }
    await config.assetsDir.create(recursive: true);

    // Delete the generated assets reference file
    if (await config.assetsRefJson.exists()) {
      await config.assetsRefJson.delete();
      logger.detail('Deleted generated_assets.json');
    }

    // Run the build (pass through the builder if provided)
    return _runBuild(store, config, builder: builder);
  }

  /// Runs the build process with proper error handling and progress reporting.
  ///
  /// Uses the provided [builder] for the build, or creates and disposes a new
  /// one if not provided.
  Future<bool> _runBuild(
    DeckBuildStore store,
    DeckConfiguration config, {
    DeckBuilder? builder,
  }) async {
    // Wait while a build is already running
    while (_isRunning) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isRunning = true;
    final progress = logger.progress('Generating slides...');

    // Track if we created the builder (and thus need to dispose it)
    final ownsBuilder = builder == null;
    builder ??= _createStandardBuilder(configuration: config, store: store);

    try {
      // Run the build process
      final slides = await builder.build();

      if (slides.isEmpty) {
        progress.update('No slides found.');
        logger.warn(
          'No slides found in your slides.md file. Make sure it exists and has proper content.',
        );
        progress.complete('Build completed with warnings.');

        return false;
      }

      progress.complete('Generated ${slides.length} slides.');

      return true;
    } on FileSystemException catch (e) {
      progress.fail('Build failed');
      logger.err('File system error: ${e.message}');
      logger.err('Path: ${e.path ?? 'Unknown'}');
      await store.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: e,
        stackTrace: StackTrace.current,
      );

      return false;
    } on FormatException catch (e) {
      progress.fail('Format error');
      logger.err(e.message);
      await store.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: e,
        stackTrace: StackTrace.current,
      );

      return false;
    } catch (e, stackTrace) {
      progress.fail('Build failed');
      _logBuildFailure(e, stackTrace);
      await store.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: e,
        stackTrace: stackTrace,
      );

      return false;
    } finally {
      _isRunning = false;
      // Dispose the builder if we created it (not in watch mode)
      if (ownsBuilder) {
        await builder.dispose();
      }
    }
  }

  @override
  Future<int> run() async {
    DeckBuildStore? store;
    try {
      final deckConfig = await loadConfiguration();

      // Check if slides file exists
      if (!await deckConfig.slidesFile.exists()) {
        logger.err('Slides file not found: ${deckConfig.slidesFile.path}');
        logger.info(
          'Run `superdeck setup` to create a sample slides file, or create your own.',
        );

        return ExitCode.unavailable.code;
      }

      // Create the data store using the consolidated repository
      store = DeckBuildStore(configuration: deckConfig);
      await store.initialize();

      // Log if force rebuild is enabled
      if (boolArg('force-rebuild')) {
        logger.info('Force rebuild enabled. All assets will be regenerated.');
        // Clean assets directory
        if (await deckConfig.assetsDir.exists()) {
          await deckConfig.assetsDir.delete(recursive: true);
          await deckConfig.assetsDir.create(recursive: true);
        }
      }

      // Update pubspec assets unless skipped
      if (!boolArg('skip-pubspec')) {
        try {
          await _ensurePubspecAssets(deckConfig);
        } catch (e) {
          logger.warn('Failed to update pubspec assets: $e');
        }
      }

      // Run the build process initially
      final repository = store;
      final success = await _runBuild(repository, deckConfig);

      if (!success && !boolArg('watch')) {
        return ExitCode.software.code;
      }

      // Watch mode
      if (boolArg('watch')) {
        logger.info('');
        logger.info(
          'Watch mode enabled. Listening for changes in slides file.',
        );
        logger.info('');
        logger.info('Commands:');
        logger.info('  r - Rebuild presentation');
        logger.info('  f - Force rebuild (clear all assets and rebuild)');
        logger.info('  q - Quit watch mode');
        logger.info('');
        logger.info('Press Ctrl+C to stop watching.');
        logger.info('');

        // Create a builder that will handle watching and rebuilding
        final builder = _createStandardBuilder(
          configuration: deckConfig,
          store: repository,
        );

        // Listen to stdin for interactive commands
        StreamSubscription<String>? stdinSubscription;
        try {
          stdinSubscription = stdin
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen((line) async {
                final command = line.trim().toLowerCase();
                switch (command) {
                  case 'r':
                  case 'rebuild':
                    logger.info('Manual rebuild triggered...');
                    // Reuse the watch builder to avoid spawning extra browser instances
                    unawaited(
                      _runBuild(repository, deckConfig, builder: builder),
                    );
                    break;
                  case 'f':
                  case 'force-rebuild':
                    logger.info('Force rebuild triggered...');
                    // Reuse the watch builder to avoid spawning extra browser instances
                    unawaited(
                      _cleanAndRebuild(
                        repository,
                        deckConfig,
                        builder: builder,
                      ),
                    );
                    break;
                  case 'q':
                  case 'quit':
                    logger.info('Exiting watch mode...');
                    await stdinSubscription?.cancel();
                    await builder.dispose();
                    exit(ExitCode.success.code);
                  default:
                    logger.warn('Unknown command: "$command"');
                    logger.info(
                      'Available commands: r (rebuild), f (force-rebuild), q (quit)',
                    );
                }
              });

          // Start watching for changes and rebuilding when needed
          await for (final event in builder.watchAndBuild()) {
            switch (event) {
              case BuildStarted():
                logger.info('File change detected. Rebuilding presentation...');
              case BuildCompleted(:final slides):
                if (slides.isEmpty) {
                  logger.warn('No slides found in the deck.');
                } else {
                  logger.success('Generated ${slides.length} slides.');
                }
              case BuildFailed(:final error, :final stackTrace):
                logger.err('Error processing slides during watch.');
                _logBuildFailure(error, stackTrace);
            }
          }
        } finally {
          await stdinSubscription?.cancel();
          await builder.dispose();
        }
      }

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      logger.err('Build failed before the deck could be generated.');
      _logBuildFailure(e, stackTrace);
      await store?.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: e,
        stackTrace: stackTrace,
      );

      return ExitCode.software.code;
    }
  }

  @override
  String get description => 'Build SuperDeck presentations from markdown';

  @override
  String get name => 'build';
}

/// Ensures the pubspec.yaml has the necessary assets configuration.
Future<void> _ensurePubspecAssets(DeckConfiguration configuration) async {
  final progress = logger.progress('Checking pubspec.yaml assets...');

  try {
    final pubspecFile = configuration.pubspecFile;

    if (!await pubspecFile.exists()) {
      progress.fail('pubspec.yaml not found');
      logger.warn('pubspec.yaml not found at ${pubspecFile.path}');

      return;
    }

    final pubspecContents = await pubspecFile.readAsString();
    final updatedPubspecContents = updatePubspecAssets(
      configuration,
      pubspecContents,
    );

    if (updatedPubspecContents != pubspecContents) {
      await pubspecFile.writeAsString(updatedPubspecContents);
      progress.complete('Pubspec assets updated');
    } else {
      progress.complete('Pubspec assets already configured');
    }
  } catch (e) {
    progress.fail('Failed to update pubspec assets');
    logger.warn('Error updating pubspec: $e');
    rethrow;
  }
}
