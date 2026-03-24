import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../utils/logger.dart';
import 'publish/build_support.dart';
import 'publish/git_support.dart';

/// Command to publish a Superdeck app to GitHub Pages.
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
      )
      ..addOption(
        'example-dir',
        help: 'Directory containing the example app to build',
        defaultsTo: '.',
      );
  }

  @override
  Future<int> run() async {
    final args = argResults!;
    final targetBranch = args['branch'] as String;
    final commitMessage = args['message'] as String;
    final shouldPush = args['push'] as bool;
    final dryRun = args['dry-run'] as bool;
    final shouldBuild = args['build'] as bool;
    final exampleDirArg = args['example-dir'] as String;
    final buildDirArg = args['build-dir'] as String;

    if (!isValidBranchName(targetBranch)) {
      _logger.err(
        'Invalid branch name: "$targetBranch". '
        'Branch names must start with alphanumeric and contain only '
        'letters, numbers, dots, hyphens, underscores, or slashes.',
      );
      return ExitCode.usage.code;
    }

    if (dryRun) {
      _logger.info('Running in dry-run mode. No changes will be made.');
    }

    final currentDir = Directory.current.path;
    final exampleDir = path.normalize(path.join(currentDir, exampleDirArg));
    final buildDir = path.normalize(
      path.isAbsolute(buildDirArg)
          ? buildDirArg
          : path.join(exampleDir, buildDirArg),
    );

    if (!await isGitRepository(_logger, currentDir)) {
      _logger.err(
        'Not a git repository. Please run this command in a git repository.',
      );
      return ExitCode.usage.code;
    }

    final currentBranch = await getCurrentBranch(_logger, currentDir);
    if (currentBranch.isEmpty) {
      _logger.err('Failed to determine current branch.');
      return ExitCode.software.code;
    }

    String? baseHref;
    if (shouldBuild) {
      final repoName = await getRepositoryName(_logger, currentDir);
      if (repoName != null) {
        baseHref = '/$repoName/';
        _logger.info('Auto-detected base-href: $baseHref');
      }
    }

    Future<int> runPublication() async {
      if (shouldBuild) {
        _logger.info('Building web app...');
        final buildSuccessful = await buildWebApp(
          _logger,
          currentDir,
          exampleDir: exampleDirArg,
          baseHref: baseHref,
          outputDirectory: buildDir,
          dryRun: dryRun,
        );

        if (!buildSuccessful && !dryRun) {
          _logger.err('Web build failed. Publication aborted.');
          return ExitCode.software.code;
        }
      }

      if (!dryRun && !Directory(buildDir).existsSync()) {
        _logger.err('Build directory not found: $buildDir');
        _logger.info(
          'Please make sure your web app is built before publishing or use the default --build flag.',
        );
        return ExitCode.usage.code;
      }

      _logger.info('Publishing to GitHub Pages...');
      final progress = _logger.progress('Publishing to $targetBranch branch');
      String? tempDir;
      var worktreeCreated = false;

      try {
        tempDir = path.join(
          Directory.systemTemp.path,
          'superdeck_publish_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (!dryRun) {
          await Directory(tempDir).create(recursive: true);
        } else {
          _logger.info('Would create temporary directory at $tempDir');
        }

        if (await branchExists(_logger, currentDir, targetBranch)) {
          await runGitCommand(_logger, currentDir, [
            'worktree',
            'add',
            '-f',
            tempDir,
            targetBranch,
          ], dryRun: dryRun);
          worktreeCreated = !dryRun;
        } else {
          await runGitCommand(_logger, currentDir, [
            'worktree',
            'add',
            '--detach',
            tempDir,
          ], dryRun: dryRun);
          worktreeCreated = !dryRun;

          await runGitCommand(_logger, tempDir, [
            'checkout',
            '--orphan',
            targetBranch,
          ], dryRun: dryRun);
          await runGitCommand(_logger, tempDir, const [
            'rm',
            '-rf',
            '.',
          ], dryRun: dryRun);
        }

        if (!dryRun) {
          final entities = Directory(tempDir)
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

          await copyDirectory(_logger, buildDir, tempDir);
          File(path.join(tempDir, '.nojekyll')).createSync();
        } else {
          _logger.info(
            'Would clear and update content in $targetBranch branch',
          );
          _logger.info('Would copy web build files to the branch');
          _logger.info(
            'Would create .nojekyll file to bypass Jekyll processing',
          );
        }

        await runGitCommand(_logger, tempDir, const [
          'add',
          '.',
        ], dryRun: dryRun);

        final hasChanges = dryRun || await hasChangesToCommit(_logger, tempDir);
        if (hasChanges) {
          await runGitCommand(_logger, tempDir, [
            'commit',
            '-m',
            '$commitMessage\n\nPublished from branch $currentBranch',
          ], dryRun: dryRun);

          if (shouldPush) {
            await runGitCommand(_logger, tempDir, [
              'push',
              'origin',
              targetBranch,
            ], dryRun: dryRun);
          }
        } else {
          _logger.info(
            'No changes to commit. The published content is already up to date.',
          );
        }

        progress.complete(
          dryRun ? 'Dry run completed successfully' : 'Publication successful',
        );

        if (!shouldPush && !dryRun && hasChanges) {
          _logger.info('\nTo push your changes to GitHub, run:');
          _logger.info('  git push origin $targetBranch');
        }

        if (!dryRun && shouldPush) {
          final remoteUrl = await getRepositoryUrl(_logger, currentDir);
          final pagesUrl = remoteUrl != null
              ? getGitHubPagesUrl(remoteUrl, targetBranch)
              : 'https://<username>.github.io/<repository>/';

          _logger.info(
            '\nYour Superdeck app is now published to GitHub Pages!',
          );
          _logger.info('Your site is available at: $pagesUrl');
          _logger.info(
            '\nNote: It may take a few minutes for GitHub to build and deploy your site.',
          );
        } else if (!dryRun) {
          final remoteUrl = await getRepositoryUrl(_logger, currentDir);
          if (remoteUrl != null) {
            _logger.info(
              '\nWhen pushed, your site will be available at: '
              '${getGitHubPagesUrl(remoteUrl, targetBranch)}',
            );
          }
        }

        return ExitCode.success.code;
      } catch (e, stackTrace) {
        progress.fail('Publication failed');
        _logger.err('Error during publication: $e');
        _logger.detail('$stackTrace');
        return ExitCode.software.code;
      } finally {
        if (worktreeCreated && tempDir != null) {
          try {
            await runGitCommand(_logger, currentDir, [
              'worktree',
              'remove',
              '--force',
              tempDir,
            ], dryRun: dryRun);
          } catch (e) {
            _logger.warn('Failed to clean up temporary git worktree: $e');
          }
        } else if (dryRun && tempDir != null) {
          _logger.info('Would clean up the temporary git worktree at $tempDir');
        }
      }
    }

    return runPublication();
  }
}
