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
  // Parse the YAML content into a map
  dynamic parsedYaml;
  try {
    parsedYaml = loadYaml(pubspecContents);
  } on YamlException catch (e) {
    throw Exception(
      'Failed to parse pubspec.yaml. Invalid YAML syntax. '
      'Please check your pubspec.yaml file. Error: $e',
    );
  }

  // Get the 'flutter' section from the parsed YAML, or an empty map if it doesn't exist
  final flutterSection =
      // ignore: avoid-dynamic
      {...(parsedYaml['flutter'] ?? {}) as Map}.cast<String, dynamic>();

  // Get the 'assets' list from the 'flutter' section, or an empty list if it doesn't exist
  final assets = flutterSection['assets']?.toList() ?? [];

  bool needsUpdate = false;

  try {
    // Normalize existing asset paths for comparison (e.g., .superdeck/ vs ./.superdeck/)
    final normalizedAssets = assets.map((a) => p.normalize(a.toString())).toList();

    // Always use normalized paths without ./ prefix for consistency
    final superDeckAssetPath = p.normalize(configuration.superdeckDir.path);
    final superDeckAssetEntry = '$superDeckAssetPath/';

    if (!normalizedAssets.contains(superDeckAssetPath)) {
      assets.add(superDeckAssetEntry);
      needsUpdate = true;
    }

    final assetsPath = p.normalize(configuration.assetsDir.path);
    final assetsEntry = '$assetsPath/';

    if (!normalizedAssets.contains(assetsPath)) {
      assets.add(assetsEntry);
      needsUpdate = true;
    }
  } catch (e) {
    throw Exception(
      'Failed to normalize asset paths. '
      'Check your superdeck directory configuration. Error: $e',
    );
  }

  if (!needsUpdate) {
    return pubspecContents;
  }

  // Update the 'assets' key in the 'flutter' section with the modified assets list
  flutterSection['assets'] = assets;

  // Create a new map from the parsed YAML and update the 'flutter' key with the modified section
  final updatedYaml = Map<String, dynamic>.from(parsedYaml)
    ..['flutter'] = flutterSection;

  // Convert the updated YAML map back to a string and return it
  return YamlWriter(allowUnquotedStrings: true).write(updatedYaml);
}
