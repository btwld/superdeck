import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../git/git_runner.dart';
import '../git/github_remote.dart';
import '../git/worktree.dart';
import '../utils/branch_validation.dart';
import '../utils/process_runner.dart';
import '../web/build_web.dart';
import '../web/index_html_template.dart';

/// Configuration for a GitHub Pages publish.
class GitHubPagesOptions {
  /// Branch to publish the built site into.
  final String branch;

  /// Commit message for the publish commit.
  final String message;

  /// Whether to push to `origin` after committing.
  final bool push;

  /// Whether to run `flutter build web` before publishing.
  final bool build;

  /// Directory (relative to [appDir], or absolute) holding the built assets.
  final String buildDir;

  /// The Flutter app directory to build.
  final String appDir;

  /// Explicit `--base-href` override; auto-detected from the remote when null.
  final String? baseHref;

  /// Whether to plan the publish without making changes.
  final bool dryRun;

  const GitHubPagesOptions({
    this.branch = 'gh-pages',
    this.message = 'Publish SuperDeck app to GitHub Pages',
    this.push = true,
    this.build = true,
    this.buildDir = 'build/web',
    this.appDir = '.',
    this.baseHref,
    this.dryRun = false,
  });
}

/// Publishes a built SuperDeck web app to a GitHub Pages branch using an
/// isolated git worktree.
class GitHubPagesTarget {
  final Logger _logger;
  final ProcessRunner _run;

  GitHubPagesTarget({required Logger logger, ProcessRunner? processRunner})
    : _logger = logger,
      _run = processRunner ?? defaultProcessRunner;

  /// Runs the publish flow. Returns an exit code (0 == success).
  Future<int> publish(GitHubPagesOptions options) async {
    if (!isValidBranchName(options.branch)) {
      _logger.err(
        'Invalid branch name: "${options.branch}". Branch names must start '
        'with an alphanumeric character and contain only letters, numbers, '
        'dots, hyphens, underscores, or slashes.',
      );

      return ExitCode.usage.code;
    }

    if (options.dryRun) {
      _logger.info('Running in dry-run mode. No changes will be made.');
    }

    final currentDir = Directory.current.path;
    final appDir = p.normalize(p.join(currentDir, options.appDir));
    final buildDir = p.normalize(
      p.isAbsolute(options.buildDir)
          ? options.buildDir
          : p.join(appDir, options.buildDir),
    );

    final git = GitRunner(
      workingDirectory: currentDir,
      logger: _logger,
      dryRun: options.dryRun,
      processRunner: _run,
    );

    if (!await git.isGitRepository()) {
      _logger.err(
        'Not a git repository. Run this command from within a git repository.',
      );

      return ExitCode.usage.code;
    }

    final currentBranch = await git.currentBranch();
    if (currentBranch == null || currentBranch.isEmpty) {
      _logger.err('Failed to determine the current branch.');

      return ExitCode.software.code;
    }

    final remote = await _resolveRemote(git);

    String? indexHtmlBackup;
    if (options.build) {
      final baseHref = options.baseHref ?? remote?.baseHref;
      if (baseHref != null) {
        _logger.info('Using base-href: $baseHref');
      }

      indexHtmlBackup = await installLoadingIndexHtml(
        p.join(appDir, 'web'),
        logger: _logger,
        dryRun: options.dryRun,
      );

      final builder = WebBuilder(
        logger: _logger,
        processRunner: _run,
      );
      final built = await builder.build(
        appDir: appDir,
        baseHref: baseHref,
        outputDir: buildDir,
        dryRun: options.dryRun,
      );

      if (!built && !options.dryRun) {
        _logger.err('Web build failed. Publication aborted.');
        await restoreIndexHtml(indexHtmlBackup, logger: _logger);

        return ExitCode.software.code;
      }
    }

    if (!options.dryRun && !Directory(buildDir).existsSync()) {
      _logger.err('Build directory not found: $buildDir');
      _logger.info(
        'Build the web app before publishing, or omit --no-build to build '
        'automatically.',
      );
      await restoreIndexHtml(indexHtmlBackup, logger: _logger);

      return ExitCode.usage.code;
    }

    final worktree = GitWorktree(
      git: git,
      logger: _logger,
      dryRun: options.dryRun,
    );
    final progress = _logger.progress(
      'Publishing to "${options.branch}" branch',
    );

    try {
      await worktree.create(targetBranch: options.branch);
      await _replaceWorktreeContents(
        worktree.path,
        buildDir,
        dryRun: options.dryRun,
      );

      await git.run(['add', '.'], workingDirectory: worktree.path);

      final hasChanges =
          options.dryRun ||
          await git.hasChangesToCommit(workingDirectory: worktree.path);

      if (hasChanges) {
        await git.run([
          'commit',
          '-m',
          '${options.message}\n\nPublished from branch $currentBranch',
        ], workingDirectory: worktree.path);

        if (options.push) {
          await git.run([
            'push',
            'origin',
            options.branch,
          ], workingDirectory: worktree.path);
        }
      } else {
        _logger.info(
          'No changes to commit. The published content is already up to date.',
        );
      }

      progress.complete(
        options.dryRun ? 'Dry run completed' : 'Publication successful',
      );

      _reportResult(options, remote, currentBranch, hasChanges: hasChanges);

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      progress.fail('Publication failed');
      _logger.err('Error during publication: $e');
      _logger.detail('$stackTrace');

      return ExitCode.software.code;
    } finally {
      await restoreIndexHtml(indexHtmlBackup, logger: _logger);
      await worktree.remove();
    }
  }

