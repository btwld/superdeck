import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'commands/build_command.dart';
import 'helpers/exceptions.dart';
import 'helpers/logger.dart';

class SuperDeckRunner extends CommandRunner<int> {
  SuperDeckRunner() : super('superdeck', 'Superdeck CLI');

  @override
  Future<int> run(Iterable<String> args) async {
    addCommand(BuildCommand());

    try {
      final exitCode = await super.run(args);

      return exitCode ?? ExitCode.software.code;
    } on AckException catch (e) {
      final errors = composeSchemaErrorMap(e.error);

      final yamlWriter = YamlWriter();
      final yamlString = yamlWriter.write(errors);

      logger.info(yamlString);

      return ExitCode.software.code;
    } on Exception catch (e) {
      printException(e);

      return ExitCode.software.code;
    }
  }
}
