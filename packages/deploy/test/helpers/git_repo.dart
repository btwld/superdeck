import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Creates a temporary git repository with one initial commit on `main`, and
/// registers async cleanup. Returns the repository directory.
Future<Directory> createGitRepo() async {
  final dir = await Directory.systemTemp.createTemp('deploy_git_test_');
  addTearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<void> git(List<String> args, {String? cwd}) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: cwd ?? dir.path,
    );
    if (result.exitCode != 0) {
      throw Exception('git ${args.join(' ')} failed: ${result.stderr}');
    }
  }

  await git(['init']);
  await git(['checkout', '-b', 'main']);
  await git(['config', 'user.email', 'test@example.com']);
  await git(['config', 'user.name', 'Deploy Test']);
  await git(['config', 'commit.gpgsign', 'false']);

  File(p.join(dir.path, 'README.md')).writeAsStringSync('# test\n');
  await git(['add', '.']);
  await git(['commit', '-m', 'init']);

  return dir;
}

/// Runs a git command in [repoPath] and returns trimmed stdout (empty on
/// failure).
Future<String> gitOutput(String repoPath, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: repoPath);

  return result.exitCode == 0 ? result.stdout.toString().trim() : '';
}
