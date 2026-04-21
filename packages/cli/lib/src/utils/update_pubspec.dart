import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// Updates the 'assets' section of a pubspec.yaml with workspace paths.
String updatePubspecAssets(DeckWorkspace workspace, String pubspecContents) {
  final parsedYaml = parseYamlMap(pubspecContents, sourceLabel: 'pubspec.yaml');
  final flutterSection = Map<String, Object?>.from(
    parsedYaml['flutter'] as Map? ?? const <String, Object?>{},
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

  addAssetDirectory(workspace.superdeckDir.path);

  if (!needsUpdate) {
    return pubspecContents;
  }

  flutterSection['assets'] = assets;

  final updatedYaml = Map.of(parsedYaml)..['flutter'] = flutterSection;

  return YamlWriter(allowUnquotedStrings: true).write(updatedYaml);
}
