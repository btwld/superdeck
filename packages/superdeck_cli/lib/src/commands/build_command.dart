import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator_pipeline.dart';
import '../helpers/exceptions.dart';
import '../helpers/extensions.dart';
import '../helpers/logger.dart';
import '../helpers/update_pubspec.dart';
import '../tasks/dart_formatter_task.dart';
import '../tasks/mermaid_task.dart';
import 'package:superdeck_core/superdeck_core.dart';

class BuildCommand extends Command<int> {
  bool _isRunning = false;

  BuildCommand() {
    argParser.addFlag(
      'watch',
      abbr: 'w',
      help: 'Watch for changes and build the deck',
    );
  }

  Future<void> _runPipeline(TaskPipeline pipeline) async {
    // wait wihle _isRunning is true
    while (_isRunning) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _isRunning = true;
    final progress = logger.progress('Generating slides...');
    try {
      final slides = await pipeline.run();
      progress.complete('Generated ${slides.length} slides.');
    } on Exception catch (e, stackTrace) {
      progress.fail();
      printException(e);

      logger.detail(stackTrace.toString());
    } finally {
      _isRunning = false;
    }
  }

  @override
  Future<int> run() async {
    final configFile = DeckConfiguration.defaultFile;
    DeckConfiguration deckConfig;

    // Load the configuration file or use defaults if it doesn't exist.
    if (!await configFile.exists()) {
      logger.warn(
        'Configuration file not found. Using default configuration.',
      );
      deckConfig = DeckConfiguration();
    } else {
      logger.info('Loading configuration from ${configFile.path}');
      final yamlConfig = await YamlUtils.loadYamlFile(configFile);
      deckConfig = DeckConfiguration.parse(yamlConfig);
      logger.info('Configuration loaded successfully.');
    }

    final pipeline = TaskPipeline(
      tasks: [MermaidConverterTask(), DartFormatterTask()],
      configuration: deckConfig,
      store: FileSystemDataStore(deckConfig),
    );
    final watch = boolArg('watch');

    // Update pubspec assets and log the update.
    await _ensurePubspecAssets(deckConfig);

    // Run the pipeline initially.
    await _runPipeline(pipeline);

    // If watch mode is enabled, subscribe to file modifications.
    if (watch) {
      logger.info(
        'Watch mode enabled. Listening for changes in slides markdown file.',
      );

      await for (final event in pipeline.store.configuration.slidesFile
          .watch(events: FileSystemEvent.modify)) {
        try {
          logger.info('Detected modification in file: ${event.path}');
          await _runPipeline(pipeline);
        } on Exception catch (e, stackTrace) {
          logger.err('Error processing file: $e');
          logger.detail(stackTrace.toString());
        }
      }
    }

    return ExitCode.success.code;
  }

  @override
  String get description => 'Build the deck';

  @override
  String get name => 'build';
}

Future<void> _ensurePubspecAssets(DeckConfiguration configuration) async {
  final pubspecContents = await configuration.pubspecFile.readAsString();
  final updatedPubspecContents =
      updatePubspecAssets(configuration, pubspecContents);
  if (updatedPubspecContents != pubspecContents) {
    await configuration.pubspecFile.writeAsString(updatedPubspecContents);
    logger.info('Pubspec assets updated.');
  }
}
