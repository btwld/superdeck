import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/runner.dart';
import 'package:superdeck_cli/src/commands/build_command.dart';
import 'package:superdeck_cli/src/commands/create/create_support.dart';
import 'package:superdeck_cli/src/commands/create_command.dart';
import 'package:superdeck_cli/src/utils/constants.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SuperDeckRunner', () {
    late _CapturingLogger mockLogger;
    late SuperDeckRunner runner;

    setUp(() {
      mockLogger = _CapturingLogger();
      runner = SuperDeckRunner(
        loggerOverride: mockLogger,
        buildCommand: BuildCommand(loggerOverride: mockLogger),
        createCommand: CreateCommand(
          loggerOverride: mockLogger,
          scaffoldBuilder: _createFakeScaffold,
        ),
      );
    });

    group('--version flag', () {
      test('prints version and exits successfully', () async {
        final exitCode = await runner.run(['--version']);

        expect(exitCode, ExitCode.success.code);
        expect(mockLogger.infoMessages, contains(contains(packageVersion)));
      });
    });

    group('version subcommand', () {
      test('prints version and exits successfully', () async {
        final exitCode = await runner.run(['version']);

        expect(exitCode, ExitCode.success.code);
        expect(mockLogger.infoMessages, contains(contains(packageVersion)));
      });
    });

    group('shared logger propagation', () {
      test('passes quiet logging to create', () async {
        final tempDir = await createTempDirAsync();
        final exitCode = await runner.run([
          '--quiet',
          'create',
          path.join(tempDir.path, 'my_talk'),
          '--force',
        ]);

        expect(exitCode, ExitCode.success.code);
        expect(mockLogger.infoMessages, isEmpty);
      });

      test('passes verbose logging to build', () async {
        final tempDir = await createTempDirAsync();
        runner = SuperDeckRunner(
          loggerOverride: mockLogger,
          buildCommand: BuildCommand(
            loggerOverride: mockLogger,
            projectDir: tempDir.path,
          ),
          createCommand: CreateCommand(
            loggerOverride: mockLogger,
            scaffoldBuilder: _createFakeScaffold,
          ),
        );

        await File(
          path.join(tempDir.path, 'slides.md'),
        ).writeAsString('# Test Slide\n\nContent');
        createTestPubspec(tempDir);

        final superdeckDir = Directory(path.join(tempDir.path, '.superdeck'));
        await superdeckDir.create(recursive: true);
        await File(
          path.join(superdeckDir.path, 'generated_assets.json'),
        ).writeAsString('{"stale":true}');

        final exitCode = await runner.run([
          '--verbose',
          'build',
          '--force-rebuild',
          '--skip-pubspec',
        ]);

        expect(
          exitCode,
          anyOf(equals(ExitCode.success.code), equals(ExitCode.software.code)),
        );
        expect(
          mockLogger.detailMessages,
          contains('Deleted generated_assets.json'),
        );
      });
    });
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
    path.join(scaffoldDir.path, 'analysis_options.yaml'),
  ).writeAsString('include: package:flutter_lints/flutter.yaml\n');
  await File(path.join(scaffoldDir.path, 'pubspec.yaml')).writeAsString('''
name: ${bindings.projectName}
description: A new Flutter project.
version: 1.0.0+1

environment:
  sdk: ">=3.10.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
''');
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
  await File(path.join(scaffoldDir.path, 'web', 'index.html')).writeAsString('''
<!DOCTYPE html>
<html>
<head>
  <base href="\$FLUTTER_BASE_HREF">
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
''');
  await File(
    path.join(scaffoldDir.path, 'README.md'),
  ).writeAsString('# placeholder');
  await Directory(
    path.join(scaffoldDir.path, 'android'),
  ).create(recursive: true);
  await Directory(path.join(scaffoldDir.path, 'ios')).create(recursive: true);
  await Directory(path.join(scaffoldDir.path, 'linux')).create(recursive: true);
  await Directory(path.join(scaffoldDir.path, 'macos')).create(recursive: true);
  await Directory(
    path.join(scaffoldDir.path, 'windows'),
  ).create(recursive: true);

  return scaffoldDir;
}

class _CapturingLogger extends Logger {
  final List<String> infoMessages = [];
  final List<String> detailMessages = [];
  final List<String> errMessages = [];

  @override
  void info(String? message, {LogStyle? style}) {
    if (level.index > Level.info.index || message == null) {
      return;
    }
    infoMessages.add(message);
  }

  @override
  void detail(String? message, {LogStyle? style}) {
    if (level.index > Level.debug.index || message == null) {
      return;
    }
    detailMessages.add(message);
  }

  @override
  void err(String? message, {LogStyle? style}) {
    if (level.index > Level.error.index || message == null) {
      return;
    }
    errMessages.add(message);
  }
}
