import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
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
}
