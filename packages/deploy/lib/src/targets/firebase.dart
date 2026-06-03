import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../utils/process_runner.dart';

/// Configuration for a Firebase Hosting deploy.
class FirebaseOptions {
  /// The directory containing `firebase.json` (the hosting root).
  final String appDir;

  /// Optional Firebase project id (`--project`).
  final String? project;

  /// Optional preview channel id; when set, deploys to a channel instead of
  /// live (`hosting:channel:deploy <channel>`).
  final String? channel;

  /// Whether to plan the deploy without running Firebase.
  final bool dryRun;

  const FirebaseOptions({
    this.appDir = '.',
    this.project,
    this.channel,
    this.dryRun = false,
  });
}

/// Deploys a built web app to Firebase Hosting via the `firebase` CLI.
///
/// The web build (`superdeck build` + `flutter build web`) and a valid
/// `firebase.json` are expected to already exist in [FirebaseOptions.appDir];
/// this target only drives the upload.
class FirebaseTarget {
  final Logger _logger;
  final ProcessRunner _run;

  FirebaseTarget({required Logger logger, ProcessRunner? processRunner})
    : _logger = logger,
      _run = processRunner ?? defaultProcessRunner;

  /// Runs the deploy. Returns an exit code (0 == success).
  Future<int> deploy(FirebaseOptions options) async {
    final appDir = p.normalize(
      p.join(Directory.current.path, options.appDir),
    );

    if (!Directory(appDir).existsSync()) {
      _logger.err('App directory not found: $appDir');

      return ExitCode.usage.code;
    }

    if (!options.dryRun && !File(p.join(appDir, 'firebase.json')).existsSync()) {
      _logger.err('firebase.json not found in $appDir');
      _logger.info('Run "firebase init hosting" to configure the project.');

      return ExitCode.usage.code;
    }

    final arguments = <String>[];
    if (options.channel != null) {
      arguments.addAll(['hosting:channel:deploy', options.channel!]);
    } else {
      arguments.addAll(['deploy', '--only', 'hosting']);
    }
    if (options.project != null) {
      arguments.addAll(['--project', options.project!]);
    }

    if (options.dryRun) {
      _logger.info('Would run: firebase ${arguments.join(' ')} (in $appDir)');

      return ExitCode.success.code;
    }

    final progress = _logger.progress('Deploying to Firebase Hosting');
    try {
      final result = await _run(
        'firebase',
        arguments,
        workingDirectory: appDir,
      );

      if (result.exitCode == 0) {
        progress.complete('Firebase deploy completed');
        _logger.info(result.stdout.toString());

        return ExitCode.success.code;
      }

      progress.fail('Firebase deploy failed');
      _logger.err(result.stderr.toString());

      return ExitCode.software.code;
    } on ProcessException catch (e) {
      progress.fail('Firebase deploy failed');
      _logger.err(
        'Could not run "firebase". Install the Firebase CLI and ensure it is '
        'on your PATH. ($e)',
      );

      return ExitCode.software.code;
    }
  }
}
