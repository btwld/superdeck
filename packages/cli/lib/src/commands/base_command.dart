import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

const unsupportedWorkspaceConfigFileName = 'superdeck.yaml';
const unsupportedWorkspaceConfigMessage =
    'Path customization via `superdeck.yaml` is not supported.\n'
    'SuperDeck uses the default workspace layout: `slides.md` in the project '
    'root and `.superdeck/` for generated output.\n'
    'Remove `superdeck.yaml`, move your files to the default paths, then use '
    '`dart run superdeck_cli:main build --watch` in one terminal and '
    '`flutter run` in another.';

/// Base class for SuperDeck commands with common functionality
abstract class SuperDeckCommand extends Command<int> {
  final Logger logger;

  SuperDeckCommand({Logger? loggerOverride})
    : logger = loggerOverride ?? Logger();

  bool ensureNoUnsupportedWorkspaceConfig() {
    final configFile = File(unsupportedWorkspaceConfigFileName);
    if (!configFile.existsSync()) {
      return true;
    }

    logger.err('Unsupported configuration file: ${configFile.path}');
    logger.info(unsupportedWorkspaceConfigMessage);

    return false;
  }
}
