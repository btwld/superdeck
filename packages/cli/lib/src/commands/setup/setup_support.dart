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

const _requiredAssets = ['.superdeck/', '.superdeck/assets/'];

Future<void> applySetup(Directory projectDir) async {
  final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw FileSystemException(
      'Failed to configure SuperDeck: pubspec.yaml not found. '
      'Run this command from a Flutter app root.',
      pubspecFile.path,
    );
  }

  final superdeckDir = Directory(path.join(projectDir.path, '.superdeck'));
  final assetsDir = Directory(path.join(superdeckDir.path, 'assets'));
  await assetsDir.create(recursive: true);
  await File(path.join(superdeckDir.path, '.gitkeep')).writeAsString('');
  await File(path.join(assetsDir.path, '.gitkeep')).writeAsString('');

  await pubspecFile.writeAsString(
    patchSetupPubspec(await pubspecFile.readAsString()),
  );

  final runnerDir = Directory(path.join(projectDir.path, 'macos', 'Runner'));
  if (runnerDir.existsSync()) {
    await _patchEntitlementsFile(
      File(path.join(runnerDir.path, 'DebugProfile.entitlements')),
      _debugEntitlements,
    );
    await _patchEntitlementsFile(
      File(path.join(runnerDir.path, 'Release.entitlements')),
      _releaseEntitlements,
    );
  }
}

String patchSetupPubspec(String pubspecContents) {
  final original = loadYaml(pubspecContents);
  if (original is! Map) {
    throw const FormatException('Expected pubspec.yaml to be a map.');
  }

  final pubspec = _toMutable(original) as Map<String, Object?>;
  final flutter = pubspec['flutter'] is Map<String, Object?>
      ? pubspec['flutter'] as Map<String, Object?>
      : <String, Object?>{};

  final assets = <String>[
    ...?(flutter['assets'] as List?)?.map((value) => value.toString()),
  ];
  var changed = false;
  for (final required in _requiredAssets) {
    if (!assets.contains(required)) {
      assets.add(required);
      changed = true;
    }
  }
  if (!changed) return pubspecContents;

  flutter['assets'] = assets;
  pubspec['flutter'] = flutter;
  return YamlWriter(allowUnquotedStrings: true).write(pubspec);
}

Object? _toMutable(Object? value) {
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), _toMutable(val)),
    );
  }
  if (value is List) {
    return value.map(_toMutable).toList();
  }
  return value;
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
