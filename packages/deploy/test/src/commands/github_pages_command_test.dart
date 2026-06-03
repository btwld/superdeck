import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_deploy/src/runner.dart';
import 'package:superdeck_deploy/src/targets/github_pages.dart';
import 'package:test/test.dart';

import '../../helpers/fake_process_runner.dart';
import '../../helpers/git_repo.dart';

void main() {
  Logger quiet() => Logger(level: Level.quiet);

  /// A fake git that reports a clean GitHub repo with no gh-pages branch.
  FakeProcessRunner fakeGit() {
    return FakeProcessRunner(
      responder: (invocation) {
        final args = invocation.arguments;
        if (args.contains('rev-parse')) return ProcessResult(0, 0, 'true', '');
        if (args.contains('symbolic-ref')) return ProcessResult(0, 0, 'main', '');
        if (args.contains('get-url')) {
          return ProcessResult(0, 0, 'https://github.com/btwld/superdeck.git', '');
        }
        if (args.contains('show-ref')) return ProcessResult(0, 1, '', '');

        return ProcessResult(0, 0, '', '');
      },
    );
  }

  test('dry-run reports success and runs no mutating git commands', () async {
    final runner = DeployRunner(
      loggerOverride: quiet(),
      processRunner: fakeGit().call,
    );

    final code = await runner.run([
      'github-pages',
      '--dry-run',
      '--no-build',
      '--no-push',
    ]);

    expect(code, ExitCode.success.code);
  });

  test('rejects an invalid branch name with a usage error', () async {
    final runner = DeployRunner(
      loggerOverride: quiet(),
      processRunner: fakeGit().call,
    );

    final code = await runner.run([
      'github-pages',
      '--branch',
      '../evil',
      '--dry-run',
      '--no-build',
    ]);

    expect(code, ExitCode.usage.code);
  });

  test('publishes built assets to an orphan branch (real git)', () async {
    final repo = await createGitRepo();

    final buildDir = await Directory.systemTemp.createTemp('deploy_build_');
    addTearDown(() => buildDir.delete(recursive: true));
    File(p.join(buildDir.path, 'index.html')).writeAsStringSync('<html></html>');
    Directory(p.join(buildDir.path, 'assets')).createSync();
    File(p.join(buildDir.path, 'assets', 'app.js')).writeAsStringSync('//js');

    final original = Directory.current;
    addTearDown(() => Directory.current = original);
    Directory.current = repo;

    final target = GitHubPagesTarget(logger: quiet());
    final code = await target.publish(
      GitHubPagesOptions(
        branch: 'gh-pages',
        build: false,
        push: false,
        buildDir: buildDir.path,
      ),
    );

    expect(code, ExitCode.success.code);

    // The working tree is untouched and still on main.
    expect(await gitOutput(repo.path, ['symbolic-ref', '--short', 'HEAD']), 'main');
    expect(await gitOutput(repo.path, ['status', '--porcelain']), isEmpty);

    // The gh-pages branch now contains the build output and a .nojekyll marker.
    final tree = await gitOutput(repo.path, ['ls-tree', '-r', '--name-only', 'gh-pages']);
    expect(tree, contains('index.html'));
    expect(tree, contains('assets/app.js'));
    expect(tree, contains('.nojekyll'));
  });
}
