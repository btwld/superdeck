import 'dart:io';

import 'package:args/command_runner.dart';

import 'setup/setup_support.dart';
import 'base_command.dart';

const _successCode = 0;
const _dataErrorCode = 65;
const _ioErrorCode = 74;

class SetupCommand extends SuperDeckCommand {
  final String? _projectDir;

  SetupCommand({super.loggerOverride, String? projectDir})
    : _projectDir = projectDir;

  @override
  String get description => 'Configure the current Flutter app for SuperDeck';

  @override
  String get name => 'setup';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isNotEmpty) {
      throw UsageException(
        '`superdeck setup` does not take arguments.\n\n'
        'Run it from a Flutter app root:\n'
        '  cd my_app\n'
        '  superdeck setup',
        usage,
      );
    }

    final projectDir = Directory(_projectDir ?? Directory.current.path);
    if (!isWorkspaceConfigValid(projectDir: projectDir.path)) {
      return _dataErrorCode;
    }

    try {
      await applySetup(projectDir, logger);
    } on FormatException catch (error) {
      logger.err(error.message);
      return _dataErrorCode;
    } on FileSystemException catch (error) {
      logger.err(error.message);
      if (error.path != null) {
        logger.err('Path: ${error.path}');
      }
      return _ioErrorCode;
    }

    logger.success('Configured SuperDeck in ${projectDir.path}');
    logger.info('');
    logger.info('Next steps:');
    logger.info('  flutter pub get');
    logger.info('  add slides.md in the project root');
    logger.info('  update lib/main.dart to run SuperDeckApp');
    logger.info('  dart run superdeck_cli:main build');
    logger.info('  flutter run');

    return _successCode;
  }
}
