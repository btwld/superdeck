import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../utils/process_runner.dart';

/// Wraps `flutter build web` for the deploy flow.
class WebBuilder {
  final Logger _logger;
  final ProcessRunner _run;

  WebBuilder({required Logger logger, ProcessRunner? processRunner})
    : _logger = logger,
      _run = processRunner ?? defaultProcessRunner;

  /// Runs `flutter build web --release` in [appDir].
  ///
  /// Optionally sets [baseHref] and writes to [outputDir]. Returns `true` on
  /// success. When [dryRun] is set, logs the intended actions and returns
  /// `true` without building.
  Future<bool> build({
    required String appDir,
    String? baseHref,
    String? outputDir,
    bool dryRun = false,
  }) async {
    if (dryRun) {
      _logger.info(
        baseHref != null
            ? 'Would build web app with base-href: $baseHref'
            : 'Would build web app with default base-href',
      );
      if (outputDir != null) {
        _logger.info('Would write build output to: $outputDir');
      }

      return true;
    }

    if (!Directory(appDir).existsSync()) {
      _logger.err('App directory not found: $appDir');

      return false;
    }

    final progress = _logger.progress('Building Flutter web app');

    final arguments = ['build', 'web', '--release'];
    if (baseHref != null) arguments.add('--base-href=$baseHref');
    if (outputDir != null) arguments.add('--output=$outputDir');

    try {
      final result = await _run(
        'flutter',
        arguments,
        workingDirectory: appDir,
      );

      if (result.exitCode == 0) {
        progress.complete('Web build completed successfully');

        return true;
      }

      progress.fail('Web build failed');
      _logger.err(result.stderr.toString());

      return false;
    } on ProcessException catch (e) {
      progress.fail('Web build failed');
      _logger.err(
        'Could not run "flutter". Make sure the Flutter SDK is on your PATH. '
        '($e)',
      );

      return false;
    }
  }
}
