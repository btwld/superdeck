import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

final _httpsRepositoryPattern = RegExp(
  r'https://github\.com/([^/]+)/([^/]+?)(\.git)?$',
);
final _sshRepositoryPattern = RegExp(
  r'git@github\.com:([^/]+)/([^/]+?)(\.git)?$',
);
final _validBranchNamePattern = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._/-]*$');

Future<ProcessResult?> runGitQuery(
  Logger logger,
  String repoPath,
  List<String> args,
) async {
  try {
    return await Process.run('git', args, workingDirectory: repoPath);
  } on ProcessException catch (e) {
    logger.detail('Git command failed: ${args.join(' ')} - ${e.message}');
    return null;
  } on IOException catch (e) {
    logger.detail('Git I/O error: ${args.join(' ')} - $e');
    return null;
  }
}

Future<bool> isGitRepository(Logger logger, String repoPath) async {
  const args = ['rev-parse', '--is-inside-work-tree'];
  final result = await runGitQuery(logger, repoPath, args);

  return result != null &&
      result.exitCode == 0 &&
      result.stdout.toString().trim() == 'true';
}

bool isValidBranchName(String branch) {
  if (branch.isEmpty) return false;
  if (branch.contains('..')) return false;
  if (branch.startsWith('-')) return false;
  if (branch.contains(RegExp(r'[\s\x00-\x1f\x7f]'))) return false;
  return _validBranchNamePattern.hasMatch(branch);
}

Future<String> getCurrentBranch(Logger logger, String repoPath) async {
  const args = ['symbolic-ref', '--short', 'HEAD'];
  final result = await runGitQuery(logger, repoPath, args);

  if (result == null || result.exitCode != 0) {
    return '';
  }

  return result.stdout.toString().trim();
}

Future<String?> getRepositoryUrl(Logger logger, String repoPath) async {
  const args = ['remote', 'get-url', 'origin'];
  final result = await runGitQuery(logger, repoPath, args);

  if (result != null && result.exitCode == 0) {
    return result.stdout.toString().trim();
  }

  return null;
}

Future<String?> getRepositoryName(Logger logger, String repoPath) async {
  final remoteUrl = await getRepositoryUrl(logger, repoPath);
  if (remoteUrl == null) return null;

  final httpsMatch = _httpsRepositoryPattern.firstMatch(remoteUrl);
  if (httpsMatch != null) {
    return httpsMatch.group(2);
  }

  final sshMatch = _sshRepositoryPattern.firstMatch(remoteUrl);
  if (sshMatch != null) {
    return sshMatch.group(2);
  }

  return null;
}

Future<bool> branchExists(Logger logger, String repoPath, String branch) async {
  // Check local branch first
  var args = ['show-ref', '--verify', '--quiet', 'refs/heads/$branch'];
  var result = await runGitQuery(logger, repoPath, args);
  if (result?.exitCode == 0) return true;

  // Fall back to remote tracking branch
  args = ['show-ref', '--verify', '--quiet', 'refs/remotes/origin/$branch'];
  result = await runGitQuery(logger, repoPath, args);
  return result?.exitCode == 0;
}

Future<bool> hasChangesToCommit(Logger logger, String repoPath) async {
  const args = ['status', '--porcelain'];
  final result = await runGitQuery(logger, repoPath, args);

  return result?.stdout.toString().trim().isNotEmpty ?? false;
}

Future<ProcessResult> runGitCommand(
  Logger logger,
  String workingDirectory,
  List<String> arguments, {
  bool dryRun = false,
}) async {
  if (dryRun) {
    logger.info('Would run: git ${arguments.join(' ')}');
    return ProcessResult(0, 0, '', '');
  }

  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );

  if (result.exitCode != 0) {
    throw Exception(
      'Git command failed: git ${arguments.join(' ')}\n${result.stderr}',
    );
  }

  return result;
}

Future<void> copyDirectory(
  Logger logger,
  String source,
  String destination, {
  bool dryRun = false,
}) async {
  if (dryRun) {
    logger.info('Would copy files from $source to $destination');
    return;
  }

  final sourceDir = Directory(source);
  if (!await sourceDir.exists()) {
    throw Exception('Source directory does not exist: $source');
  }

  await Directory(destination).create(recursive: true);

  await for (final entity in sourceDir.list(recursive: false)) {
    final newPath = path.join(destination, path.basename(entity.path));
    if (entity is Directory) {
      await copyDirectory(logger, entity.path, newPath);
    } else if (entity is File) {
      await entity.copy(newPath);
    }
  }
}

String getGitHubPagesUrl(String remoteUrl, String branch) {
  String? username;
  String? repository;

  final httpsMatch = _httpsRepositoryPattern.firstMatch(remoteUrl);
  if (httpsMatch != null) {
    username = httpsMatch.group(1);
    repository = httpsMatch.group(2);
  } else {
    final sshMatch = _sshRepositoryPattern.firstMatch(remoteUrl);
    if (sshMatch != null) {
      username = sshMatch.group(1);
      repository = sshMatch.group(2);
    }
  }

  if (username != null && repository != null) {
    if (branch == 'gh-pages') {
      return 'https://$username.github.io/$repository/';
    }
    if (repository == '$username.github.io' &&
        (branch == 'main' || branch == 'master')) {
      return 'https://$username.github.io/';
    }
  }

  return 'https://<username>.github.io/<repository>/';
}
