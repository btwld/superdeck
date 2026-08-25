import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_cli/superdeck_cli.dart';
import 'package:superdeck_cli/src/commands/build_command.dart';
import 'package:superdeck_cli/src/commands/setup_command.dart';
import 'package:superdeck_cli/src/utils/constants.dart';
import 'package:superdeck_core/superdeck_core.dart';
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
        setupCommand: SetupCommand(loggerOverride: mockLogger),
      );
    });

    group('--version flag', () {
      test('prints version and exits successfully', () async {
        final exitCode = await runner.run(['--version']);

        expect(exitCode, ExitCode.success.code);
        expect(mockLogger.infoMessages, contains(contains(packageVersion)));
      });
    });

    group('shared logger propagation', () {
      test('passes build plugins to the default build command', () {
        const plugin = _IdentityPlugin('test.runner-transform');
        final runner = SuperDeckRunner(
          loggerOverride: mockLogger,
          plugins: [plugin],
          setupCommand: SetupCommand(loggerOverride: mockLogger),
        );

        final buildCommand = runner.commands['build'] as BuildCommand;

        expect(buildCommand.plugins, contains(plugin));
      });

      test('passes quiet logging to setup', () async {
        final tempDir = await createTempDirAsync();
        await _createMinimalFlutterApp(tempDir);
        runner = SuperDeckRunner(
          loggerOverride: mockLogger,
          buildCommand: BuildCommand(loggerOverride: mockLogger),
          setupCommand: SetupCommand(
            loggerOverride: mockLogger,
            projectDir: tempDir.path,
          ),
        );
        final exitCode = await runner.run(['--quiet', 'setup']);

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
          setupCommand: SetupCommand(loggerOverride: mockLogger),
        );

        await File(
          path.join(tempDir.path, 'slides.md'),
        ).writeAsString('# Test Slide\n\nContent');
        createTestPubspec(tempDir);

        final workspace = DeckWorkspace(projectDir: tempDir.path);
        await workspace.superdeckDir.create(recursive: true);

        final exitCode = await runner.run([
          '--verbose',
          'build',
          '--skip-pubspec',
        ]);

        expect(
          exitCode,
          anyOf(equals(ExitCode.success.code), equals(ExitCode.software.code)),
        );
        expect(mockLogger.detailMessages, contains('Verbose logging enabled'));
      });
    });
  });
}

Future<void> _createMinimalFlutterApp(Directory projectDir) async {
  await File(path.join(projectDir.path, 'pubspec.yaml')).writeAsString('''
name: runner_test_app
description: A new Flutter project.
version: 1.0.0+1

environment:
  sdk: ">=3.12.0 <4.0.0"

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
  final runnerDir = Directory(path.join(projectDir.path, 'macos', 'Runner'));
  await runnerDir.create(recursive: true);
  for (final name in ['DebugProfile.entitlements', 'Release.entitlements']) {
    await File(
      path.join(runnerDir.path, name),
    ).writeAsString('<plist version="1.0"><dict></dict></plist>');
  }
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

final class _IdentityPlugin extends DeckBuildPlugin {
  @override
  final String id;

  const _IdentityPlugin(this.id);
}
