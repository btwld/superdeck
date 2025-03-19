import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

class YamlUtils {
  const YamlUtils._();
  static Map<String, dynamic> convertYamlToMap(String yamlString) {
    if (yamlString.trim().isEmpty) return {};
    final yamlMap = loadYaml(yamlString, recover: true);

    if (yamlMap is YamlMap) {
      return jsonDecode(jsonEncode(yamlMap));
    } else {
      throw FormatException(
        'Invalid YAML format. $yamlString',
      );
    }
  }

  static Future<Map<String, dynamic>> loadYamlFile(File file) async {
    final yamlString = await file.readAsString();
    return convertYamlToMap(yamlString);
  }
}
