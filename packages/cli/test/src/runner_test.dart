import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_cli/runner.dart';
import 'package:superdeck_cli/src/utils/constants.dart';
import 'package:test/test.dart';

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
