import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Loads a YAML file and returns the parsed content
Future<dynamic> loadYamlFile(String path) async {
  final file = File(path);

  if (!await file.exists()) {
    throw FileSystemException('YAML file not found', path);
  }

  final content = await file.readAsString();
  return loadYaml(content);
}

/// Checks if a file is a YAML file based on its extension
bool isYamlFile(String path) {
  final extension = p.extension(path).toLowerCase();
  return extension == '.yaml' || extension == '.yml';
}

/// Converts YAML string to a `Map<String, dynamic>`
///
/// Supports both block-style and flow-style YAML:
/// - Block-style: `key1: value1\nkey2: value2`
/// - Flow-style: `{key1: value1, key2: value2}`
Map<String, dynamic> convertYamlToMap(
  String yamlString, {
  bool strict = false,
}) {
  if (yamlString.trim().isEmpty) return {};

  try {
    final yamlDoc = loadYaml(yamlString);
    if (yamlDoc == null) return {};

    final converted = _deepConvert(yamlDoc);
    return converted is Map ? converted as Map<String, dynamic> : {};
  } on YamlException {
    if (strict) rethrow;
    return {};
  } catch (e) {
    if (strict) rethrow;
    // Return empty map on parse error
    return {};
  }
}

/// Recursively converts YAML types (YamlMap, YamlList) to plain Dart types
dynamic _deepConvert(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map(
        (e) => MapEntry(e.key.toString(), _deepConvert(e.value)),
      ),
    );
  } else if (value is List) {
    return value.map(_deepConvert).toList();
  }
  return value;
}

/// Normalizes a YAML block by trimming surrounding empty lines and
/// removing the minimum common indentation.
String normalizeYamlBlock(String text) {
  if (text.isEmpty) return '';

  final lines = text.split('\n');

  int firstContent = 0;
  while (firstContent < lines.length && lines[firstContent].trim().isEmpty) {
    firstContent++;
  }

  int lastContent = lines.length - 1;
  while (lastContent >= firstContent && lines[lastContent].trim().isEmpty) {
    lastContent--;
  }

  if (firstContent > lastContent) {
    return '';
  }

  final trimmedLines = lines.sublist(firstContent, lastContent + 1);

  int? indent;
  for (final line in trimmedLines) {
    if (line.trim().isEmpty) continue;
    final lineIndent = line.length - line.trimLeft().length;
    if (indent == null || lineIndent < indent) {
      indent = lineIndent;
    }
    if (indent == 0) break;
  }

  final dedent = indent ?? 0;

  return trimmedLines
      .map((line) {
        if (line.trim().isEmpty) return '';
        if (dedent == 0) return line;
        if (line.length <= dedent) {
          return line.trimLeft();
        }
        return line.substring(dedent);
      })
      .join('\n');
}
