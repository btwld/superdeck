import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/setup/setup_asset_support.dart';
import 'package:superdeck_cli/src/commands/setup/setup_support.dart';
import 'package:superdeck_cli/src/commands/setup_command.dart';
import 'package:superdeck_cli/src/utils/constants.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SetupCommand', () {
    late Directory tempDir;
    late CommandRunner<int> runner;

    setUp(() async {
      tempDir = await createTempDirAsync();
      runner = createTestRunner(SetupCommand(projectDir: tempDir.path));
    });

    test('resolves packaged setup assets', () async {
      final assetsRoot = resolveSetupAssetsRoot();

      expect(
        File(path.join(assetsRoot, 'web', 'superdeck_loader.svg')).existsSync(),
        isTrue,
      );
      expect(
        File(path.join(assetsRoot, 'web', 'loader_body.html')).existsSync(),
        isTrue,
      );
      expect(
        File(path.join(assetsRoot, 'web', 'flutter_bootstrap.js')).existsSync(),
        isTrue,
      );
      expect(File(path.join(assetsRoot, 'README.md')).existsSync(), isFalse);
      expect(
        File(path.join(assetsRoot, 'lib', 'main.dart.template')).existsSync(),
        isFalse,
      );
    });

    test(
      'configures the current Flutter app without touching app code',
      () async {
        await _createMinimalFlutterApp(
          tempDir,
          includeWeb: true,
          includeMacos: true,
        );

        final mainFile = File(path.join(tempDir.path, 'lib', 'main.dart'));
        await mainFile.create(recursive: true);
        await mainFile.writeAsString('void main() => print("keep");\n');

        final slidesFile = File(path.join(tempDir.path, 'slides.md'));
        await slidesFile.writeAsString('# Keep me');

        final result = await runner.run(['setup']);

        expect(result, ExitCode.success.code);
        expect(
          await mainFile.readAsString(),
          'void main() => print("keep");\n',
        );
        expect(await slidesFile.readAsString(), '# Keep me');
        expect(
          await File(path.join(tempDir.path, 'pubspec.yaml')).readAsString(),
          allOf(
            contains('superdeck: ^$packageVersion'),
            contains('superdeck_cli: ^$packageVersion'),
            contains('.superdeck/'),
            contains('.superdeck/assets/'),
          ),
        );
        expect(
          Directory(
            path.join(tempDir.path, '.superdeck', 'assets'),
          ).existsSync(),
          isTrue,
        );
        expect(
          await File(
            path.join(tempDir.path, 'web', 'index.html'),
          ).readAsString(),
          allOf(
            contains('id="flutter-loader"'),
            contains('superdeck:managed loader-style:start'),
            contains('superdeck:managed loader-body:start'),
          ),
        );
        expect(
          await File(
            path.join(tempDir.path, 'web', 'flutter_bootstrap.js'),
          ).readAsString(),
          contains('superdeck:managed bootstrap'),
        );
        expect(
          File(
            path.join(tempDir.path, 'web', 'superdeck_loader.svg'),
          ).existsSync(),
          isTrue,
        );
        expect(
          await File(
            path.join(
              tempDir.path,
              'macos',
              'Runner',
              'DebugProfile.entitlements',
            ),
          ).readAsString(),
          allOf(
            contains('com.apple.security.files.user-selected.read-write'),
            contains('com.apple.security.files.downloads.read-write'),
            contains('<false/>'),
          ),
        );
        expect(
          File(path.join(tempDir.path, 'README.md')).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'configures the app when project has a package config without superdeck_cli',
      () async {
        await _createMinimalFlutterApp(
          tempDir,
          includeWeb: true,
          includeMacos: false,
        );
        await _writeAppPackageConfig(tempDir);

        final result = await runner.run(['setup']);

        expect(result, ExitCode.success.code);
        expect(
          await File(
            path.join(tempDir.path, 'web', 'flutter_bootstrap.js'),
          ).readAsString(),
          contains('superdeck:managed bootstrap'),
        );
        expect(
          File(
            path.join(tempDir.path, 'web', 'superdeck_loader.svg'),
          ).existsSync(),
          isTrue,
        );
      },
    );

    test('adds default dependencies when missing', () {
      final patched = patchSetupPubspec(_fakePubspec('existing_app'));
      final dependencies = _pubspecSection(patched, 'dependencies');
      final devDependencies = _pubspecSection(patched, 'dev_dependencies');

      expect(dependencies['superdeck'], '^$packageVersion');
      expect(devDependencies['superdeck_cli'], '^$packageVersion');
    });

    test('preserves an existing pinned superdeck dependency', () {
      final patched = patchSetupPubspec('''
name: existing_app
dependencies:
  flutter:
    sdk: flutter
  superdeck: 1.2.3
flutter:
  uses-material-design: true
''');

      final dependencies = _pubspecSection(patched, 'dependencies');

      expect(dependencies['superdeck'], '1.2.3');
    });

    test('preserves an existing path-based superdeck dependency', () {
      final patched = patchSetupPubspec('''
name: existing_app
dependencies:
  flutter:
    sdk: flutter
  superdeck:
    path: ../superdeck
flutter:
  uses-material-design: true
''');

      final dependencies = _pubspecSection(patched, 'dependencies');
      final superdeck = dependencies['superdeck'] as YamlMap;

      expect(superdeck['path'], '../superdeck');
    });

    test('preserves an existing git-based superdeck_cli dev dependency', () {
      final patched = patchSetupPubspec('''
name: existing_app
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  superdeck_cli:
    git:
      url: https://github.com/leoafarias/superdeck.git
      path: packages/cli
flutter:
  uses-material-design: true
''');

      final devDependencies = _pubspecSection(patched, 'dev_dependencies');
      final superdeckCli = devDependencies['superdeck_cli'] as YamlMap;
      final git = superdeckCli['git'] as YamlMap;

      expect(git['url'], 'https://github.com/leoafarias/superdeck.git');
      expect(git['path'], 'packages/cli');
    });

    test('rerunning setup is idempotent', () async {
      await _createMinimalFlutterApp(
        tempDir,
        includeWeb: true,
        includeMacos: true,
      );

      expect(await runner.run(['setup']), ExitCode.success.code);
      expect(await runner.run(['setup']), ExitCode.success.code);

      final pubspecContents = await File(
        path.join(tempDir.path, 'pubspec.yaml'),
      ).readAsString();
      final indexContents = await File(
        path.join(tempDir.path, 'web', 'index.html'),
      ).readAsString();
      final debugEntitlements = await File(
        path.join(tempDir.path, 'macos', 'Runner', 'DebugProfile.entitlements'),
      ).readAsString();

      expect(_countMatches(pubspecContents, 'superdeck: ^$packageVersion'), 1);
      expect(_countMatches(pubspecContents, '.superdeck/assets/'), 1);
      expect(_countMatches(indexContents, 'id="flutter-loader"'), 1);
      expect(
        _countMatches(
          debugEntitlements,
          'com.apple.security.files.user-selected.read-write',
        ),
        1,
      );
    });

    test('skips missing web and macos platforms', () async {
      await File(
        path.join(tempDir.path, 'pubspec.yaml'),
      ).writeAsString(_fakePubspec('existing_app'));

      final result = await runner.run(['setup']);

      expect(result, ExitCode.success.code);
      expect(
        Directory(path.join(tempDir.path, '.superdeck', 'assets')).existsSync(),
        isTrue,
      );
      expect(
        File(path.join(tempDir.path, 'web', 'index.html')).existsSync(),
        isFalse,
      );
      expect(
        File(
          path.join(tempDir.path, 'macos', 'Runner', 'Release.entitlements'),
        ).existsSync(),
        isFalse,
      );
    });

    test('fails cleanly when web/index.html cannot be patched', () async {
      await _createMinimalFlutterApp(
        tempDir,
        includeWeb: false,
        includeMacos: false,
      );

      final webDir = Directory(path.join(tempDir.path, 'web'));
      await webDir.create(recursive: true);
      await File(path.join(webDir.path, 'index.html')).writeAsString('''
<!DOCTYPE html>
<html>
<head></head>
<body></body>
</html>
''');

      final result = await runner.run(['setup']);

      expect(result, ExitCode.data.code);
      expect(
        File(
          path.join(tempDir.path, 'web', 'flutter_bootstrap.js'),
        ).existsSync(),
        isFalse,
      );
    });

    test('fails cleanly when flutter_bootstrap.js already exists', () async {
      await _createMinimalFlutterApp(
        tempDir,
        includeWeb: true,
        includeMacos: false,
      );
      await File(
        path.join(tempDir.path, 'web', 'flutter_bootstrap.js'),
      ).writeAsString('// custom bootstrap');

      final result = await runner.run(['setup']);

      expect(result, ExitCode.ioError.code);
    });

    test(
      'preserves unrelated entitlement keys while patching required ones',
      () {
        final patched = patchSetupEntitlements(
          '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>com.apple.security.app-sandbox</key>
\t<true/>
\t<key>custom.key</key>
\t<true/>
</dict>
</plist>
''',
          const {
            'com.apple.security.app-sandbox': false,
            'com.apple.security.network.client': true,
          },
        );

        expect(patched, contains('<key>custom.key</key>'));
        expect(
          patched,
          contains('\t<key>com.apple.security.app-sandbox</key>\n\t<false/>'),
        );
        expect(patched, contains('com.apple.security.network.client'));
      },
    );

    test('fails when pubspec.yaml is missing', () async {
      final result = await runner.run(['setup']);

      expect(result, ExitCode.ioError.code);
    });

    test('fails when pubspec has no Flutter dependency', () async {
      await File(path.join(tempDir.path, 'pubspec.yaml')).writeAsString('''
name: dart_only_pkg
version: 1.0.0
environment:
  sdk: ^3.11.1
dependencies:
  http: ^1.0.0
''');

      final result = await runner.run(['setup']);

      expect(result, ExitCode.ioError.code);
      expect(
        Directory(path.join(tempDir.path, '.superdeck')).existsSync(),
        isFalse,
      );
    });

    test('fails fast when superdeck.yaml exists', () async {
      await File(
        path.join(tempDir.path, 'pubspec.yaml'),
      ).writeAsString(_fakePubspec('existing_app'));
      await File(
        path.join(tempDir.path, 'superdeck.yaml'),
      ).writeAsString('slidesPath: custom.md');

      final result = await runner.run(['setup']);

      expect(result, ExitCode.data.code);
      expect(
        Directory(path.join(tempDir.path, '.superdeck')).existsSync(),
        isFalse,
      );
    });
  });
}

Future<void> _createMinimalFlutterApp(
  Directory projectDir, {
  required bool includeWeb,
  required bool includeMacos,
}) async {
  await File(
    path.join(projectDir.path, 'pubspec.yaml'),
  ).writeAsString(_fakePubspec(path.basename(projectDir.path)));

  if (includeWeb) {
    final webDir = Directory(path.join(projectDir.path, 'web'));
    await webDir.create(recursive: true);
    await File(
      path.join(webDir.path, 'index.html'),
    ).writeAsString(_fakeIndexHtml(path.basename(projectDir.path)));
  }

  if (includeMacos) {
    final runnerDir = Directory(path.join(projectDir.path, 'macos', 'Runner'));
    await runnerDir.create(recursive: true);
    await File(
      path.join(runnerDir.path, 'DebugProfile.entitlements'),
    ).writeAsString(_fakeDebugEntitlements);
    await File(
      path.join(runnerDir.path, 'Release.entitlements'),
    ).writeAsString(_fakeReleaseEntitlements);
  }
}

int _countMatches(String contents, String pattern) {
  return RegExp(RegExp.escape(pattern)).allMatches(contents).length;
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

const _fakeDebugEntitlements = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>com.apple.security.app-sandbox</key>
\t<true/>
</dict>
</plist>
''';

const _fakeReleaseEntitlements = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>com.apple.security.app-sandbox</key>
\t<true/>
</dict>
</plist>
''';

Future<void> _writeAppPackageConfig(Directory projectDir) async {
  final packageConfigFile = File(
    path.join(projectDir.path, '.dart_tool', 'package_config.json'),
  );
  await packageConfigFile.create(recursive: true);
  await packageConfigFile.writeAsString('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "${path.basename(projectDir.path)}",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "3.11"
    },
    {
      "name": "flutter",
      "rootUri": "../fake_flutter/",
      "packageUri": "lib/",
      "languageVersion": "3.11"
    }
  ]
}
''');
}

YamlMap _pubspecSection(String pubspecContents, String sectionName) {
  final pubspec = loadYaml(pubspecContents) as YamlMap;
  return pubspec[sectionName] as YamlMap;
}
