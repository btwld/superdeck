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
        'revert',
        help:
            'Revert the last publication by resetting the branch to its remote state',
        negatable: false,
      )
      ..addFlag(
        'push',
        help: 'Push the changes to remote after publication',
        defaultsTo: false,
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
      );
  }

  /// Reverts the publication by resetting the target branch to its remote state
  Future<int> _revertPublication(String repoPath, String targetBranch) async {
    _logger.info('Reverting publication...');
    final progress =
        _logger.progress('Reverting $targetBranch to remote state');

    try {
      // Get current branch
      final String currentBranch = await _getCurrentBranch(repoPath);

      // Check if target branch exists
      if (!await _branchExists(repoPath, targetBranch)) {
        progress.fail('Target branch does not exist');

        return ExitCode.usage.code;
      }

      // Check if remote branch exists
      final ProcessResult remoteResult = await Process.run(
        'git',
        ['ls-remote', '--heads', 'origin', targetBranch],
        workingDirectory: repoPath,
      );

      final bool remoteExists =
          remoteResult.stdout.toString().trim().isNotEmpty;

      if (remoteExists) {
        // Reset local branch to match remote
        await _runGitCommand(repoPath, ['checkout', targetBranch]);
        await _runGitCommand(repoPath, ['fetch', 'origin', targetBranch]);
        await _runGitCommand(
          repoPath,
          ['reset', '--hard', 'origin/$targetBranch'],
        );

        // Switch back to original branch
        await _runGitCommand(repoPath, ['checkout', currentBranch]);

        progress.complete('Publication reverted successfully');
      } else {
        // If remote doesn't exist, delete the local branch
        await _runGitCommand(repoPath, ['checkout', currentBranch]);
        await _runGitCommand(repoPath, ['branch', '-D', targetBranch]);

        progress.complete('Local branch deleted (no remote branch found)');
      }

      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Revert failed');
      _logger.err('Error during revert: $e');

      return ExitCode.software.code;
    }
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

  /// Checks if the repository has uncommitted changes
  Future<bool> _hasUncommittedChanges(String repoPath) async {
    try {
      final ProcessResult result = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: repoPath,
      );

      return result.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      return true; // Assume uncommitted changes on error
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

  /// Builds the web app
  Future<bool> _buildWebApp(
    String workingDirectory, {
    bool dryRun = false,
  }) async {
    if (dryRun) {
      _logger.info('Would build app for web');

      return true;
    }

    final progress = _logger.progress('Building app');

    try {
      // First, try with standard release mode
      _logger.detail('Building Flutter web app...');
      final ProcessResult result = await Process.run(
        'flutter',
        ['build', 'web', '--release'],
        workingDirectory: workingDirectory,
      );

      if (result.exitCode == 0) {
        progress.complete('Build completed successfully');

        return true;
      }

      _logger.detail('Standard build failed, trying alternative options...');

      // If standard build fails, try with html renderer
      _logger.detail('Attempting build with HTML renderer...');
      final ProcessResult htmlResult = await Process.run(
        'flutter',
        ['build', 'web', '--release', '--web-renderer=html'],
        workingDirectory: workingDirectory,
      );

      if (htmlResult.exitCode == 0) {
        progress.complete('Build completed successfully with HTML renderer');

        return true;
      }

      // If all builds fail, report error
      progress.fail('Build failed');
      _logger.err('All build attempts failed:');
      _logger.err(result.stderr.toString());

      return false;
    } catch (e) {
      progress.fail('Build failed');
      _logger.err('Error during build: $e');

      return false;
    }
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

  @override
  Future<int> run() async {
    final ArgResults args = argResults!;

    final String targetBranch = args['branch'] as String;
    final String commitMessage = args['message'] as String;
    final bool shouldRevert = args['revert'] as bool;
    final bool shouldPush = args['push'] as bool;
    final String buildDirRelative = args['build-dir'] as String;
    final bool dryRun = args['dry-run'] as bool;

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

    // Handle revert option
    if (shouldRevert) {
      if (dryRun) {
        _logger.info('Would revert publication of branch $targetBranch');

        return ExitCode.success.code;
      }

      return _revertPublication(currentDir, targetBranch);
    }

    // Get the current branch
    final String currentBranch = await _getCurrentBranch(currentDir);
    if (currentBranch.isEmpty) {
      _logger.err('Failed to determine current branch.');

      return ExitCode.software.code;
    }

    // Check for uncommitted changes
    if (await _hasUncommittedChanges(currentDir)) {
      _logger.warn(
        'You have uncommitted changes. This might interfere with publication.',
      );
      final bool shouldContinue = _logger.confirm(
        'Do you want to continue?',
        defaultValue: false,
      );

      if (!shouldContinue) {
        _logger.info('Publication cancelled.');

        return ExitCode.success.code;
      }
    }

    // Build the app
    _logger.info('Building Superdeck app...');

    final bool buildSuccessful = await _buildWebApp(currentDir, dryRun: dryRun);
    if (!buildSuccessful && !dryRun) {
      _logger.info('');
      _logger.info('Hint: Check your Flutter web build configuration.');

      return ExitCode.software.code;
    }

    // Check build directory
    if (!dryRun && !Directory(buildDir).existsSync()) {
      _logger.err('Build directory not found: $buildDir');
      _logger.info(
        'Build process failed to create the expected output directory.',
      );

      return ExitCode.usage.code;
    }

    // Publish to GitHub Pages
    _logger.info('Publishing to GitHub Pages...');
    final progress = _logger.progress('Publishing to $targetBranch branch');

    try {
      // Create a temporary directory for publication
      Directory? tempDir;
      String tempPath;

      if (dryRun) {
        tempPath = '/tmp/superdeck_publish_dryrun';
        _logger.info('Would create temporary directory for publication');
      } else {
        tempDir = await Directory.systemTemp.createTemp('superdeck_publish_');
        tempPath = tempDir.path;
      }

      // Copy build files to temp directory
      await _copyDirectory(buildDir, tempPath, dryRun: dryRun);

      // Switch to target branch or create it if it doesn't exist
      if (await _branchExists(currentDir, targetBranch)) {
        await _runGitCommand(
          currentDir,
          ['checkout', targetBranch],
          dryRun: dryRun,
        );
      } else {
        await _runGitCommand(
          currentDir,
          ['checkout', '--orphan', targetBranch],
          dryRun: dryRun,
        );
        await _runGitCommand(currentDir, ['rm', '-rf', '.'], dryRun: dryRun);
      }

      if (!dryRun) {
        // Clear current content in branch (except .git)
        final List<FileSystemEntity> entities = Directory(currentDir)
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

        // Copy content from temp directory to working directory
        await _copyDirectory(tempPath, currentDir);

        // Create a .nojekyll file to bypass Jekyll processing
        File(path.join(currentDir, '.nojekyll')).createSync();
      } else {
        _logger.info('Would clear and update content in $targetBranch branch');
        _logger.info('Would create .nojekyll file to bypass Jekyll processing');
      }

      // Stage, commit, and optionally push changes
      await _runGitCommand(currentDir, ['add', '.'], dryRun: dryRun);
      await _runGitCommand(
        currentDir,
        [
          'commit',
          '-m',
          '$commitMessage\n\nPublished from branch $currentBranch',
        ],
        dryRun: dryRun,
      );

      if (shouldPush) {
        await _runGitCommand(
          currentDir,
          ['push', 'origin', targetBranch],
          dryRun: dryRun,
        );
      }

      // Clean up temporary directory
      if (tempDir != null && !dryRun) {
        await tempDir.delete(recursive: true);
      } else if (dryRun) {
        _logger.info('Would clean up temporary directory');
      }

      // Switch back to original branch
      await _runGitCommand(
        currentDir,
        ['checkout', currentBranch],
        dryRun: dryRun,
      );

      progress.complete(
        dryRun ? 'Dry run completed successfully' : 'Publication successful',
      );

      if (!shouldPush && !dryRun) {
        _logger.info('\nTo push your changes to GitHub, run:');
        _logger.info('  git push origin $targetBranch');
      }

      if (!dryRun && shouldPush) {
        _logger.info('\nYour Superdeck app is now published to GitHub Pages!');
        _logger.info(
          'It should be available at: https://<username>.github.io/<repository>/',
        );
      }

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      progress.fail('Publication failed');
      _logger.err('Error during publication: $e');
      _logger.detail('$stackTrace');

      // Try to switch back to original branch in case of failure
      if (!dryRun) {
        try {
          await _runGitCommand(currentDir, ['checkout', currentBranch]);
        } catch (e) {
          _logger.err('Failed to switch back to $currentBranch: $e');
        }
      }

      return ExitCode.software.code;
    }
  }
}
