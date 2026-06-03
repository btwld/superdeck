import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/firebase_command.dart';
import 'commands/github_pages_command.dart';
import 'utils/constants.dart';
import 'utils/process_runner.dart';

/// Command runner for the `superdeck-deploy` executable.
class DeployRunner extends CommandRunner<int> {
  final Logger _logger;

  DeployRunner({
    Logger? loggerOverride,
    ProcessRunner? processRunner,
    Command<int>? githubPagesCommand,
    Command<int>? firebaseCommand,
  }) : _logger = loggerOverride ?? Logger(),
       super(deployToolName, deployToolDescription) {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose logging.',
        negatable: false,
      )
      ..addFlag(
        'version',
        help: 'Print the current version.',
        negatable: false,
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        help: 'Disable all output except errors.',
        negatable: false,
      );

    addCommand(
      githubPagesCommand ??
          GitHubPagesCommand(
            loggerOverride: _logger,
            processRunner: processRunner,
          ),
    );
    addCommand(
      firebaseCommand ??
          FirebaseCommand(
            loggerOverride: _logger,
            processRunner: processRunner,
          ),
    );
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);

      if (argResults['version'] == true) {
        _logger.info('$deployToolName version: $deployToolVersion');

        return ExitCode.success.code;
      }

      if (argResults['verbose'] == true) {
        _logger.level = Level.verbose;
      }

      if (argResults['quiet'] == true) {
        _logger.level = Level.error;
      }

      final exitCode = await runCommand(argResults);

      return exitCode ?? ExitCode.success.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);

      return ExitCode.usage.code;
    } on ProcessException catch (e) {
      _logger
        ..err('Process error: ${e.executable} ${e.arguments}')
        ..err(e.message);

      return ExitCode.software.code;
    } on FileSystemException catch (e) {
      _logger
        ..err('File system error: ${e.message}')
        ..err('Path: ${e.path ?? 'Unknown'}');

      return ExitCode.ioError.code;
    } on Exception catch (e, stackTrace) {
      _logger
        ..err('Error: $e')
        ..detail('$stackTrace');

      return ExitCode.software.code;
    }
  }
}
