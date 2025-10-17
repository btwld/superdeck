import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Creates a temporary directory that will be automatically cleaned up
/// when the test completes.
Directory createTempDir() {
  final tempDir = Directory.systemTemp.createTempSync('superdeck_test_');
  addTearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
  return tempDir;
}

/// Creates a temporary file with the given content and returns the file.
/// The file will be automatically cleaned up when the test completes.
File createTempFile(String content, {String? extension}) {
  final dir = createTempDir();
  final file = File(p.join(dir.path, 'test${extension ?? ''}'));
  file.writeAsStringSync(content);
  return file;
}

/// Creates a temporary directory with async cleanup.
/// Use this for tests that need async setup/tearDown.
Future<Directory> createTempDirAsync() async {
  final tempDir = await Directory.systemTemp.createTemp('superdeck_test_');
  addTearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });
  return tempDir;
}

/// Mock configuration for testing repositories and file operations
/// Uses composition instead of inheritance since DeckConfiguration is final
class MockDeckConfiguration {
  final Directory _tempDir;

  MockDeckConfiguration(this._tempDir);

  String? get projectDir => _tempDir.path;
  String? get slidesPath => null;
  String? get outputDir => null;
  String? get assetsPath => null;
  Directory get superdeckDir => Directory(p.join(_tempDir.path, '.superdeck'));
  File get deckJson =>
      File(p.join(_tempDir.path, '.superdeck', 'superdeck.json'));
  Directory get assetsDir =>
      Directory(p.join(_tempDir.path, '.superdeck', 'assets'));
  File get assetsRefJson =>
      File(p.join(_tempDir.path, '.superdeck', 'generated_assets.json'));
  File get slidesFile => File(p.join(_tempDir.path, 'slides.md'));
  File get pubspecFile => File(p.join(_tempDir.path, 'pubspec.yaml'));
}

/// Creates a mock deck configuration with temporary directory
MockDeckConfiguration createMockConfig() {
  return MockDeckConfiguration(createTempDir());
}

/// Verifies that a UUID conforms to the v4 format.
Matcher isValidUuidV4() {
  return matches(
    RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    ),
  );
}
