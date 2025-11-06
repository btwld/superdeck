import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// Updates the 'assets' section of a pubspec.yaml file with superdeck paths.
///
/// This function takes a [yamlContent] string representing the contents of a
/// pubspec.yaml file. It parses the YAML, adds the '.superdeck/' and
/// '.superdeck/generated/' paths to the 'assets' section under the 'flutter'
/// key if they don't already exist, and returns the updated YAML as a string.
///
/// Returns the updated pubspec YAML content as a string.
String updatePubspecAssets(
  DeckConfiguration configuration,
  String pubspecContents,
) {
  final parsedYaml = _loadPubspecMap(pubspecContents);
  final flutterSection = _stringKeyedMap(
    parsedYaml['flutter'] as Map? ?? const <String, dynamic>{},
  );

  final assets = List<String>.from(
    (flutterSection['assets'] as List?)?.map((value) => value.toString()) ??
        const <String>[],
    growable: true,
  );
  final normalizedAssets = assets.map((asset) => p.normalize(asset)).toSet();

  var needsUpdate = false;
  void addAssetDirectory(String directoryPath) {
    final normalized = p.normalize(directoryPath);
    if (normalizedAssets.add(normalized)) {
      assets.add('$normalized/');
      needsUpdate = true;
    }
  }

  addAssetDirectory(configuration.superdeckDir.path);
  addAssetDirectory(configuration.assetsDir.path);

  if (!needsUpdate) {
    return pubspecContents;
  }

  flutterSection['assets'] = assets;

  final updatedYaml = Map<String, dynamic>.of(parsedYaml)
    ..['flutter'] = flutterSection;

  return YamlWriter(allowUnquotedStrings: true).write(updatedYaml);
}

Map<String, dynamic> _loadPubspecMap(String pubspecContents) {
  Object? yaml;
  try {
    yaml = loadYaml(pubspecContents);
  } on YamlException catch (error, stackTrace) {
    return _pubspecFormatException(
      'Failed to parse pubspec.yaml. Invalid YAML syntax. '
      'Please check your pubspec.yaml file. Error: $error',
      stackTrace,
    );
  }

  if (yaml is Map<Object?, Object?>) {
    return _stringKeyedMap(yaml);
  }

  return _pubspecFormatException(
    'Expected pubspec.yaml to define a map at the top level.',
    StackTrace.current,
  );
}

Map<String, dynamic> _stringKeyedMap(Map<Object?, Object?> source) {
  return source.map((key, value) {
    final stringKey = key?.toString();
    if (stringKey == null) {
      throw const FormatException('Encountered null key in pubspec.yaml map.');
    }

    return MapEntry(stringKey, value);
  });
}

Never _pubspecFormatException(String message, StackTrace stackTrace) {
  return Error.throwWithStackTrace(FormatException(message), stackTrace);
}
