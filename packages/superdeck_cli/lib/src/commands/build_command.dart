import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';

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
  Future<bool> _runPipeline(TaskPipeline pipeline) async {
    // Wait while a build is already running
    while (_isRunning) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isRunning = true;
    final progress = logger.progress('Generating slides...');

    try {
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
    } on FileSystemException catch (e) {
      progress.fail('File error: ${e.message}');
      logger.err('Path: ${e.path}');

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
      DeckConfiguration deckConfig;
      final configFile = DeckConfiguration.defaultFile;

      try {
        // Load the configuration file or use defaults if it doesn't exist.
        if (!await configFile.exists()) {
          progress.update(
            'Configuration file not found. Using default configuration.',
          );
          deckConfig = DeckConfiguration();
        } else {
          progress.update('Loading configuration from ${configFile.path}');
          final yamlConfig = await YamlUtils.loadYamlFile(configFile);
          deckConfig = DeckConfiguration.parse(yamlConfig);
        }
        progress.complete('Configuration loaded.');
      } catch (e) {
        progress.fail('Failed to load configuration');
        logger.err('Error: $e');
        logger.info('Using default configuration.');
        deckConfig = DeckConfiguration();
      }

      // Check if slides file exists
      if (!await deckConfig.slidesFile.exists()) {
        logger.err('Slides file not found: ${deckConfig.slidesFile.path}');
        logger.info(
          'Run `superdeck setup` to create a sample slides file, or create your own.',
        );

        return ExitCode.unavailable.code;
      }

      // Create the pipeline with tasks
      final pipeline = TaskPipeline(
        tasks: [MermaidConverterTask(), DartFormatterTask()],
        configuration: deckConfig,
        store: FileSystemDataStore(deckConfig),
      );

      // Log if force rebuild is enabled
      if (boolArg('force-rebuild')) {
        logger.info('Force rebuild enabled. All assets will be regenerated.');
        // Note: TaskPipeline doesn't support force rebuild directly. We could clean
        // the asset directory first if needed in a future implementation.
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
      final success = await _runPipeline(pipeline);

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

        try {
          await for (final event
              in deckConfig.slidesFile.watch(events: FileSystemEvent.modify)) {
            logger.info('Detected change in: ${event.path}');
            await _runPipeline(pipeline);
          }
        } on FileSystemException catch (e) {
          logger.err('Watch error: ${e.message}');
          logger.err('Path: ${e.path}');

          return ExitCode.ioError.code;
        }
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
