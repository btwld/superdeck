import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'git_runner.dart';

/// Manages an isolated git worktree used to publish built assets to a target
/// branch without disturbing the user's working tree.
///
/// Create with [create], then operate inside [path]; always call [remove] in a
/// `finally` block to guarantee cleanup.
class GitWorktree {
  /// The absolute path of the temporary worktree directory.
  late final String path;

  final GitRunner _git;
  final Logger _logger;
  final bool _dryRun;
  bool _created = false;

  GitWorktree({
    required GitRunner git,
    required Logger logger,
    bool dryRun = false,
  }) : _git = git,
       _logger = logger,
       _dryRun = dryRun;

  /// Adds a worktree for [targetBranch], creating it as an orphan branch when
  /// it does not already exist.
  Future<void> create({required String targetBranch}) async {
    path = p.join(
      Directory.systemTemp.path,
      'superdeck_publish_${DateTime.now().millisecondsSinceEpoch}',
    );

    final branchExists = await _git.branchExists(targetBranch);
    if (branchExists) {
      await _git.run(['worktree', 'add', '-f', path, targetBranch]);
    } else {
      await _git.run(['worktree', 'add', '--detach', path]);
    }
    _created = !_dryRun;

    if (!branchExists) {
      await _git.run(
        ['checkout', '--orphan', targetBranch],
        workingDirectory: path,
      );
      await _git.run(['rm', '-rf', '.'], workingDirectory: path);
    }
  }

  /// Removes the worktree if one was created.
  Future<void> remove() async {
    if (_created) {
      try {
        await _git.run(['worktree', 'remove', '--force', path]);
      } catch (e) {
        _logger.warn('Failed to clean up temporary git worktree: $e');
      }
    } else if (_dryRun) {
      _logger.info('Would clean up the temporary git worktree at $path');
    }
  }
}
