#!/usr/bin/env dart

import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_cli/runner.dart';
import 'package:superdeck_cli/src/utils/constants.dart';

/// Main entry point for the SuperDeck CLI when run as a global command
Future<void> main(List<String> args) async {
  // Show a welcome message for direct invocations (no args)
  if (args.isEmpty) {
    final logger = Logger();
    logger.info('SuperDeck CLI version $packageVersion');
    logger.info('');
    logger.info('Available commands:');
    logger.info('  build    - Build SuperDeck presentations from markdown');
    logger.info('  publish  - Publish Superdeck app to GitHub Pages');
    logger.info('  setup    - Set up SuperDeck in your Flutter project');
    logger.info('  version  - Print the current version of SuperDeck CLI');
    logger.info('');
    logger.info('Run "superdeck --help" for usage information.');
    await _flushThenExit(ExitCode.success.code);
  } else {
    await _flushThenExit(await SuperDeckRunner().run(args));
  }
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from proceeding
/// after you've decided to exit.
Future<void> _flushThenExit(int status) async {
  await stdout.flush();
  await stderr.flush();
  exit(status);
}
