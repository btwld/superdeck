import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

import '../../utils/constants.dart';
import '../publish/build_support.dart';

const legacyWorkspaceConfigPath = 'superdeck.yaml';

const createScaffoldPaths = <String>[
  '.gitignore',
  '.superdeck',
  'README.md',
  'analysis_options.yaml',
  'android',
  'ios',
  'lib',
  'linux',
  'macos',
  'pubspec.yaml',
  'slides.md',
  'test',
  'web',
  'windows',
];

const refreshManagedPaths = <String>[
  '.superdeck/',
  'pubspec.yaml',
  'README.md (starter copy only)',
  'slides.md (starter copy only)',
  'web/index.html',
  'web/superdeck_loader.svg',
];

const refreshPreservedPaths = <String>[
  'android/',
  'ios/',
  'lib/',
  'linux/',
  'macos/',
  'test/',
  'windows/',
  'custom files in web/',
];

const generatedReadmeMarker = '<!-- superdeck:managed readme -->';
const generatedSlidesMarker = '<!-- superdeck:managed slides -->';

final _flutterBootstrapScriptPattern = RegExp(
  r"""<script[^>]+src=['"]flutter_bootstrap\.js['"][^>]*></script>""",
  caseSensitive: false,
);

typedef CreateScaffoldBuilder =
    Future<Directory> Function(Directory tempRoot, CreateBindings bindings);

class CreateBindings {
  final String projectName;
  final String displayName;

  const CreateBindings({
    required this.projectName,
    required this.displayName,
  });

  factory CreateBindings.fromTargetName(String targetName) {
    final projectName = _sanitizeProjectName(targetName);
    final displayName = _displayNameFor(projectName);

    return CreateBindings(
      projectName: projectName,
      displayName: displayName,
    );
  }
}

Future<Directory> buildStarterScaffold(
  Directory tempRoot, {
  required CreateBindings bindings,
  required String workingDirectory,
  CreateScaffoldBuilder? scaffoldBuilder,
  String? loaderAssetPath,
}) async {
  final scaffoldDir = scaffoldBuilder != null
      ? await scaffoldBuilder(tempRoot, bindings)
      : await _runFlutterCreate(
          tempRoot,
          bindings: bindings,
          workingDirectory: workingDirectory,
        );

  await _applyOverlay(
    scaffoldDir,
    bindings: bindings,
    loaderAssetPath: loaderAssetPath,
  );

  return scaffoldDir;
}

bool isExistingNonEmptyDirectory(Directory directory) {
  return directory.existsSync() && directory.listSync().isNotEmpty;
}

Future<void> copyCreateScaffold(
  Directory scaffoldDir,
  Directory targetDir,
) async {
  await targetDir.create(recursive: true);

  for (final entry in createScaffoldPaths) {
    final sourcePath = path.join(scaffoldDir.path, entry);
    final targetPath = path.join(targetDir.path, entry);
    await _copyScaffoldPath(sourcePath, targetPath);
  }
}

