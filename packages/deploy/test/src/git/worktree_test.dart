import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_deploy/src/git/git_runner.dart';
import 'package:superdeck_deploy/src/git/worktree.dart';
import 'package:test/test.dart';

import '../../helpers/git_repo.dart';

void main() {
  test('creates an orphan worktree for a new branch and cleans up', () async {
    final repo = await createGitRepo();
    final git = GitRunner(
      workingDirectory: repo.path,
      logger: Logger(level: Level.quiet),
    );
    final worktree = GitWorktree(git: git, logger: Logger(level: Level.quiet));

    await worktree.create(targetBranch: 'gh-pages');

    expect(Directory(worktree.path).existsSync(), isTrue);
    expect(
      await gitOutput(worktree.path, ['symbolic-ref', '--short', 'HEAD']),
      'gh-pages',
    );

    await worktree.remove();
    expect(Directory(worktree.path).existsSync(), isFalse);
  });

  test('bases the worktree on origin when the branch is remote-only', () async {
    final repo = await createGitRepo();

    Future<void> git(List<String> args, {String? cwd}) async {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: cwd ?? repo.path,
      );
      if (result.exitCode != 0) {
        throw Exception('git ${args.join(' ')} failed: ${result.stderr}');
      }
    }

    // A bare remote holding an existing gh-pages branch with prior content.
    final remote = await Directory.systemTemp.createTemp('deploy_remote_');
    addTearDown(() => remote.delete(recursive: true));
    await git(['init', '--bare', remote.path]);
    await git(['remote', 'add', 'origin', remote.path]);

    await git(['checkout', '-b', 'gh-pages']);
    File(p.join(repo.path, 'existing.txt')).writeAsStringSync('prior deploy\n');
    await git(['add', 'existing.txt']);
    await git(['commit', '-m', 'existing deploy']);
    await git(['push', 'origin', 'gh-pages']);

    // Simulate a fresh clone / CI checkout: no local gh-pages branch.
    await git(['checkout', 'main']);
    await git(['branch', '-D', 'gh-pages']);

    final runner = GitRunner(
      workingDirectory: repo.path,
      logger: Logger(level: Level.quiet),
    );
    final worktree = GitWorktree(
      git: runner,
      logger: Logger(level: Level.quiet),
    );
    addTearDown(worktree.remove);

    await worktree.create(targetBranch: 'gh-pages');

    // The worktree extends the remote history (its prior file is present),
    // rather than starting a fresh orphan branch that would clobber it.
    expect(
      await gitOutput(worktree.path, ['symbolic-ref', '--short', 'HEAD']),
      'gh-pages',
    );
    expect(File(p.join(worktree.path, 'existing.txt')).existsSync(), isTrue);
  });
}
