import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:yaml/yaml.dart';

/// Base class for SuperDeck commands with common functionality
abstract class SuperDeckCommand extends Command<int> {
  final Logger logger;

  SuperDeckCommand({Logger? loggerOverride})
    : logger = loggerOverride ?? Logger();

  /// Loads the Superdeck configuration from the default file
  /// or returns a default configuration if the file doesn't exist
  Future<DeckWorkspace> loadConfiguration() async {
    final progress = logger.progress('Loading configuration...');
    final configFile = DeckWorkspace.defaultFile;

    try {
      // Load the configuration file or use defaults if it doesn't exist.
      if (!await configFile.exists()) {
        progress.update(
          'Configuration file not found. Using default configuration.',
        );

        return DeckWorkspace();
      }

      progress.update('Loading configuration from ${configFile.path}');
      final yamlString = await configFile.readAsString();
      final yamlData = loadYaml(yamlString);

      // Handle empty/comment-only YAML files
      if (yamlData == null) {
        return DeckWorkspace();
      }

      final yamlConfig = jsonDecode(jsonEncode(yamlData));
      final config = DeckWorkspace.parse(yamlConfig);
      progress.complete('Configuration loaded.');

      return config;
    } on YamlException catch (e) {
      // YAML syntax error - fail loudly
      progress.fail('Invalid configuration file');
      logger.err('YAML syntax error in ${configFile.path}:');
      logger.err('  ${e.message}');
      logger.err('Please fix your superdeck.yaml syntax.');
      rethrow;
    } on FormatException catch (e) {
      // Configuration parsing error - fail loudly
      progress.fail('Invalid configuration');
      logger.err('Configuration error: ${e.message}');
      rethrow;
    } catch (e) {
      // Unexpected error - fail loudly
      progress.fail('Failed to load configuration');
      logger.err('Unexpected error: $e');
      rethrow;
    }
  }
}
