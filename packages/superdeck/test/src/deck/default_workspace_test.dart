import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck/src/deck/default_workspace.dart';

void main() {
  group('findProjectRoot', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'superdeck_default_workspace_test_',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns nearest ancestor containing pubspec.yaml', () async {
      final projectDir = Directory(p.join(tempDir.path, 'project'));
      final nestedDir = Directory(p.join(projectDir.path, 'lib', 'src'));
      await nestedDir.create(recursive: true);
      await File(
        p.join(projectDir.path, 'pubspec.yaml'),
      ).writeAsString('name: project\n');

      final root = findProjectRoot(nestedDir);

      expect(root?.path, projectDir.absolute.path);
    });

    test('returns null when no ancestor contains pubspec.yaml', () async {
      final nestedDir = Directory(p.join(tempDir.path, 'project', 'lib'));
      await nestedDir.create(recursive: true);

      final root = findProjectRoot(nestedDir);

      expect(root, isNull);
    });
  });
}
