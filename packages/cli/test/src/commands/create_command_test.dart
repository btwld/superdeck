import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/create/create_support.dart';
import 'package:superdeck_cli/src/commands/create_command.dart';
import 'package:superdeck_cli/src/commands/publish/build_support.dart';
import 'package:superdeck_cli/src/utils/constants.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('CreateCommand', () {
    late Directory tempDir;
    late CommandRunner<int> runner;

    setUp(() async {
      tempDir = await createTempDirAsync();
    });

    test('creates a starter app and rewrites identifiers', () async {
      final command = CreateCommand(scaffoldBuilder: _createFakeScaffold);
      runner = createTestRunner(command);

      final targetDir = Directory(path.join(tempDir.path, 'my_talk'));
      final result = await runner.run(['create', targetDir.path, '--force']);

      expect(result, 0);
      expect(
        await File(path.join(targetDir.path, 'README.md')).readAsString(),
        allOf(
          contains('My Talk'),
          contains('Build slides in `slides.md`'),
          isNot(contains('Remove the marker')),
        ),
      );
      expect(
        await File(path.join(targetDir.path, 'slides.md')).readAsString(),
        allOf(
          contains('Sample widget'),
          isNot(contains('WidgetFactory')),
        ),
      );
      expect(
        await File(path.join(targetDir.path, 'pubspec.yaml')).readAsString(),
        allOf(
          contains('name: my_talk'),
          contains('sdk: ^3.11.1'),
          contains('superdeck: ^$packageVersion'),
          contains('superdeck_cli: ^$packageVersion'),
          contains('.superdeck/assets/'),
        ),
      );
      expect(
        File(
          path.join(
            targetDir.path,
            'android',
            'app',
            'src',
            'main',
            'kotlin',
            'com',
            'example',
            'mytalk',
            'MainActivity.kt',
          ),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          path.join(targetDir.path, 'web', 'superdeck_loader.svg'),
        ).existsSync(),
        isTrue,
      );
      expect(
        await File(
          path.join(targetDir.path, 'web', 'index.html'),
        ).readAsString(),
        contains('id="flutter-loader"'),
      );
    });

    test('cancels overwrite when confirmation is declined', () async {
      final targetDir = Directory(path.join(tempDir.path, 'existing_app'));
      await targetDir.create();
      final originalReadme = File(path.join(targetDir.path, 'README.md'));
      await originalReadme.writeAsString('keep me');
      var confirmationMessage = '';

      final command = CreateCommand(
        scaffoldBuilder: _createFakeScaffold,
        confirmOverride: (message, {defaultValue = false}) {
          confirmationMessage = message;
          return false;
        },
      );
      runner = createTestRunner(command);

      final result = await runner.run(['create', targetDir.path]);

      expect(result, 0);
      expect(await originalReadme.readAsString(), 'keep me');
      expect(
        File(path.join(targetDir.path, legacyWorkspaceConfigPath)).existsSync(),
        isFalse,
      );
      expect(confirmationMessage, contains('README.md (starter copy only)'));
      expect(confirmationMessage, contains('pubspec.yaml'));
      expect(confirmationMessage, contains('lib/'));
      expect(confirmationMessage, contains('android/'));
    });

    test(
      'force refresh preserves app code and only updates starter overlay files',
      () async {
        final targetDir = Directory(path.join(tempDir.path, 'existing_app'));
        await targetDir.create(recursive: true);

        final pubspecFile = File(path.join(targetDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString(_fakePubspec('existing_app'));

        final readmeFile = File(path.join(targetDir.path, 'README.md'));
        await readmeFile.writeAsString('custom readme');
        final slidesFile = File(path.join(targetDir.path, 'slides.md'));
        await slidesFile.writeAsString('custom slides');

        final libMainFile = File(path.join(targetDir.path, 'lib', 'main.dart'));
        await libMainFile.create(recursive: true);
        await libMainFile.writeAsString('void main() => print("keep");\n');

        final androidFile = File(
          path.join(targetDir.path, 'android', 'keep.txt'),
        );
        await androidFile.create(recursive: true);
        await androidFile.writeAsString('keep android');

        final indexHtmlFile = File(
          path.join(targetDir.path, 'web', 'index.html'),
        );
        await indexHtmlFile.create(recursive: true);
        await indexHtmlFile.writeAsString(_fakeIndexHtml('existing_app'));

        await File(
          path.join(targetDir.path, legacyWorkspaceConfigPath),
        ).writeAsString('slidesPath: custom.md');

        final command = CreateCommand(scaffoldBuilder: _createFakeScaffold);
        runner = createTestRunner(command);

        final result = await runner.run(['create', targetDir.path, '--force']);

        expect(result, 0);
        expect(await readmeFile.readAsString(), equals('custom readme'));
        expect(await slidesFile.readAsString(), equals('custom slides'));
        expect(
          await libMainFile.readAsString(),
          equals('void main() => print("keep");\n'),
        );
        expect(await androidFile.readAsString(), equals('keep android'));
        expect(
          await pubspecFile.readAsString(),
          allOf(
            contains('superdeck: ^$packageVersion'),
            contains('superdeck_cli: ^$packageVersion'),
            contains('.superdeck/assets/'),
          ),
        );
        expect(
          File(
            path.join(targetDir.path, legacyWorkspaceConfigPath),
          ).existsSync(),
          isFalse,
        );
        expect(
          await indexHtmlFile.readAsString(),
          contains('id="flutter-loader"'),
        );
        expect(
          File(
            path.join(targetDir.path, 'web', 'superdeck_loader.svg'),
          ).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'refresh replaces generated README and slides when markers are present',
      () async {
        final targetDir = Directory(path.join(tempDir.path, 'existing_app'));
        await targetDir.create(recursive: true);

        await File(
          path.join(targetDir.path, 'pubspec.yaml'),
        ).writeAsString(_fakePubspec('existing_app'));
        await File(
          path.join(targetDir.path, 'web', 'index.html'),
        ).create(recursive: true);
        await File(
          path.join(targetDir.path, 'web', 'index.html'),
        ).writeAsString(_fakeIndexHtml('existing_app'));

        final readmeFile = File(path.join(targetDir.path, 'README.md'));
        await readmeFile.writeAsString('$generatedReadmeMarker\nold readme');
        final slidesFile = File(path.join(targetDir.path, 'slides.md'));
        await slidesFile.writeAsString('$generatedSlidesMarker\nold slides');

        final command = CreateCommand(scaffoldBuilder: _createFakeScaffold);
        runner = createTestRunner(command);

        final result = await runner.run(['create', targetDir.path, '--force']);

        expect(result, 0);
        expect(await readmeFile.readAsString(), contains('Existing App'));
        expect(await readmeFile.readAsString(), isNot(contains('old readme')));
        expect(
          await readmeFile.readAsString(),
          isNot(contains('Remove the marker')),
        );
        expect(await slidesFile.readAsString(), contains('Sample widget'));
        expect(await slidesFile.readAsString(), isNot(contains('old slides')));
      },
    );

    test('fails early when target path is an existing file', () async {
      final targetFile = File(path.join(tempDir.path, 'not_a_directory'));
      await targetFile.writeAsString('nope');

      final command = CreateCommand(scaffoldBuilder: _createFakeScaffold);
      runner = createTestRunner(command);

      final result = await runner.run(['create', targetFile.path, '--force']);

      expect(result, 74);
      expect(await targetFile.readAsString(), 'nope');
    });

    test(
      'can scaffold from flutter create when Flutter is available',
      () async {
        final flutter = resolveFlutterBinary(Directory.current.path);
        final flutterVersion = await Process.run(flutter, ['--version']);
        if (flutterVersion.exitCode != 0) {
          return;
        }

        final command = CreateCommand();
        runner = createTestRunner(command);

        final targetDir = Directory(path.join(tempDir.path, 'real_app'));
        final result = await runner.run(['create', targetDir.path, '--force']);

        expect(result, 0);
        expect(
          Directory(path.join(targetDir.path, 'android')).existsSync(),
          isTrue,
        );
        expect(
          File(path.join(targetDir.path, 'slides.md')).existsSync(),
          isTrue,
        );
        expect(
          File(
            path.join(targetDir.path, 'web', 'superdeck_loader.svg'),
          ).existsSync(),
          isTrue,
        );
        expect(
          await File(path.join(targetDir.path, 'pubspec.yaml')).readAsString(),
          allOf(
            contains('superdeck: ^$packageVersion'),
            contains('superdeck_cli: ^$packageVersion'),
            contains('environment:'),
            contains('sdk:'),
          ),
        );
      },
    );
  });
}

Future<Directory> _createFakeScaffold(
  Directory tempRoot,
  CreateBindings bindings,
) async {
  final scaffoldDir = Directory(path.join(tempRoot.path, bindings.projectName));
  await scaffoldDir.create(recursive: true);

  await File(
    path.join(scaffoldDir.path, '.gitignore'),
  ).writeAsString('.dart_tool/\n');
  await File(
    path.join(scaffoldDir.path, 'README.md'),
  ).writeAsString('# placeholder');
  await File(
    path.join(scaffoldDir.path, 'analysis_options.yaml'),
  ).writeAsString('include: package:flutter_lints/flutter.yaml\n');
  await File(
    path.join(scaffoldDir.path, 'pubspec.yaml'),
  ).writeAsString(_fakePubspec(bindings.projectName));
  await File(
    path.join(scaffoldDir.path, 'lib', 'main.dart'),
  ).create(recursive: true);
  await File(
    path.join(scaffoldDir.path, 'lib', 'main.dart'),
  ).writeAsString('void main() {}\n');
  await File(
    path.join(scaffoldDir.path, 'test', 'widget_test.dart'),
  ).create(recursive: true);
  await File(
    path.join(scaffoldDir.path, 'test', 'widget_test.dart'),
  ).writeAsString('void main() {}\n');
  await File(
    path.join(scaffoldDir.path, 'web', 'index.html'),
  ).create(recursive: true);
  await File(
    path.join(scaffoldDir.path, 'web', 'index.html'),
  ).writeAsString(_fakeIndexHtml(bindings.projectName));

  final mainActivity = File(
    path.joinAll([
      scaffoldDir.path,
      'android',
      'app',
      'src',
      'main',
      'kotlin',
      'com',
      'example',
      bindings.projectName.replaceAll('_', ''),
      'MainActivity.kt',
    ]),
  );
  await mainActivity.parent.create(recursive: true);
  await mainActivity.writeAsString(
    'package com.example.${bindings.projectName.replaceAll('_', '')}\n'
    'class MainActivity {}',
  );

  await Directory(path.join(scaffoldDir.path, 'ios')).create(recursive: true);
  await Directory(path.join(scaffoldDir.path, 'linux')).create(recursive: true);
  await Directory(path.join(scaffoldDir.path, 'macos')).create(recursive: true);
  await Directory(
    path.join(scaffoldDir.path, 'windows'),
  ).create(recursive: true);

  return scaffoldDir;
}

String _fakePubspec(String projectName) =>
    '''
name: $projectName
description: A new Flutter project.
version: 1.0.0+1

environment:
  sdk: ^3.11.1

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
''';

String _fakeIndexHtml(String projectName) =>
    '''
<!DOCTYPE html>
<html>
<head>
  <base href="\$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="$projectName">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>$projectName</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
''';
