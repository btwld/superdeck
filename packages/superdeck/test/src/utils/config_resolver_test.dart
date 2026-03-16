import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/utils/config_resolver.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('resolveConfiguration (io)', () {
    late Directory originalCurrentDir;
    late Directory tempDir;

    setUp(() {
      originalCurrentDir = Directory.current;
      tempDir = Directory.systemTemp.createTempSync('config_resolver_test_');
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = originalCurrentDir;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns override when provided', () {
      DeckConfiguration.defaultFile.writeAsStringSync('slidesPath: ignored.md');
      final override = DeckConfiguration(slidesPath: 'override.md');

      final resolved = resolveConfiguration(override);

      expect(resolved, same(override));
    });

    test('parses a valid superdeck.yaml file', () {
      DeckConfiguration.defaultFile.writeAsStringSync('slidesPath: custom.md');

      final resolved = resolveConfiguration(null);

      expect(resolved.slidesPath, 'custom.md');
      expect(resolved.assetsPath, isNull);
      expect(resolved.outputDir, isNull);
      expect(resolved.projectDir, isNull);
    });

    test('falls back to default when superdeck.yaml is missing', () {
      final resolved = resolveConfiguration(null);

      expect(resolved, DeckConfiguration());
    });

    test('falls back to default when superdeck.yaml is empty', () {
      DeckConfiguration.defaultFile.writeAsStringSync('');

      final resolved = resolveConfiguration(null);

      expect(resolved, DeckConfiguration());
    });

    test('falls back to default when superdeck.yaml has only comments', () {
      DeckConfiguration.defaultFile.writeAsStringSync('# comment');

      final resolved = resolveConfiguration(null);

      expect(resolved, DeckConfiguration());
    });

    test('falls back to default when superdeck.yaml is malformed', () {
      DeckConfiguration.defaultFile.writeAsStringSync(': : [invalid');

      final resolved = resolveConfiguration(null);

      expect(resolved, DeckConfiguration());
    });

    test(
      'falls back to default when superdeck.yaml fails schema validation',
      () {
        DeckConfiguration.defaultFile.writeAsStringSync('slidesPath: 42');

        final resolved = resolveConfiguration(null);

        expect(resolved, DeckConfiguration());
      },
    );

    test('parses partial fields from superdeck.yaml', () {
      DeckConfiguration.defaultFile.writeAsStringSync('assetsPath: imgs');

      final resolved = resolveConfiguration(null);

      expect(resolved.assetsPath, 'imgs');
      expect(resolved.slidesPath, isNull);
      expect(resolved.outputDir, isNull);
      expect(resolved.projectDir, isNull);
    });
  });
}
