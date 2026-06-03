import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_deploy/src/web/build_web.dart';
import 'package:test/test.dart';

import '../../helpers/fake_process_runner.dart';

void main() {
  late FakeProcessRunner runner;
  late WebBuilder builder;

  setUp(() {
    runner = FakeProcessRunner();
    builder = WebBuilder(logger: Logger(level: Level.quiet), processRunner: runner.call);
  });

  test('dry-run does not invoke flutter', () async {
    final result = await builder.build(appDir: '.', baseHref: '/x/', dryRun: true);
    expect(result, isTrue);
    expect(runner.invocations, isEmpty);
  });

  test('passes base-href and output to flutter build web', () async {
    final tempDir = await Directory.systemTemp.createTemp('build_web_test_');
    addTearDown(() => tempDir.delete(recursive: true));

    await builder.build(
      appDir: tempDir.path,
      baseHref: '/superdeck/',
      outputDir: '/tmp/out',
    );

    final args = runner.argsFor('flutter');
    expect(args, contains('web'));
    expect(args, contains('--release'));
    expect(args, contains('--base-href=/superdeck/'));
    expect(args, contains('--output=/tmp/out'));
  });

  test('returns false when the app directory is missing', () async {
    final result = await builder.build(appDir: '/no/such/dir');
    expect(result, isFalse);
    expect(runner.invocations, isEmpty);
  });
}
