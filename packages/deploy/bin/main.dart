#!/usr/bin/env dart

import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_deploy/src/runner.dart';
import 'package:superdeck_deploy/src/utils/constants.dart';

/// Entry point for the `superdeck-deploy` executable.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    final logger = Logger();
    logger.info('$deployToolName version $deployToolVersion');
    logger.info('');
    logger.info('Available commands:');
    logger.info('  github-pages  - Publish a web app to GitHub Pages');
    logger.info('  firebase      - Deploy a web app to Firebase Hosting');
    logger.info('');
    logger.info('Run "$deployToolName --help" for usage information.');
    await _flushThenExit(ExitCode.success.code);
  } else {
    await _flushThenExit(await DeployRunner().run(args));
  }
}

Future<void> _flushThenExit(int status) async {
  await stdout.flush();
  await stderr.flush();
  exit(status);
}
