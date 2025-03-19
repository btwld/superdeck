import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../helpers/constants.dart';
import '../helpers/logger.dart';

/// Command to display version information
class VersionCommand extends Command<int> {
  @override
  Future<int> run() async {
    logger.info('SuperDeck CLI version: $packageVersion');

    return ExitCode.success.code;
  }

  @override
  String get description => 'Print the current version of SuperDeck CLI';

  @override
  String get name => 'version';
}
