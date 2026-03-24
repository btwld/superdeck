import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import 'create/create_support.dart';
import '../utils/extensions.dart';
import 'base_command.dart';

/// Creates or refreshes a SuperDeck starter application using `flutter create`
/// plus a lightweight SuperDeck overlay.
class CreateCommand extends SuperDeckCommand {
  final bool Function(String message, {bool defaultValue})? confirmOverride;
  final CreateScaffoldBuilder? scaffoldBuilder;
  final String? loaderAssetPath;

  CreateCommand({
    super.loggerOverride,
    this.confirmOverride,
    this.scaffoldBuilder,
    this.loaderAssetPath,
  }) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Refresh starter files without prompting',
      negatable: false,
    );
  }

  bool _confirmAction(String message, {bool defaultValue = false}) {
    final override = confirmOverride;
    if (override != null) {
      return override(message, defaultValue: defaultValue);
    }
    return logger.confirm(message, defaultValue: defaultValue);
  }

  @override
  String get description =>
      'Create a SuperDeck starter app or refresh starter files';

  @override
  String get name => 'create';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.length != 1) {
      throw UsageException(
        'Expected exactly one target directory.\n\n'
        'Example: superdeck create my_talk',
        usage,
      );
    }

    final targetArgument = rest.single;
    final targetPath = path.absolute(targetArgument);
    final targetDir = Directory(targetPath);
    final targetName = path.basename(targetPath);
    final targetType = FileSystemEntity.typeSync(
      targetPath,
      followLinks: false,
    );

    if (targetType != FileSystemEntityType.notFound &&
        targetType != FileSystemEntityType.directory) {
      logger.err('Target exists but is not a directory: $targetPath');
      return ExitCode.ioError.code;
    }

    final isExistingNonEmptyDir = isExistingNonEmptyDirectory(targetDir);
    final shouldOverwrite = boolArg('force');

    if (isExistingNonEmptyDir && !shouldOverwrite) {
      final managedPaths = describeRefreshChanges(targetDir);
      final confirmed = _confirmAction(
        'Target directory is not empty.\n'
        'This will refresh these SuperDeck starter files: $managedPaths\n'
        'It will keep your app code and platform folders untouched: ${describeRefreshPreserved()}\n'
        'Continue?',
        defaultValue: false,
      );

      if (!confirmed) {
        logger.info('Create cancelled. No files were changed.');
        return ExitCode.success.code;
      }
    }

    final bindings = CreateBindings.fromTargetName(targetName);
    final tempRoot = await Directory.systemTemp.createTemp('superdeck_cli_');

    try {
      final scaffoldDir = await buildStarterScaffold(
        tempRoot,
        bindings: bindings,
        workingDirectory: Directory.current.path,
        scaffoldBuilder: scaffoldBuilder,
        loaderAssetPath: loaderAssetPath,
      );
      if (isExistingNonEmptyDir) {
        await refreshManagedOverlay(scaffoldDir, targetDir);
      } else {
        await copyCreateScaffold(scaffoldDir, targetDir);
      }
    } on FormatException catch (error) {
      logger.err(error.message);
      return ExitCode.data.code;
    } on ProcessException catch (error) {
      logger.err('Failed to run Flutter tooling: ${error.message}');
      return ExitCode.software.code;
    } on FileSystemException catch (error) {
      logger.err('Failed to write starter app: ${error.message}');
      if (error.path != null) {
        logger.err('Path: ${error.path}');
      }
      return ExitCode.ioError.code;
    } finally {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    }

    if (isExistingNonEmptyDir) {
      logger.success('Refreshed SuperDeck starter files in ${targetDir.path}');
    } else {
      logger.success('Created SuperDeck app at ${targetDir.path}');
    }
    logger.info('');
    logger.info('Next steps:');
    logger.info('  cd $targetArgument');
    logger.info('  flutter pub get');
    logger.info('  dart run superdeck_cli:main build');
    logger.info('  flutter run');

    return ExitCode.success.code;
  }
}
