import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'update_pubspec.dart';

/// Ensures the pubspec.yaml has the necessary assets configuration.
Future<void> ensurePubspecAssets(DeckWorkspace workspace, Logger logger) async {
  final progress = logger.progress('Checking pubspec.yaml assets...');

  final pubspecFile = workspace.pubspecFile;

  if (!await pubspecFile.exists()) {
    progress.fail('pubspec.yaml not found');

    return;
  }

  final pubspecContents = await pubspecFile.readAsString();
  final updatedPubspecContents = updatePubspecAssets(
    workspace,
    pubspecContents,
  );

  if (updatedPubspecContents != pubspecContents) {
    await pubspecFile.writeAsString(updatedPubspecContents);
    progress.complete('Pubspec assets updated');
  } else {
    progress.complete('Pubspec assets already configured');
  }
}
