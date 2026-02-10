import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/runtime_configuration.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('resolveDeckConfiguration', () {
    late Directory tempDir;
    late Directory originalCwd;

    setUp(() async {
      originalCwd = Directory.current;
      tempDir = await Directory.systemTemp.createTemp('runtime_config_test_');
      Directory.current = tempDir;
    });

    tearDown(() async {
      Directory.current = originalCwd;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns provided configuration override', () {
      final config = DeckConfiguration(
        projectDir: '/tmp/superdeck-project',
        slidesPath: 'content/slides.md',
        outputDir: '.custom-superdeck',
        assetsPath: 'custom-assets',
      );

      final resolved = resolveDeckConfiguration(config);
      expect(resolved, same(config));
    });

    test('returns defaults when superdeck.yaml does not exist', () {
      final resolved = resolveDeckConfiguration(null);
      expect(resolved, equals(DeckConfiguration()));
    });

    test('loads and parses superdeck.yaml when available', () async {
      final configFile = File('${tempDir.path}/superdeck.yaml');
      await configFile.writeAsString('''
slidesPath: content/slides.md
outputDir: .generated-superdeck
assetsPath: generated-assets
''');

      final resolved = resolveDeckConfiguration(null);

      expect(
        resolved,
        equals(
          DeckConfiguration(
            slidesPath: 'content/slides.md',
            outputDir: '.generated-superdeck',
            assetsPath: 'generated-assets',
          ),
        ),
      );
    });

    test('falls back to defaults when superdeck.yaml is invalid', () async {
      final configFile = File('${tempDir.path}/superdeck.yaml');
      await configFile.writeAsString('slidesPath: [');

      final resolved = resolveDeckConfiguration(null);
      expect(resolved, equals(DeckConfiguration()));
    });
  });
}
