import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'src/commands/build_command.dart';
import 'src/commands/publish_command.dart';
import 'src/commands/setup_command.dart';
import 'src/commands/version_command.dart';
import 'src/utils/constants.dart';
import 'src/utils/logger.dart';

/// SuperDeck command runner
///
/// This is the main entrypoint for the CLI, handling command dispatch and
/// global option parsing.
class SuperDeckRunner extends CommandRunner<int> {
  late final Logger _logger;

  /// Creates a new [SuperDeckRunner] instance
  SuperDeckRunner({
    Logger? loggerOverride,
    BuildCommand? buildCommand,
    SetupCommand? setupCommand,
  }) : super(cliName, cliDescription) {
    _logger = loggerOverride ?? logger;

    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose logging',
        negatable: false,
      )
      ..addFlag('version', help: 'Print the current version', negatable: false)
      ..addFlag(
        'quiet',
        abbr: 'q',
        help: 'Disable all output except errors',
        negatable: false,
      );

    addCommand(buildCommand ?? BuildCommand(loggerOverride: _logger));
    addCommand(setupCommand ?? SetupCommand(loggerOverride: _logger));
    addCommand(PublishCommand(loggerOverride: _logger));
    addCommand(VersionCommand(loggerOverride: loggerOverride));
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);

      if (argResults['version'] == true) {
        _logger.info('SuperDeck CLI version: $packageVersion');

        return ExitCode.success.code;
      }

      if (argResults['verbose'] == true) {
        _logger.level = Level.verbose;
        _logger.detail('Verbose logging enabled');
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
    } on AckException catch (e) {
      _logger.err('Schema validation error:');
      _logger.err(e.toString());

      return ExitCode.data.code;
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
    } on FormatException catch (e) {
      _logger.err('Format error: ${e.message}');

      return ExitCode.data.code;
    } on Exception catch (e, stackTrace) {
      _logger
        ..err('Error: ${e.toString()}')
        ..detail('$stackTrace');

      return ExitCode.software.code;
    }
  }
}
