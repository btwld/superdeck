import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_deploy/src/runner.dart';
import 'package:superdeck_deploy/src/targets/firebase.dart';
import 'package:test/test.dart';

import '../../helpers/fake_process_runner.dart';

void main() {
  Logger quiet() => Logger(level: Level.quiet);

  test('dry-run reports success without running firebase', () async {
    final runner = FakeProcessRunner();
    final code = await DeployRunner(
      loggerOverride: quiet(),
      processRunner: runner.call,
    ).run(['firebase', '--dry-run']);

    expect(code, ExitCode.success.code);
    expect(runner.invocations, isEmpty);
  });

  test('deploys hosting with the configured project', () async {
    final appDir = await Directory.systemTemp.createTemp('deploy_firebase_');
    addTearDown(() => appDir.delete(recursive: true));
    File(p.join(appDir.path, 'firebase.json')).writeAsStringSync('{}');

    final runner = FakeProcessRunner();
    final target = FirebaseTarget(logger: quiet(), processRunner: runner.call);

    final code = await target.deploy(
      FirebaseOptions(appDir: appDir.path, project: 'superdeck-dev'),
    );

    expect(code, ExitCode.success.code);
    final args = runner.argsFor('firebase');
    expect(args, containsAllInOrder(['deploy', '--only', 'hosting']));
    expect(args, containsAllInOrder(['--project', 'superdeck-dev']));
  });

  test('fails with a usage error when firebase.json is missing', () async {
    final appDir = await Directory.systemTemp.createTemp('deploy_firebase_');
    addTearDown(() => appDir.delete(recursive: true));

    final target = FirebaseTarget(logger: quiet());
    final code = await target.deploy(FirebaseOptions(appDir: appDir.path));

    expect(code, ExitCode.usage.code);
  });
}
