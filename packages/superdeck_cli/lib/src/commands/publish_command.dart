import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../helpers/logger.dart';

/// Command to publish a Superdeck app to GitHub Pages
class PublishCommand extends Command<int> {
  @override
  final String name = 'publish';

  @override
  final String description = 'Publish Superdeck app to GitHub Pages';

  final Logger _logger;

  PublishCommand({Logger? loggerOverride})
      : _logger = loggerOverride ?? logger {
    argParser
      ..addOption(
        'branch',
        abbr: 'b',
        help: 'The git branch where the built content will be published',
        defaultsTo: 'gh-pages',
      )
      ..addOption(
        'message',
        abbr: 'm',
        help: 'The commit message for the publication',
        defaultsTo: 'Publish Superdeck app to GitHub Pages',
      )
      ..addFlag(
        'push',
        help: 'Push the changes to remote after publication',
        defaultsTo: true,
      )
      ..addOption(
        'build-dir',
        help: 'Directory containing the built web assets to publish',
        defaultsTo: 'build/web',
      )
      ..addFlag(
        'dry-run',
        help:
            'Run through the publication process without making actual changes',
        negatable: false,
      )
      ..addFlag(
        'build',
        help: 'Build the web app before publishing',
        defaultsTo: true,
      );
  }

  /// Checks if the current directory is a git repository
  Future<bool> _isGitRepository(String repoPath) async {
    try {
      final ProcessResult result = await Process.run(
        'git',
        ['rev-parse', '--is-inside-work-tree'],
        workingDirectory: repoPath,
      );

      return result.exitCode == 0 && result.stdout.toString().trim() == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Gets the current branch name
  Future<String> _getCurrentBranch(String repoPath) async {
    try {
      final ProcessResult result = await Process.run(
        'git',
        ['symbolic-ref', '--short', 'HEAD'],
        workingDirectory: repoPath,
      );

      return result.stdout.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// Gets the repository name from the remote URL
  Future<String?> _getRepositoryName(String repoPath) async {
    final String? remoteUrl = await _getRepositoryUrl(repoPath);
    if (remoteUrl == null) return null;

    // Extract repository name from different URL formats
    // Handle HTTPS URL: https://github.com/username/repo.git
    final httpsMatch = RegExp(r'https://github\.com/([^/]+)/([^/.]+)(\.git)?')
        .firstMatch(remoteUrl);
    if (httpsMatch != null) {
      return httpsMatch.group(2);
    }

    // Handle SSH URL: git@github.com:username/repo.git
    final sshMatch = RegExp(r'git@github\.com:([^/]+)/([^/.]+)(\.git)?')
        .firstMatch(remoteUrl);
    if (sshMatch != null) {
      return sshMatch.group(2);
    }

    return null;
  }

  /// Builds the web app with appropriate base href
  Future<bool> _buildWebApp(
    String workingDirectory, {
    String? baseHref,
    bool dryRun = false,
  }) async {
    if (dryRun) {
      if (baseHref != null) {
        _logger.info('Would build web app with base-href: $baseHref');
      } else {
        _logger.info('Would build web app with default base-href');
      }

      return true;
    }

    final progress = _logger.progress('Building Flutter web app');

    try {
      final List<String> buildArgs = ['build', 'web', '--release'];

      // Add base-href if provided
      if (baseHref != null) {
        buildArgs.add('--base-href=$baseHref');
      }

      final ProcessResult result = await Process.run(
        'flutter',
        buildArgs,
        workingDirectory: workingDirectory,
      );

      if (result.exitCode == 0) {
        progress.complete('Web build completed successfully');

        return true;
      }
      progress.fail('Web build failed');
      _logger.err(result.stderr.toString());

      return false;
    } catch (e) {
      progress.fail('Web build failed');
      _logger.err('Error during build: $e');

      return false;
    }
  }

  /// Checks if a branch exists
  Future<bool> _branchExists(String repoPath, String branch) async {
    try {
      final ProcessResult result = await Process.run(
        'git',
        ['show-ref', '--verify', '--quiet', 'refs/heads/$branch'],
        workingDirectory: repoPath,
      );

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Checks if there are any changes to commit
  Future<bool> _hasChangesToCommit(String repoPath) async {
    try {
      final ProcessResult result = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: repoPath,
      );

      return result.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Runs a git command
  Future<ProcessResult> _runGitCommand(
    String workingDirectory,
    List<String> arguments, {
    bool dryRun = false,
  }) async {
    if (dryRun) {
      _logger.info('Would run: git ${arguments.join(' ')}');

      return ProcessResult(0, 0, '', '');
    }

    final ProcessResult result = await Process.run(
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

  /// Copies directories recursively
  Future<void> _copyDirectory(
    String source,
    String destination, {
    bool dryRun = false,
  }) async {
    if (dryRun) {
      _logger.info('Would copy files from $source to $destination');

      return;
    }

    final Directory sourceDir = Directory(source);
    if (!await sourceDir.exists()) {
      throw Exception('Source directory does not exist: $source');
    }

    await Directory(destination).create(recursive: true);

    await for (final entity in sourceDir.list(recursive: false)) {
      final String newPath = path.join(
        destination,
        path.basename(entity.path),
      );

      if (entity is Directory) {
        await _copyDirectory(entity.path, newPath);
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  /// Gets the remote URL for the repository
  Future<String?> _getRepositoryUrl(String repoPath) async {
    try {
      final ProcessResult result = await Process.run(
        'git',
        ['remote', 'get-url', 'origin'],
        workingDirectory: repoPath,
      );

      if (result.exitCode == 0) {
        final String url = result.stdout.toString().trim();

        return url;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Converts a git remote URL to a GitHub Pages URL
  String _getGitHubPagesUrl(String remoteUrl, String branch) {
    // Extract username and repository from different URL formats
    String? username;
    String? repository;

    // Handle HTTPS URL: https://github.com/username/repo.git
    final httpsMatch = RegExp(r'https://github\.com/([^/]+)/([^/.]+)(\.git)?')
        .firstMatch(remoteUrl);
    if (httpsMatch != null) {
      username = httpsMatch.group(1);
      repository = httpsMatch.group(2);
    }
    // Handle SSH URL: git@github.com:username/repo.git
    else {
      final sshMatch = RegExp(r'git@github\.com:([^/]+)/([^/.]+)(\.git)?')
          .firstMatch(remoteUrl);
      if (sshMatch != null) {
        username = sshMatch.group(1);
        repository = sshMatch.group(2);
      }
    }

    if (username != null && repository != null) {
      // Default GitHub Pages URL format
      if (branch == 'gh-pages') {
        return 'https://$username.github.io/$repository/';
      }
      // For username.github.io repositories with main branch
      else if (repository == '$username.github.io' &&
          (branch == 'main' || branch == 'master')) {
        return 'https://$username.github.io/';
      }
    }

    // Fallback if we couldn't determine the URL format
    return 'https://<username>.github.io/<repository>/';
  }

  @override
  Future<int> run() async {
    final ArgResults args = argResults!;

    final String targetBranch = args['branch'] as String;
    final String commitMessage = args['message'] as String;
    final bool shouldPush = args['push'] as bool;
    final String buildDirRelative = args['build-dir'] as String;
    final bool dryRun = args['dry-run'] as bool;
    final bool shouldBuild = args['build'] as bool;

    if (dryRun) {
      _logger.info('Running in dry-run mode. No changes will be made.');
    }

    // Get current directory
    final String currentDir = Directory.current.path;
    final String buildDir = path.join(currentDir, buildDirRelative);

    // Check if we're in a git repository
    if (!await _isGitRepository(currentDir)) {
      _logger.err(
        'Not a git repository. Please run this command in a git repository.',
      );

      return ExitCode.usage.code;
    }

    // Get the current branch
    final String currentBranch = await _getCurrentBranch(currentDir);
    if (currentBranch.isEmpty) {
      _logger.err('Failed to determine current branch.');

      return ExitCode.software.code;
    }

    // Auto-detect base-href for GitHub Pages
    String? baseHref;
    if (shouldBuild) {
      final String? repoName = await _getRepositoryName(currentDir);
      if (repoName != null) {
        baseHref = '/$repoName/';
        _logger.info('Auto-detected base-href: $baseHref');
      }
    }

    // Build the web app if requested
    if (shouldBuild) {
      _logger.info('Building web app...');
      final bool buildSuccessful = await _buildWebApp(
        currentDir,
        baseHref: baseHref,
        dryRun: dryRun,
      );

      if (!buildSuccessful && !dryRun) {
        _logger.err('Web build failed. Publication aborted.');

        return ExitCode.software.code;
      }
    }

    // Check build directory exists
    if (!dryRun && !Directory(buildDir).existsSync()) {
      _logger.err('Build directory not found: $buildDir');
      _logger.info(
        'Please make sure your web app is built before publishing or use the default --build flag.',
      );

      return ExitCode.usage.code;
    }

    // Publish to GitHub Pages
    _logger.info('Publishing to GitHub Pages...');
    final progress = _logger.progress('Publishing to $targetBranch branch');

    try {
      // Create a temporary git worktree for the target branch
      final String tempDir = path.join(
        Directory.systemTemp.path,
        'superdeck_publish_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!dryRun) {
        await Directory(tempDir).create(recursive: true);
      } else {
        _logger.info('Would create temporary directory at $tempDir');
      }

      // Use git worktree to handle the branch switching without affecting the working directory
      if (await _branchExists(currentDir, targetBranch)) {
        // If branch exists, add a worktree for it
        await _runGitCommand(
          currentDir,
          ['worktree', 'add', '-f', tempDir, targetBranch],
          dryRun: dryRun,
        );
      } else {
        // If branch doesn't exist, create it as an orphan branch
        await _runGitCommand(
          currentDir,
          ['worktree', 'add', '--detach', tempDir],
          dryRun: dryRun,
        );

        await _runGitCommand(
          tempDir,
          ['checkout', '--orphan', targetBranch],
          dryRun: dryRun,
        );

        // Clean out any files in the new branch
        await _runGitCommand(tempDir, ['rm', '-rf', '.'], dryRun: dryRun);
      }

      if (!dryRun) {
        // Clear existing content in the worktree (except .git)
        final List<FileSystemEntity> entities = Directory(tempDir)
            .listSync()
            .where((entity) => path.basename(entity.path) != '.git')
            .toList();

        for (final entity in entities) {
          if (entity.existsSync()) {
            if (entity is Directory) {
              await entity.delete(recursive: true);
            } else {
              await entity.delete();
            }
          }
        }

        // Copy build directory contents to the worktree
        await _copyDirectory(buildDir, tempDir);

        // Create a .nojekyll file to bypass Jekyll processing
        File(path.join(tempDir, '.nojekyll')).createSync();
      } else {
        _logger.info('Would clear and update content in $targetBranch branch');
        _logger.info('Would copy web build files to the branch');
        _logger.info('Would create .nojekyll file to bypass Jekyll processing');
      }

      // Stage and commit changes
      await _runGitCommand(tempDir, ['add', '.'], dryRun: dryRun);

      // Only commit if there are changes
      final bool hasChanges = dryRun || await _hasChangesToCommit(tempDir);

      if (hasChanges) {
        await _runGitCommand(
          tempDir,
          [
            'commit',
            '-m',
            '$commitMessage\n\nPublished from branch $currentBranch',
          ],
          dryRun: dryRun,
        );

        // Push if requested
        if (shouldPush) {
          await _runGitCommand(
            tempDir,
            ['push', 'origin', targetBranch],
            dryRun: dryRun,
          );
        }
      } else {
        _logger.info(
          'No changes to commit. The published content is already up to date.',
        );
      }

      // Clean up the worktree
      if (!dryRun) {
        await _runGitCommand(
          currentDir,
          ['worktree', 'remove', tempDir],
          dryRun: dryRun,
        );
      } else {
        _logger.info('Would clean up the temporary git worktree');
      }

      progress.complete(
        dryRun ? 'Dry run completed successfully' : 'Publication successful',
      );

      if (!shouldPush && !dryRun && hasChanges) {
        _logger.info('\nTo push your changes to GitHub, run:');
        _logger.info('  git push origin $targetBranch');
      }

      if (!dryRun && shouldPush) {
        final String? remoteUrl = await _getRepositoryUrl(currentDir);
        String pagesUrl = 'https://<username>.github.io/<repository>/';

        if (remoteUrl != null) {
          pagesUrl = _getGitHubPagesUrl(remoteUrl, targetBranch);
        }

        _logger.info('\nYour Superdeck app is now published to GitHub Pages!');
        _logger.info('Your site is available at: $pagesUrl');

        // Add note about delay
        _logger.info(
          '\nNote: It may take a few minutes for GitHub to build and deploy your site.',
        );
      } else if (!dryRun) {
        // Show the URL even when not pushing
        final String? remoteUrl = await _getRepositoryUrl(currentDir);
        if (remoteUrl != null) {
          final String pagesUrl = _getGitHubPagesUrl(remoteUrl, targetBranch);
          _logger
              .info('\nWhen pushed, your site will be available at: $pagesUrl');
        }
      }

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      progress.fail('Publication failed');
      _logger.err('Error during publication: $e');
      _logger.detail('$stackTrace');

      return ExitCode.software.code;
    }
  }
}
