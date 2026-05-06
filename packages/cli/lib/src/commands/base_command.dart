import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

abstract class SuperDeckCommand extends Command<int> {
  final Logger logger;

  SuperDeckCommand({Logger? loggerOverride})
    : logger = loggerOverride ?? Logger();
}
