import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../utils/process_runner.dart';

/// Base class for deploy commands, providing a shared [logger] and an
/// injectable [processRunner] for testing.
abstract class DeployCommand extends Command<int> {
  /// Logger used for all command output.
  final Logger logger;

  /// Process runner used by deploy targets; overridable in tests.
  final ProcessRunner? processRunner;

  DeployCommand({Logger? loggerOverride, this.processRunner})
    : logger = loggerOverride ?? Logger();
}
