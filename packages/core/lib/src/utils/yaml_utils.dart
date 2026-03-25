import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

final _logger = Logger('YamlUtils');

/// Converts YAML string to a `Map<String, Object?>`
///
/// Supports both block-style and flow-style YAML:
/// - Block-style: `key1: value1\nkey2: value2`
/// - Flow-style: `{key1: value1, key2: value2}`
Map<String, Object?> convertYamlToMap(
  String yamlString, {
  bool strict = false,
}) {
  if (yamlString.trim().isEmpty) return {};

  try {
    final yamlDoc = loadYaml(yamlString);
    if (yamlDoc == null) return {};

    final converted = _deepConvert(yamlDoc);
    return converted is Map ? converted as Map<String, Object?> : {};
  } on YamlException catch (e) {
    _logger.warning(
      'Invalid YAML syntax in options: "$yamlString". '
      'Error: $e. Using empty options map. '
      'Check your fenced code block syntax for typos.',
    );
    if (strict) rethrow;
    return {};
  } catch (e, stackTrace) {
    _logger.severe(
      'Unexpected error parsing YAML options: "$yamlString"',
      e,
      stackTrace,
    );
    if (strict) rethrow;
    return {};
  }
}

/// Recursively converts YAML types (YamlMap, YamlList) to plain Dart types
dynamic _deepConvert(dynamic value) {
  if (value is Map) {
    return Map<String, Object?>.fromEntries(
      value.entries.map(
        (e) => MapEntry(e.key.toString(), _deepConvert(e.value)),
      ),
    );
  } else if (value is List) {
    return value.map(_deepConvert).toList();
  }
  return value;
}
