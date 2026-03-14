import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_cli/runner.dart';
import 'package:superdeck_cli/src/utils/constants.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SuperDeckRunner', () {
    late _CapturingLogger mockLogger;
    late SuperDeckRunner runner;
    late Directory tempDir;
    late Directory previousDir;

    setUp(() async {
      mockLogger = _CapturingLogger();
      runner = SuperDeckRunner(loggerOverride: mockLogger);
      tempDir = await createTempDirAsync();
      previousDir = Directory.current;
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = previousDir;
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

    group('invalid config path', () {
      test('reports configuration error for absolute slidesPath', () async {
        File(
          'superdeck.yaml',
        ).writeAsStringSync('slidesPath: /etc/absolute.md\n');

        final exitCode = await runner.run(['build']);

        expect(exitCode, isNot(ExitCode.success.code));
      });

      test('reports configuration error for traversal outputDir', () async {
        File('superdeck.yaml').writeAsStringSync('outputDir: ../outside\n');

        final exitCode = await runner.run(['build']);

        expect(exitCode, isNot(ExitCode.success.code));
      });
    });
  });
}

class _CapturingLogger extends Logger {
  final List<String> infoMessages = [];
  final List<String> errMessages = [];

  @override
  void info(String? message, {LogStyle? style}) {
    if (message != null) infoMessages.add(message);
  }

  @override
  void err(String? message, {LogStyle? style}) {
    if (message != null) errMessages.add(message);
  }
}
