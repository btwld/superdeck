import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../../utils/templates.dart';

/// Resolves the Flutter binary, preferring an FVM-managed SDK when available.
String resolveFlutterBinary(String workingDirectory, {bool? isWindows}) {
  final binaryName = (isWindows ?? Platform.isWindows)
      ? 'flutter.bat'
      : 'flutter';
  var dir = Directory(path.absolute(workingDirectory));

  while (true) {
    final candidate = File(
      path.join(dir.path, '.fvm', 'flutter_sdk', 'bin', binaryName),
    );
    if (candidate.existsSync()) return candidate.path;

    final parent = dir.parent;
    if (parent.path == dir.path) return 'flutter';
    dir = parent;
  }
}

/// Sets up a custom index.html with a loading indicator before build.
Future<String?> setupCustomIndexHtml(
  Logger logger, {
  required String repoDir,
  required String exampleDir,
  required bool isDryRun,
  Future<void> Function(File file, String content)? writeFile,
}) async {
  final progress = logger.progress('Setting up custom index.html');
  String? backupPath;
  final writeIndexHtml =
      writeFile ??
      (File file, String content) => file.writeAsString(content);
  try {
    if (!isDryRun) {
      final webDir = path.join(repoDir, exampleDir, 'web');
      final indexHtmlPath = path.join(webDir, 'index.html');
      final indexHtmlFile = File(indexHtmlPath);

      if (indexHtmlFile.existsSync()) {
        backupPath = path.join(webDir, 'index.html.bak');
        await indexHtmlFile.copy(backupPath);
        logger.detail('Created backup of original index.html');
      }

      await writeIndexHtml(indexHtmlFile, customIndexHtml);
      logger.info('Created custom index.html with loading indicator');
    } else {
      logger.info('Would replace index.html with custom template');
    }

    progress.complete('Custom index.html setup complete');
    return backupPath;
  } catch (e) {
    progress.fail('Failed to set up custom index.html');
    logger.err('Error setting up custom index.html: $e');
    await restoreIndexHtmlBackup(logger, backupPath);
    rethrow;
  }
}

/// Applies the custom build-time index.html template and always restores
/// the original backup after [action] completes.
Future<T> withTemporaryCustomIndexHtml<T>(
  Logger logger, {
  required String repoDir,
  required String exampleDir,
  required bool isDryRun,
  required Future<T> Function() action,
  Future<void> Function(File file, String content)? writeFile,
}) async {
  final backupPath = await setupCustomIndexHtml(
    logger,
    repoDir: repoDir,
    exampleDir: exampleDir,
    isDryRun: isDryRun,
    writeFile: writeFile,
  );

  try {
    return await action();
  } finally {
    await restoreIndexHtmlBackup(logger, backupPath);
  }
}

/// Restores the original index.html from backup if it exists.
Future<void> restoreIndexHtmlBackup(Logger logger, String? backupPath) async {
  if (backupPath == null) return;

  final backupFile = File(backupPath);
  if (!backupFile.existsSync()) return;

  final indexHtmlPath = backupPath.replaceAll('.bak', '');
  try {
    await backupFile.copy(indexHtmlPath);
    await backupFile.delete();
    logger.detail('Restored original index.html from backup');
  } catch (e) {
    logger.warn('Failed to restore index.html backup: $e');
  }
}

/// Builds the web app with appropriate base href.
Future<bool> buildWebApp(
  Logger logger,
  String workingDirectory, {
  required String exampleDir,
  String? baseHref,
  String? outputDirectory,
  bool dryRun = false,
}) async {
  if (dryRun) {
    if (baseHref != null) {
      logger.info('Would build web app with base-href: $baseHref');
    } else {
      logger.info('Would build web app with default base-href');
    }

    if (outputDirectory != null) {
      logger.info('Would write build output to: $outputDirectory');
    }

    return true;
  }

  final progress = logger.progress('Building Flutter web app');

  try {
    final resolvedExampleDir = path.join(workingDirectory, exampleDir);
    if (!Directory(resolvedExampleDir).existsSync()) {
      progress.fail('Example directory not found: $resolvedExampleDir');
      logger.err('Example directory not found: $resolvedExampleDir');
      return false;
    }

    final buildArgs = <String>['build', 'web', '--release'];
    if (baseHref != null) {
      buildArgs.add('--base-href=$baseHref');
    }

    if (outputDirectory != null) {
      buildArgs.add('--output=$outputDirectory');
    }

    final flutterBin = resolveFlutterBinary(resolvedExampleDir);
    logger.detail('Using Flutter binary: $flutterBin');

    final result = await Process.run(
      flutterBin,
      buildArgs,
      workingDirectory: resolvedExampleDir,
    );

    if (result.exitCode == 0) {
      progress.complete('Web build completed successfully');
      return true;
    }

    progress.fail('Web build failed');
    logger.err(result.stderr.toString());
    return false;
  } catch (e) {
    progress.fail('Web build failed');
    logger.err('Error during build: $e');
    return false;
  }
}