Future<void> refreshManagedOverlay(
  Directory scaffoldDir,
  Directory targetDir,
) async {
  await _deleteIfExists(path.join(targetDir.path, legacyWorkspaceConfigPath));
  await _ensureSuperdeckPlaceholders(targetDir);

  await _refreshManagedTextFile(
    source: File(path.join(scaffoldDir.path, 'README.md')),
    target: File(path.join(targetDir.path, 'README.md')),
    marker: generatedReadmeMarker,
  );
  await _refreshManagedTextFile(
    source: File(path.join(scaffoldDir.path, 'slides.md')),
    target: File(path.join(targetDir.path, 'slides.md')),
    marker: generatedSlidesMarker,
  );

  final pubspecFile = File(path.join(targetDir.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw FileSystemException(
      'Failed to refresh SuperDeck starter files: pubspec.yaml not found.',
      pubspecFile.path,
    );
  }
  await pubspecFile.writeAsString(
    _patchPubspec(await pubspecFile.readAsString()),
  );

  final indexHtmlFile = File(path.join(targetDir.path, 'web', 'index.html'));
  if (!indexHtmlFile.existsSync()) {
    throw const FormatException(
      'Failed to refresh starter web files: expected web/index.html in the target app.',
    );
  }
  await indexHtmlFile.writeAsString(
    _patchIndexHtml(await indexHtmlFile.readAsString()),
  );

  final sourceLoader = File(
    path.join(scaffoldDir.path, 'web', 'superdeck_loader.svg'),
  );
  final targetLoader = File(
    path.join(targetDir.path, 'web', 'superdeck_loader.svg'),
  );
  await targetLoader.parent.create(recursive: true);
  await sourceLoader.copy(targetLoader.path);
  await _copyFileMode(sourceLoader, targetLoader);
}

String describeRefreshChanges(Directory targetDir) {
  final items = <String>[...refreshManagedPaths];
  if (File(path.join(targetDir.path, legacyWorkspaceConfigPath)).existsSync()) {
    items.add(legacyWorkspaceConfigPath);
  }
  items.sort();
  return items.join(', ');
}

String describeRefreshPreserved() => refreshPreservedPaths.join(', ');

Future<String> resolveLoaderAssetPath({String? overridePath}) async {
  if (overridePath != null) {
    return path.absolute(overridePath);
  }

  final packageRoot = await _resolvePackageRoot();
  return path.join(packageRoot, 'tool', 'assets', 'superdeck_loader.svg');
}

Future<Directory> _runFlutterCreate(
  Directory tempRoot, {
  required CreateBindings bindings,
  required String workingDirectory,
}) async {
  final flutter = resolveFlutterBinary(workingDirectory);
  final arguments = <String>[
    'create',
    '--platforms=web,macos,windows,linux,android,ios',
    '--org',
    'com.example',
    bindings.projectName,
  ];
  final result = await Process.run(
    flutter,
    arguments,
    workingDirectory: tempRoot.path,
  );

  if (result.exitCode != 0) {
    stderr
      ..writeln(result.stdout)
      ..writeln(result.stderr);
    throw ProcessException(
      flutter,
      arguments,
      result.stderr.toString(),
      result.exitCode,
    );
  }

  return Directory(path.join(tempRoot.path, bindings.projectName));
}

Future<void> _applyOverlay(
  Directory scaffoldDir, {
  required CreateBindings bindings,
  String? loaderAssetPath,
}) async {
  final resolvedLoaderAssetPath = await resolveLoaderAssetPath(
    overridePath: loaderAssetPath,
  );

  await File(
    path.join(scaffoldDir.path, 'README.md'),
  ).writeAsString(_readme(bindings));
  await File(
    path.join(scaffoldDir.path, 'slides.md'),
  ).writeAsString(_slides(bindings));
  await File(
    path.join(scaffoldDir.path, 'lib', 'main.dart'),
  ).writeAsString(_mainDart);
  await File(
    path.join(scaffoldDir.path, 'lib', 'web_loader_stub.dart'),
  ).writeAsString(_webLoaderStub);
  await File(
    path.join(scaffoldDir.path, 'lib', 'web_loader_web.dart'),
  ).writeAsString(_webLoaderWeb);
  final noteCardFile = File(
    path.join(scaffoldDir.path, 'lib', 'widgets', 'note_card.dart'),
  );
  await noteCardFile.parent.create(recursive: true);
  await noteCardFile.writeAsString(_noteCardDart);
  await File(
    path.join(scaffoldDir.path, 'test', 'widget_test.dart'),
  ).writeAsString(_widgetTest(bindings));

  await _ensureSuperdeckPlaceholders(scaffoldDir);

  final indexHtmlFile = File(path.join(scaffoldDir.path, 'web', 'index.html'));
  await indexHtmlFile.writeAsString(
    _patchIndexHtml(await indexHtmlFile.readAsString()),
  );
  await File(
    path.join(scaffoldDir.path, 'web', 'superdeck_loader.svg'),
  ).writeAsString(await File(resolvedLoaderAssetPath).readAsString());

  final pubspecFile = File(path.join(scaffoldDir.path, 'pubspec.yaml'));
  await pubspecFile.writeAsString(
    _patchPubspec(await pubspecFile.readAsString()),
  );
}

Future<void> _ensureSuperdeckPlaceholders(Directory targetDir) async {
  final superdeckDir = Directory(path.join(targetDir.path, '.superdeck'));
  final assetsDir = Directory(path.join(superdeckDir.path, 'assets'));
  await assetsDir.create(recursive: true);
  await File(path.join(superdeckDir.path, '.gitkeep')).writeAsString('');
  await File(path.join(assetsDir.path, '.gitkeep')).writeAsString('');
}

Future<void> _refreshManagedTextFile({
  required File source,
  required File target,
  required String marker,
}) async {
  if (!target.existsSync()) {
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    await _copyFileMode(source, target);
    return;
  }

  final existingContents = await target.readAsString();
  if (!existingContents.contains(marker)) {
    return;
  }

  await target.writeAsString(await source.readAsString());
  await _copyFileMode(source, target);
}

String _patchPubspec(String pubspecContents) {
  final pubspec = _loadYamlMap(pubspecContents);
  final dependencies = _mutableMap(pubspec['dependencies']);
  final devDependencies = _mutableMap(pubspec['dev_dependencies']);
  final flutter = _mutableMap(pubspec['flutter']);

  dependencies['superdeck'] = '^$packageVersion';
  devDependencies['superdeck_cli'] = '^$packageVersion';

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

String _patchIndexHtml(String indexHtml) {
  if (indexHtml.contains('id="flutter-loader"')) {
    return indexHtml;
  }

  if (!_flutterBootstrapScriptPattern.hasMatch(indexHtml)) {
    throw const FormatException(
      'Failed to patch web/index.html: missing flutter_bootstrap.js script tag.',
    );
  }

  final withStyle = _insertBeforeClosingTag(
    indexHtml,
    tagName: 'head',
    insertion: _loaderStyles,
    errorMessage: 'Failed to patch web/index.html: missing </head>.',
  );

  return _insertBeforeClosingTag(
    withStyle,
    tagName: 'body',
    insertion: '$_loaderMarkup\n$_loaderScript',
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

Future<String> _resolvePackageRoot() async {
  final packageUri = await Isolate.resolvePackageUri(
    Uri.parse('package:superdeck_cli/runner.dart'),
  );
  if (packageUri == null) {
    throw const FileSystemException(
      'Failed to resolve the superdeck_cli package root.',
    );
  }

  final libPath = path.dirname(packageUri.toFilePath());
  return path.dirname(libPath);
}

Future<void> _copyScaffoldPath(String sourcePath, String targetPath) async {
  final sourceType = FileSystemEntity.typeSync(sourcePath, followLinks: false);

  switch (sourceType) {
    case FileSystemEntityType.directory:
      await _copyDirectory(Directory(sourcePath), Directory(targetPath));
      return;
    case FileSystemEntityType.file:
    case FileSystemEntityType.link:
      final sourceFile = File(sourcePath);
      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);
      await sourceFile.copy(targetFile.path);
      await _copyFileMode(sourceFile, targetFile);
      return;
    case FileSystemEntityType.notFound:
      return;
    default:
      throw FileSystemException(
        'Unsupported scaffold entity type: $sourceType',
        sourcePath,
      );
  }
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);

  await for (final entity in source.list(recursive: true)) {
    final relativePath = path.relative(entity.path, from: source.path);
    final targetPath = path.join(destination.path, relativePath);

    if (entity is Directory) {
      await Directory(targetPath).create(recursive: true);
      continue;
    }

    if (entity is File) {
      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);
      await entity.copy(targetFile.path);
      await _copyFileMode(entity, targetFile);
      continue;
    }

    if (entity is Link) {
      final targetLink = Link(targetPath);
      await targetLink.parent.create(recursive: true);
      await targetLink.create(await entity.target(), recursive: true);
    }
  }
}

Future<void> _copyFileMode(File source, File destination) async {
  if (Platform.isWindows) {
    return;
  }

  final mode = source.statSync().mode & 0x1FF;
  final result = await Process.run('chmod', [_toOctal(mode), destination.path]);
  if (result.exitCode != 0) {
    throw ProcessException(
      'chmod',
      [_toOctal(mode), destination.path],
      result.stderr.toString(),
      result.exitCode,
    );
  }
}

String _toOctal(int mode) => mode.toRadixString(8).padLeft(3, '0');

Future<void> _deleteIfExists(String location) async {
  final type = FileSystemEntity.typeSync(location, followLinks: false);
  switch (type) {
    case FileSystemEntityType.file:
      await File(location).delete();
      return;
    case FileSystemEntityType.link:
      await Link(location).delete();
      return;
    case FileSystemEntityType.directory:
      await Directory(location).delete(recursive: true);
      return;
    case FileSystemEntityType.notFound:
      return;
    default:
      throw FileSystemException(
        'Unsupported filesystem entity type: $type',
        location,
      );
  }
}

String _sanitizeProjectName(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  final projectName = normalized.isEmpty
      ? 'superdeck_presentation'
      : normalized;
  if (RegExp(r'^[0-9]').hasMatch(projectName)) {
    return 'superdeck_$projectName';
  }
  return projectName;
}

String _displayNameFor(String projectName) {
  final words = projectName
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}');
  return words.join(' ');
}

