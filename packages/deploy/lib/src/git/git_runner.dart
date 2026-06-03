import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../utils/process_runner.dart';

/// Thrown when a mutating git command exits with a non-zero status.
class GitException implements Exception {
  /// The git arguments that failed.
  final List<String> arguments;

  /// The captured stderr output.
  final String stderr;

  const GitException(this.arguments, this.stderr);

  @override
  String toString() =>
      'Git command failed: git ${arguments.join(' ')}\n$stderr';
}

/// A thin wrapper around the `git` executable.
///
/// Distinguishes read-only [query] calls (which return `null` on failure) from
/// mutating [run] calls (which throw [GitException]). Honours [dryRun] for
/// mutating calls so publish flows can be previewed without side effects.
class GitRunner {
  /// The default working directory for git invocations.
  final String workingDirectory;

  /// Whether mutating commands should be logged instead of executed.
  final bool dryRun;

  final ProcessRunner _run;
  final Logger _logger;

  GitRunner({
    required this.workingDirectory,
    required Logger logger,
    this.dryRun = false,
    ProcessRunner? processRunner,
  }) : _logger = logger,
       _run = processRunner ?? defaultProcessRunner;

  /// Runs a mutating git command, throwing [GitException] on failure.
  ///
  /// When [dryRun] is set, the command is logged and a success result is
  /// returned without executing anything.
  Future<ProcessResult> run(
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (dryRun) {
      _logger.info('Would run: git ${arguments.join(' ')}');

      return ProcessResult(0, 0, '', '');
    }

    final result = await _run(
      'git',
      arguments,
      workingDirectory: workingDirectory ?? this.workingDirectory,
    );

    if (result.exitCode != 0) {
      throw GitException(arguments, result.stderr.toString());
    }

    return result;
  }

  /// Runs a read-only git command, returning `null` if git is unavailable or
  /// the command exits non-zero. Always executes, even in [dryRun] mode.
  Future<ProcessResult?> query(
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    try {
      final result = await _run(
        'git',
        arguments,
        workingDirectory: workingDirectory ?? this.workingDirectory,
      );

      return result.exitCode == 0 ? result : null;
    } on ProcessException catch (e) {
      _logger.detail('Git command failed: ${arguments.join(' ')} - ${e.message}');

      return null;
    } on IOException catch (e) {
      _logger.detail('Git I/O error: ${arguments.join(' ')} - $e');

      return null;
    }
  }

  /// Whether [workingDirectory] is inside a git work tree.
  Future<bool> isGitRepository() async {
    final result = await query(['rev-parse', '--is-inside-work-tree']);

    return result != null && result.stdout.toString().trim() == 'true';
  }

  /// The current branch name, or `null` if it cannot be determined.
  Future<String?> currentBranch() async {
    final result = await query(['symbolic-ref', '--short', 'HEAD']);

    return result?.stdout.toString().trim();
  }

  /// The `origin` remote URL, or `null` if there is no origin.
  Future<String?> remoteUrl() async {
    final result = await query(['remote', 'get-url', 'origin']);

    return result?.stdout.toString().trim();
  }

  /// Whether a local branch named [branch] exists.
  Future<bool> branchExists(String branch) async {
    final result = await query([
      'show-ref',
      '--verify',
      '--quiet',
      'refs/heads/$branch',
    ]);

    return result != null;
  }

  /// Whether [workingDirectory] has staged or unstaged changes.
  Future<bool> hasChangesToCommit({String? workingDirectory}) async {
    final result = await query(
      ['status', '--porcelain'],
      workingDirectory: workingDirectory,
    );

    return result?.stdout.toString().trim().isNotEmpty ?? false;
  }
}
