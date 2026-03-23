import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/runner.dart';
import 'package:superdeck_cli/src/utils/constants.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SuperDeckRunner', () {
    late _CapturingLogger mockLogger;
    late SuperDeckRunner runner;

    setUp(() {
      mockLogger = _CapturingLogger();
      runner = SuperDeckRunner(loggerOverride: mockLogger);
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
      test('passes quiet logging to setup', () async {
        final tempDir = await createTempDirAsync();
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          await File(
            path.join(tempDir.path, 'superdeck.yaml'),
          ).writeAsString('slidesPath: custom.md');

          final exitCode = await runner.run(['--quiet', 'setup', '--force']);

          expect(exitCode, ExitCode.data.code);
          expect(
            mockLogger.errMessages,
            contains(contains('Unsupported configuration file')),
          );
          expect(mockLogger.infoMessages, isEmpty);
        } finally {
          Directory.current = previousDir;
        }
      });

      test('passes verbose logging to build', () async {
        final tempDir = await createTempDirAsync();
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
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
            anyOf(
              equals(ExitCode.success.code),
              equals(ExitCode.software.code),
            ),
          );
          expect(
            mockLogger.detailMessages,
            contains('Deleted generated_assets.json'),
          );
        } finally {
          Directory.current = previousDir;
        }
      });
    });
  });
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