String _readme(CreateBindings bindings) =>
    '''$generatedReadmeMarker
# ${bindings.displayName}

Build slides in `slides.md` and render them with Flutter.

## Start here

1. Run `flutter pub get`
2. Run `dart run superdeck_cli:main build`
3. Run `flutter run`

## Customize it

- Update `slides.md`
- Replace `lib/widgets/note_card.dart` with your own widget
- Update `web/` if you want a different loading screen
''';

String _slides(CreateBindings bindings) =>
    '''---
title: ${bindings.displayName}
---

<!-- superdeck:managed slides -->

@block {
  align: center
}

# ${bindings.displayName}

Build presentations with Markdown, Flutter, and SuperDeck.

---
---

@note-card {
  title: "Sample widget"
  message: "Replace lib/widgets/note_card.dart with your own widget when you need custom UI."
}

---
---

@block

## Next steps

1. Run `dart run superdeck_cli:main build`
2. Run `flutter run`
3. Edit `slides.md`
4. Replace `lib/widgets/note_card.dart` with your own widgets
''';

const _mainDart = '''import 'package:flutter/material.dart';
import 'package:superdeck/superdeck.dart';

import 'web_loader_stub.dart'
    if (dart.library.js_interop) 'web_loader_web.dart';
import 'widgets/note_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SuperDeckApp.initialize();
  runApp(const PresentationApp());
  scheduleHideWebLoader();
}

class PresentationApp extends StatelessWidget {
  const PresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperDeckApp(
      options: DeckOptions(
        widgets: {'note-card': noteCardWidget},
      ),
    );
  }
}
''';

