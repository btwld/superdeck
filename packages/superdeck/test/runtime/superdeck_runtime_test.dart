import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  test('builds deck configuration directly from runtime config and source', () {
    final runtime = SuperDeckRuntime.forTesting(
      source: const DeckSource.local(slidesPath: 'slides-dev.md'),
      runtimeConfig: const DeckRuntimeConfig(
        projectDir: 'demo_project',
        outputDir: '.custom-superdeck',
        assetsPath: 'generated-assets',
      ),
    );

    expect(
      runtime.configuration,
      equals(
        DeckConfiguration(
          projectDir: 'demo_project',
          slidesPath: 'slides-dev.md',
          outputDir: '.custom-superdeck',
          assetsPath: 'generated-assets',
        ),
      ),
    );
  });
}
