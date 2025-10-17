import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_core/superdeck_core.dart' hide logger;
import 'package:yaml/yaml.dart';

/// Base class for Superdeck commands with common functionality
abstract class SuperdeckCommand extends Command<int> {
  final Logger logger;

  SuperdeckCommand({Logger? loggerOverride})
    : logger = loggerOverride ?? Logger();

  /// Loads the Superdeck configuration from the default file
  /// or returns a default configuration if the file doesn't exist
  Future<DeckConfiguration> loadConfiguration() async {
    final progress = logger.progress('Loading configuration...');
    final configFile = DeckConfiguration.defaultFile;

    try {
      // Load the configuration file or use defaults if it doesn't exist.
      if (!await configFile.exists()) {
        progress.update(
          'Configuration file not found. Using default configuration.',
        );

        return DeckConfiguration();
      }

      progress.update('Loading configuration from ${configFile.path}');
      final yamlString = await configFile.readAsString();
      final yamlData = loadYaml(yamlString);

      // Handle empty/comment-only YAML files
      if (yamlData == null) {
        return DeckConfiguration();
      }

      final yamlConfig = jsonDecode(jsonEncode(yamlData));
      final config = DeckConfiguration.parse(yamlConfig);
      progress.complete('Configuration loaded.');

      return config;
    } catch (e) {
      progress.fail('Failed to load configuration');
      logger.err('Error: $e');
      logger.info('Using default configuration.');

      return DeckConfiguration();
    }
  }
}
