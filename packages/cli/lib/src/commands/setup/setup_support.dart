import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

const _debugEntitlements = <String, bool>{
  'com.apple.security.app-sandbox': false,
  'com.apple.security.cs.allow-jit': true,
  'com.apple.security.network.server': true,
  'com.apple.security.network.client': true,
  'com.apple.security.files.downloads.read-write': true,
  'com.apple.security.files.user-selected.read-write': true,
};

const _releaseEntitlements = <String, bool>{
  'com.apple.security.app-sandbox': true,
  'com.apple.security.files.user-selected.read-write': true,
  'com.apple.security.network.client': true,
  'com.apple.security.network.server': true,
  'com.apple.security.files.downloads.read-write': true,
};

Future<void> applySetup(Directory projectDir) async {
  final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw FileSystemException(
      'Failed to configure SuperDeck: pubspec.yaml not found. '
      'Run this command from a Flutter app root.',
      pubspecFile.path,
    );
  }

  await _ensureSuperdeckPlaceholders(projectDir);
  await pubspecFile.writeAsString(
    patchSetupPubspec(await pubspecFile.readAsString()),
  );

  final macosDir = Directory(path.join(projectDir.path, 'macos'));
  if (macosDir.existsSync()) {
    await _applyMacOsSetup(projectDir);
  }
}

String patchSetupPubspec(String pubspecContents) {
  final pubspec = _loadYamlMap(pubspecContents);
  final flutter = _mutableMap(pubspec['flutter']);

  final assets = List<String>.from(
    (flutter['assets'] as List?)?.map((value) => value.toString()) ??
        const <String>[],
    growable: true,
  );
  final normalizedAssets = assets.toSet();
  for (final asset in const ['.superdeck/', '.superdeck/assets/']) {
    if (normalizedAssets.add(asset)) {
      assets.add(asset);
    }
  }

  flutter['assets'] = assets;
  pubspec['flutter'] = flutter;

  return YamlWriter(allowUnquotedStrings: true).write(pubspec);
}

Map<String, Object?> _loadYamlMap(String contents) {
  final yaml = loadYaml(contents);
  if (yaml is! Map<Object?, Object?>) {
    throw const FormatException(
      'Expected generated YAML content to have a top-level map.',
    );
  }
  return _stringKeyedMap(yaml);
}

Map<String, Object?> _stringKeyedMap(Map<Object?, Object?> source) {
  return source.map((key, value) {
    final stringKey = key?.toString();
    if (stringKey == null) {
      throw const FormatException('Encountered a null YAML key.');
    }
    return MapEntry(stringKey, _normalizeYamlValue(value));
  });
}

Object? _normalizeYamlValue(Object? value) {
  if (value is Map<Object?, Object?>) {
    return _stringKeyedMap(value);
  }
  if (value is List) {
    return value.map(_normalizeYamlValue).toList();
  }
  return value;
}

Map<String, Object?> _mutableMap(Object? value) {
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map<Object?, Object?>) {
    return _stringKeyedMap(value);
  }
  return <String, Object?>{};
}

Future<void> _ensureSuperdeckPlaceholders(Directory projectDir) async {
  final superdeckDir = Directory(path.join(projectDir.path, '.superdeck'));
  final assetsDir = Directory(path.join(superdeckDir.path, 'assets'));
  await assetsDir.create(recursive: true);
  await File(path.join(superdeckDir.path, '.gitkeep')).writeAsString('');
  await File(path.join(assetsDir.path, '.gitkeep')).writeAsString('');
}

Future<void> _applyMacOsSetup(Directory projectDir) async {
  final runnerDir = path.join(projectDir.path, 'macos', 'Runner');
  await _patchEntitlementsFile(
    File(path.join(runnerDir, 'DebugProfile.entitlements')),
    _debugEntitlements,
  );
  await _patchEntitlementsFile(
    File(path.join(runnerDir, 'Release.entitlements')),
    _releaseEntitlements,
  );
}

Future<void> _patchEntitlementsFile(
  File file,
  Map<String, bool> entries,
) async {
  if (!file.existsSync()) {
    throw FileSystemException(
      'Failed to patch macOS entitlements: file not found.',
      file.path,
    );
  }
  await file.writeAsString(
    patchSetupEntitlements(await file.readAsString(), entries),
  );
}

String patchSetupEntitlements(
  String entitlementsContents,
  Map<String, bool> requiredEntries,
) {
  if (!entitlementsContents.contains('</dict>')) {
    throw const FormatException(
      'Failed to patch macOS entitlements: missing </dict>.',
    );
  }

  var updatedContents = entitlementsContents;
  for (final entry in requiredEntries.entries) {
    final keyPattern = RegExp(
      '<key>${RegExp.escape(entry.key)}</key>\\s*<(?:true|false)\\s*/>',
      multiLine: true,
    );
    final replacement =
        '\t<key>${entry.key}</key>\n\t<${entry.value ? 'true' : 'false'}/>';
    if (keyPattern.hasMatch(updatedContents)) {
      updatedContents = updatedContents.replaceFirst(keyPattern, replacement);
      continue;
    }
    updatedContents = updatedContents.replaceFirst(
      '</dict>',
      '$replacement\n</dict>',
    );
  }

  return updatedContents;
}
