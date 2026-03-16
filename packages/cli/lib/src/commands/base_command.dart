import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// Base class for SuperDeck commands with common functionality
abstract class SuperDeckCommand extends Command<int> {
  final Logger logger;

  SuperDeckCommand({Logger? loggerOverride})
    : logger = loggerOverride ?? Logger();
}