  Future<GitHubRemote?> _resolveRemote(GitRunner git) async {
    final url = await git.remoteUrl();

    return url == null ? null : GitHubRemote.parse(url);
  }

  /// Clears the worktree (except `.git`), copies the build output in, and writes
  /// a `.nojekyll` marker.
  Future<void> _replaceWorktreeContents(
    String worktreePath,
    String buildDir, {
    required bool dryRun,
  }) async {
    if (dryRun) {
      _logger.info('Would clear and update content in the target branch');
      _logger.info('Would copy web build files from $buildDir');
      _logger.info('Would create a .nojekyll file');

      return;
    }

    final entities = Directory(worktreePath)
        .listSync()
        .where((entity) => p.basename(entity.path) != '.git')
        .toList();

    for (final entity in entities) {
      if (!entity.existsSync()) continue;
      await entity.delete(recursive: entity is Directory);
    }

    await _copyDirectory(buildDir, worktreePath);
    File(p.join(worktreePath, '.nojekyll')).createSync();
  }

  Future<void> _copyDirectory(String source, String destination) async {
    final sourceDir = Directory(source);
    if (!await sourceDir.exists()) {
      throw Exception('Source directory does not exist: $source');
    }

    await Directory(destination).create(recursive: true);

    await for (final entity in sourceDir.list(recursive: false)) {
      final newPath = p.join(destination, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity.path, newPath);
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  void _reportResult(
    GitHubPagesOptions options,
    GitHubRemote? remote,
    String currentBranch, {
    required bool hasChanges,
  }) {
    final pagesUrl = remote?.pagesUrl(options.branch);

    if (!options.push && hasChanges && !options.dryRun) {
      _logger.info('\nTo push your changes to GitHub, run:');
      _logger.info('  git push origin ${options.branch}');
    }

    if (pagesUrl == null) return;

    if (options.push && !options.dryRun) {
      _logger.info('\nYour SuperDeck app is now published to GitHub Pages!');
      _logger.info('Your site is available at: $pagesUrl');
      _logger.info(
        '\nNote: it may take a few minutes for GitHub to build and deploy.',
      );
    } else if (!options.dryRun) {
      _logger.info('\nWhen pushed, your site will be available at: $pagesUrl');
    }
  }
}
