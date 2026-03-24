import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

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
