import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck/superdeck.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'commands/build_command.dart';
import 'commands/setup_command.dart';
import 'commands/version_command.dart';
import 'helpers/constants.dart';
import 'helpers/logger.dart';

/// SuperDeck command runner
///
/// This is the main entrypoint for the CLI, handling command dispatch and
/// global option parsing.
class SuperDeckRunner extends CommandRunner<int> {
  late final Logger _logger;

  /// Creates a new [SuperDeckRunner] instance
  SuperDeckRunner({Logger? loggerOverride}) : super(cliName, cliDescription) {
    // Use provided logger or global instance
    _logger = loggerOverride ?? logger;

    // Add global flags
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose logging',
        negatable: false,
      )
      ..addFlag(
        'version',
        help: 'Print the current version',
        negatable: false,
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        help: 'Disable all output except errors',
        negatable: false,
      );

    // Add commands
    addCommand(BuildCommand());
    addCommand(SetupCommand());
    addCommand(VersionCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      // Parse global arguments to handle --version and logging flags
      // before command execution
      final argResults = parse(args);

      // Handle --version flag at top level
      if (argResults['version'] == true) {
        _logger.info('SuperDeck CLI version: $packageVersion');

        return ExitCode.success.code;
      }

      // Configure logger verbosity
      if (argResults['verbose'] == true) {
        _logger.level = Level.verbose;
        _logger.detail('Verbose logging enabled');
      }

      // Disable output for quiet mode
      if (argResults['quiet'] == true) {
        _logger.level = Level.error;
      }

      // Run the command
      final exitCode = await runCommand(argResults);

      return exitCode ?? ExitCode.success.code;
    } on UsageException catch (e) {
      // Handle usage errors (invalid commands, missing required args, etc.)
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);

      return ExitCode.usage.code;
    } on AckException catch (e) {
      // Handle schema validation errors with proper formatting
      _logger.err('Schema validation error:');

      final errors = composeSchemaErrorMap(e.error);
      final yamlWriter = YamlWriter();
      final yamlString = yamlWriter.write(errors);

      _logger.info(yamlString);

      return ExitCode.data.code;
    } on ProcessException catch (e) {
      // Handle errors from external processes
      _logger
        ..err('Process error: ${e.executable} ${e.arguments}')
        ..err(e.message);

      return ExitCode.software.code;
    } on FileSystemException catch (e) {
      // Handle file system errors
      _logger
        ..err('File system error: ${e.message}')
        ..err('Path: ${e.path}');

      return ExitCode.ioError.code;
    } on FormatException catch (e) {
      // Handle format errors (YAML parsing, etc.)
      _logger.err('Format error: ${e.message}');

      return ExitCode.data.code;
    } on Exception catch (e, stackTrace) {
      // Handle general exceptions
      _logger
        ..err('Error: ${e.toString()}')
        ..detail('$stackTrace');

      return ExitCode.software.code;
    }
  }
}
