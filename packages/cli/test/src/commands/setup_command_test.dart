import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/setup/setup_support.dart';
import 'package:superdeck_cli/src/commands/setup_command.dart';
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

    test('configures placeholders, pubspec assets, and macOS entitlements', () async {
      await _createMinimalFlutterApp(tempDir, includeMacos: true);

      final mainFile = File(path.join(tempDir.path, 'lib', 'main.dart'));
      await mainFile.create(recursive: true);
      await mainFile.writeAsString('void main() => print("keep");\n');

      final slidesFile = File(path.join(tempDir.path, 'slides.md'));
      await slidesFile.writeAsString('# Keep me');

      final result = await runner.run(['setup']);

      expect(result, ExitCode.success.code);
      expect(await mainFile.readAsString(), 'void main() => print("keep");\n');
      expect(await slidesFile.readAsString(), '# Keep me');
      expect(
        await File(path.join(tempDir.path, 'pubspec.yaml')).readAsString(),
        allOf(
          contains('.superdeck/'),
          contains('.superdeck/assets/'),
        ),
      );
      expect(
        Directory(path.join(tempDir.path, '.superdeck', 'assets')).existsSync(),
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
    });

    test('adds .superdeck asset entries to pubspec flutter.assets', () {
      final patched = patchSetupPubspec(_fakePubspec('existing_app'));
      final pubspec = loadYaml(patched) as YamlMap;
      final flutter = pubspec['flutter'] as YamlMap;
      final assets = (flutter['assets'] as YamlList).map((e) => e.toString());

      expect(assets, containsAll(['.superdeck/', '.superdeck/assets/']));
    });

    test('rerunning setup is idempotent', () async {
      await _createMinimalFlutterApp(tempDir, includeMacos: true);

      expect(await runner.run(['setup']), ExitCode.success.code);
      expect(await runner.run(['setup']), ExitCode.success.code);

      final pubspecContents = await File(
        path.join(tempDir.path, 'pubspec.yaml'),
      ).readAsString();
      final debugEntitlements = await File(
        path.join(tempDir.path, 'macos', 'Runner', 'DebugProfile.entitlements'),
      ).readAsString();

      expect(_countMatches(pubspecContents, '.superdeck/assets/'), 1);
      expect(
        _countMatches(
          debugEntitlements,
          'com.apple.security.files.user-selected.read-write',
        ),
        1,
      );
    });

    test('skips macOS setup when the platform directory is absent', () async {
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
        File(
          path.join(tempDir.path, 'macos', 'Runner', 'Release.entitlements'),
        ).existsSync(),
        isFalse,
      );
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

  });
}

Future<void> _createMinimalFlutterApp(
  Directory projectDir, {
  required bool includeMacos,
}) async {
  await File(
    path.join(projectDir.path, 'pubspec.yaml'),
  ).writeAsString(_fakePubspec(path.basename(projectDir.path)));

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
