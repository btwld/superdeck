import 'dart:io';

import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

Directory createTempDir({String prefix = 'superdeck_builder_'}) {
  final tempDir = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
  return tempDir;
}

DeckWorkspace createTestWorkspace(
  Directory tempDir, {
  String? slidesPath,
  String? outputDir,
  String? assetsPath,
}) {
  return DeckWorkspace(
    projectDir: tempDir.path,
    slidesPath: slidesPath,
    outputDir: outputDir,
    assetsPath: assetsPath,
  );
}
