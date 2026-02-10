import 'package:superdeck_core/superdeck_core.dart';

DeckConfiguration resolveDeckConfiguration(DeckConfiguration? configuration) {
  if (configuration != null) {
    return configuration;
  }

  final logger = Logger('RuntimeConfiguration');
  final file = DeckConfiguration.defaultFile;

  if (!file.existsSync()) {
    return DeckConfiguration();
  }

  try {
    final yamlString = file.readAsStringSync();
    final yamlMap = convertYamlToMap(yamlString, strict: true);
    if (yamlMap.isEmpty) {
      return DeckConfiguration();
    }

    return DeckConfiguration.parse(yamlMap);
  } catch (error, stackTrace) {
    logger.warning(
      'Failed to load runtime configuration from ${file.path}. '
      'Falling back to defaults.',
      error,
      stackTrace,
    );
    return DeckConfiguration();
  }
}
