import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  test('SuperDeckProvider exposes config and builder', () {
    final provider = SuperDeckProvider(
      config: const DeckConfig.bundle(
        projectDir: 'demo_project',
        outputDir: '.custom-superdeck',
        assetsPath: 'generated-assets',
      ),
      builder: (context, deck) => const SizedBox(),
    );

    expect(provider.config, isA<DeckConfig>());
    expect(provider.builder, isNotNull);
  });

  test('SuperDeckProvider accepts local config', () {
    final provider = SuperDeckProvider(
      config: const DeckConfig.local(
        projectDir: 'demo_project',
        outputDir: '.custom-superdeck',
        assetsPath: 'generated-assets',
        slidesPath: 'slides.md',
        watch: false,
      ),
      builder: (context, deck) => const SizedBox(),
    );

    expect(provider.config, isA<LocalDeckConfig>());
  });
}
