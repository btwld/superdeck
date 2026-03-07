import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/runtime/deck_config.dart';

void main() {
  group('DeckConfig mapping', () {
    test('serializes and deserializes local config with discriminator', () {
      const config = DeckConfig.local(
        slidesPath: 'slides/custom.md',
        watch: true,
        projectDir: 'demo',
        outputDir: '.superdeck-dev',
        assetsPath: 'generated-assets',
      );

      final encoded = config.toMap();
      final decoded = DeckConfig.fromMap(encoded);

      expect(encoded['type'], 'local');
      expect(decoded, isA<LocalDeckConfig>());
      expect(decoded, config);
    });

    test('serializes and deserializes bundled config with discriminator', () {
      const config = DeckConfig.bundle(
        deckAssetPath: '.superdeck/superdeck.v2.json',
        outputDir: '.superdeck',
      );

      final encoded = config.toMap();
      final decoded = DeckConfig.fromMap(encoded);

      expect(encoded['type'], 'bundle');
      expect(decoded, isA<BundledDeckConfig>());
      expect(decoded, config);
    });
  });
}
