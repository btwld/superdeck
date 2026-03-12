import 'package:superdeck_core/superdeck_core.dart';

final _logger = Logger('ConfigResolver');

DeckConfiguration resolveConfiguration(DeckConfiguration? override) {
  if (override != null) {
    _logger.info('Using explicit configuration override');
    return override;
  }

  try {
    final file = DeckConfiguration.defaultFile;
    if (!file.existsSync()) {
      _logger.info(
        'Configuration file not found at ${file.path}. Using default configuration',
      );
      return DeckConfiguration();
    }

    final content = file.readAsStringSync();
    final yamlMap = convertYamlToMap(content);
    final configuration = DeckConfiguration.parse(yamlMap);
    if (yamlMap.isEmpty) {
      _logger.info(
        'Configuration file at ${file.path} had no valid entries. Using default configuration',
      );
    } else {
      _logger.info('Resolved configuration from ${file.path}');
    }
    return configuration;
  } on Exception catch (error, stackTrace) {
    _logger.warning(
      'Failed to resolve configuration from superdeck.yaml. Using default configuration',
      error,
      stackTrace,
    );
    return DeckConfiguration();
  }
}
