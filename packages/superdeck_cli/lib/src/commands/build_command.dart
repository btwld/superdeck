import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:yaml/yaml.dart';

import '../helpers/logger.dart';
import '../helpers/update_pubspec.dart';

/// Command to build SuperDeck presentations
///
/// This command parses and processes the slides.md file,
/// generating all required assets and outputs for the presentation.
class BuildCommand extends Command<int> {
  /// Flag to track if a build is currently in progress
  bool _isRunning = false;

  /// Creates a new [BuildCommand] instance
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

  /// Runs the build pipeline with proper error handling and progress reporting
  Future<bool> _runPipeline(
    FileSystemPresentationRepository store,
    PresentationConfig config,
  ) async {
    // Wait while a build is already running
    while (_isRunning) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isRunning = true;
    final progress = logger.progress('Generating slides...');

    try {
      // Use the default pipeline from superdeck_builder instead of custom implementation
      final pipeline = getDefaultPipeline(config, store);

      // Listen for metrics to provide more detailed progress information
      final subscription = pipeline.metrics.listen((metrics) {
        progress.update(
          'Processing slide ${metrics.slideIndex + 1}: ${metrics.taskName}',
        );
      });

      try {
        // Run the pipeline
        final slides = await pipeline.run();

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
      } finally {
        // Cancel the subscription to prevent memory leaks
        subscription.cancel();
      }
    } on FileSystemException catch (e) {
      progress.fail('Build failed');
      logger.err('File system error: ${e.message}');
      logger.err('Path: ${e.path ?? 'Unknown'}');

      return false;
    } on FormatException catch (e) {
      progress.fail('Format error');
      logger.err(e.message);

      return false;
    } on Exception catch (e, stackTrace) {
      progress.fail('Build failed');
      logger.err('Error: ${e.toString()}');
      logger.detail(stackTrace.toString());

      return false;
    } finally {
      _isRunning = false;
    }
  }

  /// Returns the value of a boolean argument
  bool boolArg(String name) => argResults?[name] as bool? ?? false;

  @override
  Future<int> run() async {
    try {
      final progress = logger.progress('Loading configuration...');
      PresentationConfig deckConfig;
      final configFile = PresentationConfig.defaultFile;

      try {
        // Load the configuration file or use defaults if it doesn't exist.
        if (!await configFile.exists()) {
          progress.update(
            'Configuration file not found. Using default configuration.',
          );
          deckConfig = PresentationConfig();
        } else {
          progress.update('Loading configuration from ${configFile.path}');
          final yamlString = await configFile.readAsString();
          final yamlConfig = jsonDecode(jsonEncode(loadYaml(yamlString)));
          deckConfig = PresentationConfig.parse(yamlConfig);
        }
        progress.complete('Configuration loaded.');
      } catch (e) {
        progress.fail('Failed to load configuration');
        logger.err('Error: $e');
        logger.info('Using default configuration.');
        deckConfig = PresentationConfig();
      }

      // Check if slides file exists
      if (!await deckConfig.slidesFile.exists()) {
        logger.err('Slides file not found: ${deckConfig.slidesFile.path}');
        logger.info(
          'Run `superdeck setup` to create a sample slides file, or create your own.',
        );

        return ExitCode.unavailable.code;
      }

      // Create the data store
      final store = FileSystemPresentationRepository(deckConfig);
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

      // Run the pipeline initially
      final success = await _runPipeline(store, deckConfig);

      if (!success && !boolArg('watch')) {
        return ExitCode.software.code;
      }

      // Watch mode
      if (boolArg('watch')) {
        logger.info('');
        logger
            .info('Watch mode enabled. Listening for changes in slides file.');
        logger.info('Press Ctrl+C to stop watching.');
        logger.info('');

        // Create a pipeline that will handle watching and rebuilding
        final pipeline = getDefaultPipeline(deckConfig, store);

        // Start watching for changes and rebuilding when needed
        await pipeline.runAndWatch(
          onLog: (message) => logger.info(message),
          onSlidesProcessed: (slides) {
            if (slides.isEmpty) {
              logger.warn('No slides found in the deck.');
            } else {
              logger.success('Generated ${slides.length} slides.');
            }
          },
        );
      }

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      logger.err('Build failed: $e');
      logger.detail('$stackTrace');

      return ExitCode.software.code;
    }
  }

  @override
  String get description => 'Build SuperDeck presentations from markdown';

  @override
  String get name => 'build';
}

/// Ensures the pubspec.yaml has the necessary assets configuration
Future<void> _ensurePubspecAssets(
  PresentationConfig configuration,
) async {
  final progress = logger.progress('Checking pubspec.yaml assets...');

  try {
    final pubspecFile = configuration.pubspecFile;

    if (!await pubspecFile.exists()) {
      progress.fail('pubspec.yaml not found');
      logger.warn('pubspec.yaml not found at ${pubspecFile.path}');

      return;
    }

    final pubspecContents = await pubspecFile.readAsString();
    final updatedPubspecContents =
        updatePubspecAssets(configuration, pubspecContents);

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