const _webLoaderStub = 'void scheduleHideWebLoader() {}\n';

const _webLoaderWeb = '''import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';

void scheduleHideWebLoader() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!globalContext.has('hideFlutterLoader')) return;

    final hideFlutterLoader = globalContext['hideFlutterLoader'] as JSFunction;
    hideFlutterLoader.callAsFunction(globalContext);
  });
}
''';

const _noteCardDart = '''import 'package:flutter/material.dart';

Widget noteCardWidget(Map<String, Object?> args) {
  final title = args['title'] as String? ?? 'Custom Widget';
  final message =
      args['message'] as String? ??
      'Replace lib/widgets/note_card.dart with your own widget.';

  return NoteCard(title: title, message: message);
}

class NoteCard extends StatelessWidget {
  final String title;
  final String message;

  const NoteCard({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
''';

String _widgetTest(CreateBindings bindings) =>
    '''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:${bindings.projectName}/widgets/note_card.dart';

void main() {
  testWidgets('note card renders the provided content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NoteCard(
            title: 'Hello',
            message: 'World',
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);
  });
}
''';

const _loaderStyles = '''  <style>
    html,
    body {
      height: 100%;
    }

    body {
      margin: 0;
    }

    #flutter-loader {
      position: fixed;
      inset: 0;
      display: grid;
      place-items: center;
      background:
        radial-gradient(circle at top, #17314d 0%, #09121b 45%, #05080d 100%);
      opacity: 1;
      transition: opacity 180ms ease-out, visibility 180ms ease-out;
      z-index: 9999;
    }

    #flutter-loader.is-hidden {
      opacity: 0;
      visibility: hidden;
    }

    #flutter-loader img {
      width: min(144px, 22vw);
      height: auto;
      display: block;
    }

    #flutter-loader-copy {
      margin: 18px 0 0;
      color: rgba(255, 255, 255, 0.82);
      font:
        500 15px/1.4 system-ui,
        -apple-system,
        BlinkMacSystemFont,
        "Segoe UI",
        sans-serif;
      letter-spacing: 0.02em;
      text-align: center;
    }

    #flutter-loader-copy.is-error {
      color: #ffe7e0;
      max-width: 24rem;
    }
  </style>''';

const _loaderMarkup = '''  <div id="flutter-loader" aria-hidden="true">
    <div>
      <img src="superdeck_loader.svg" alt="" width="144" height="163">
      <p id="flutter-loader-copy">Loading presentation…</p>
    </div>
  </div>''';

const _loaderScript = '''  <script>
    const loader = document.getElementById('flutter-loader');
    const loaderCopy = document.getElementById('flutter-loader-copy');
    const loaderErrorTimeout = window.setTimeout(() => {
      if (!loader || !loaderCopy || loader.classList.contains('is-hidden')) {
        return;
      }

      loaderCopy.classList.add('is-error');
      loaderCopy.textContent = 'Startup is taking longer than expected. Refresh the page or check the browser console.';
    }, 15000);

    window.hideFlutterLoader = function () {
      if (!loader) return;

      window.clearTimeout(loaderErrorTimeout);
      loader.classList.add('is-hidden');
      window.setTimeout(() => loader.remove(), 220);
    };
  </script>''';
