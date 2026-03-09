import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_genui/src/presentation/view/presentation_deck_host.dart';

void main() {
  test('uses provided config and app builder', () {
    final host = PresentationDeckHost(
      config: const DeckConfig.bundle(
        projectDir: 'demo_project',
        outputDir: '.custom-superdeck',
        assetsPath: 'generated-assets',
      ),
      appBuilder: (theme, deck) => const SizedBox(),
    );

    expect(host.config, isA<DeckConfig>());
    expect(host.appBuilder, isNotNull);
  });

  test('has a valid default config', () {
    const host = PresentationDeckHost();
    expect(host.config, isA<DeckConfig>());
  });
}
