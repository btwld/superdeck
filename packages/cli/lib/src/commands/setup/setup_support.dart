import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:yaml_writer/yaml_writer.dart';

import '../../utils/constants.dart';
import 'setup_asset_support.dart';

const _managedBootstrapMarker = '// superdeck:managed bootstrap';
const _managedLoaderStyleStart =
    '<!-- superdeck:managed loader-style:start -->';
const _managedLoaderStyleEnd = '<!-- superdeck:managed loader-style:end -->';
const _managedLoaderBodyStart = '<!-- superdeck:managed loader-body:start -->';
const _managedLoaderBodyEnd = '<!-- superdeck:managed loader-body:end -->';

final _flutterBootstrapScriptPattern = RegExp(
  r"""<script[^>]+src=['"]flutter_bootstrap\.js['"][^>]*></script>""",
  caseSensitive: false,
);

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

Future<void> applySetup(Directory projectDir, Logger logger) async {
  final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw FileSystemException(
      'Failed to configure SuperDeck: pubspec.yaml not found. '
      'Run this command from a Flutter app root.',
      pubspecFile.path,
    );
  }

  final pubspecContents = await pubspecFile.readAsString();
  final pubspec = parseYamlMap(pubspecContents, sourceLabel: 'pubspec.yaml');
  final dependencies = pubspec['dependencies'];
  final flutterDependency = dependencies is Map
      ? dependencies['flutter']
      : null;
  final isFlutterApp =
      flutterDependency is Map && flutterDependency['sdk'] == 'flutter';
  if (!isFlutterApp) {
    throw FileSystemException(
      'Failed to configure SuperDeck: pubspec.yaml does not declare a '
      'Flutter SDK dependency. SuperDeck requires a Flutter app.',
      pubspecFile.path,
    );
  }

  await _ensureSuperdeckPlaceholders(projectDir);
  await pubspecFile.writeAsString(patchSetupPubspec(pubspecContents));

  final webDir = Directory(path.join(projectDir.path, 'web'));
  if (webDir.existsSync()) {
    await _applyWebSetup(projectDir);
  } else {
    logger.info(
      'Skipped web setup. Run `flutter create . --platforms web` and rerun '
      '`superdeck setup` to add the web loader.',
    );
  }

  final macosDir = Directory(path.join(projectDir.path, 'macos'));
  if (macosDir.existsSync()) {
    await _applyMacOsSetup(projectDir);
  } else {
    logger.info(
      'Skipped macOS setup. Run `flutter create . --platforms macos` and '
      'rerun `superdeck setup` to apply the required entitlements.',
    );
  }
}

String patchSetupPubspec(String pubspecContents) {
  final pubspec = parseYamlMap(pubspecContents, sourceLabel: 'pubspec.yaml');
  final dependencies = _mutableMap(pubspec['dependencies']);
  final devDependencies = _mutableMap(pubspec['dev_dependencies']);
  final flutter = _mutableMap(pubspec['flutter']);

  dependencies.putIfAbsent('superdeck', () => '^$packageVersion');
  devDependencies.putIfAbsent('superdeck_cli', () => '^$packageVersion');

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
  pubspec['dependencies'] = dependencies;
  pubspec['dev_dependencies'] = devDependencies;
  pubspec['flutter'] = flutter;

  return YamlWriter(allowUnquotedStrings: true).write(pubspec);
}

Future<String> patchSetupIndexHtml(
  String indexHtml, {
  required String assetsRoot,
}) async {
  final hasManagedStyle = indexHtml.contains(_managedLoaderStyleStart);
  final hasManagedBody = indexHtml.contains(_managedLoaderBodyStart);
  if (hasManagedStyle && hasManagedBody) {
    return indexHtml;
  }
  if (hasManagedStyle != hasManagedBody ||
      indexHtml.contains('id="flutter-loader"')) {
    throw const FormatException(
      'Failed to patch web/index.html: existing loader markup is not managed '
      'by SuperDeck. Merge the loader manually.',
    );
  }

  if (!_flutterBootstrapScriptPattern.hasMatch(indexHtml)) {
    throw const FormatException(
      'Failed to patch web/index.html: missing flutter_bootstrap.js script tag.',
    );
  }

  final loaderStyle = await File(
    path.join(assetsRoot, 'web', 'loader_style.html'),
  ).readAsString();
  final loaderBody = await File(
    path.join(assetsRoot, 'web', 'loader_body.html'),
  ).readAsString();
  final managedStyle =
      '$_managedLoaderStyleStart\n$loaderStyle\n$_managedLoaderStyleEnd';
  final managedBody =
      '$_managedLoaderBodyStart\n$loaderBody\n$_managedLoaderBodyEnd';

  final withStyle = _insertBeforeClosingTag(
    indexHtml,
    tagName: 'head',
    insertion: managedStyle,
    errorMessage: 'Failed to patch web/index.html: missing </head>.',
  );

  return _insertBeforeClosingTag(
    withStyle,
    tagName: 'body',
    insertion: managedBody,
    errorMessage: 'Failed to patch web/index.html: missing </body>.',
  );
}

String _insertBeforeClosingTag(
  String html, {
  required String tagName,
  required String insertion,
  required String errorMessage,
}) {
  final closingTag = RegExp('</$tagName>', caseSensitive: false);
  final match = closingTag.firstMatch(html);
  if (match == null) {
    throw FormatException(errorMessage);
  }

  return html.replaceRange(match.start, match.start, '$insertion\n');
}

Map<String, Object?> _mutableMap(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.from(value);
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

Future<void> _applyWebSetup(Directory projectDir) async {
  final assetsRoot = resolveSetupAssetsRoot();
  final indexHtmlFile = File(path.join(projectDir.path, 'web', 'index.html'));
  if (!indexHtmlFile.existsSync()) {
    throw FileSystemException(
      'Failed to patch web/index.html: file not found.',
      indexHtmlFile.path,
    );
  }
  final bootstrapFile = File(
    path.join(projectDir.path, 'web', 'flutter_bootstrap.js'),
  );
  final patchedIndexHtml = await patchSetupIndexHtml(
    await indexHtmlFile.readAsString(),
    assetsRoot: assetsRoot,
  );
  await _ensureBootstrapIsManagedOrMissing(bootstrapFile);

  await indexHtmlFile.writeAsString(patchedIndexHtml);

  final bootstrapSource = File(
    path.join(assetsRoot, 'web', 'flutter_bootstrap.js'),
  );
  await bootstrapFile.writeAsString(await bootstrapSource.readAsString());

  final svgSource = File(path.join(assetsRoot, 'web', 'superdeck_loader.svg'));
  final svgTarget = File(
    path.join(projectDir.path, 'web', 'superdeck_loader.svg'),
  );
  await svgSource.copy(svgTarget.path);
}

Future<void> _ensureBootstrapIsManagedOrMissing(File bootstrapFile) async {
  if (bootstrapFile.existsSync()) {
    final existingContents = await bootstrapFile.readAsString();
    if (!existingContents.contains(_managedBootstrapMarker)) {
      throw FileSystemException(
        'Failed to configure web/flutter_bootstrap.js: file already exists '
        'and is not managed by SuperDeck. Merge the loader bootstrap manually.',
        bootstrapFile.path,
      );
    }
  }
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
