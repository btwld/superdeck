import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../utils/constants.dart';
import '../utils/logger.dart' as global;

/// Prints the current version of the SuperDeck CLI.
class VersionCommand extends Command<int> {
  final Logger _logger;

  VersionCommand({Logger? loggerOverride})
    : _logger = loggerOverride ?? global.logger;

  @override
  String get name => 'version';

  @override
  String get description => 'Print the current version of SuperDeck CLI';

  @override
  int run() {
    _logger.info('SuperDeck CLI version: $packageVersion');
    return ExitCode.success.code;
  }
}
