import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  test('builds deck configuration directly from runtime config and source', () {
    final runtime = SuperDeckRuntime.forTesting(
      config: const DeckConfig.local(
        slidesPath: 'slides-dev.md',
        projectDir: 'demo_project',
        outputDir: '.custom-superdeck',
        assetsPath: 'generated-assets',
      ),
    );

    expect(
      runtime.workspace,
      equals(
        DeckWorkspace(
          projectDir: 'demo_project',
          slidesPath: 'slides-dev.md',
          outputDir: '.custom-superdeck',
          assetsPath: 'generated-assets',
        ),
      ),
    );
  });
}
