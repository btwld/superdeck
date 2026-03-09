import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  testWidgets('SuperDeckProvider computes workspace from bundled config', (
    tester,
  ) async {
    DeckDataState? capturedState;

    await tester.pumpWidget(
      SuperDeckProvider(
        config: const DeckConfig.bundle(
          projectDir: 'demo_project',
          outputDir: '.custom-superdeck',
          assetsPath: 'generated-assets',
        ),
        child: Builder(
          builder: (context) {
            capturedState = SuperDeckProvider.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(capturedState, isNotNull);
    expect(
      capturedState!.workspace,
      equals(
        DeckWorkspace(
          projectDir: 'demo_project',
          outputDir: '.custom-superdeck',
          assetsPath: 'generated-assets',
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox());
  });

  // Uses real async to avoid fake-timer assertions from
  // DeckService.loadDeckStream's internal timeout.
  testWidgets(
    'SuperDeckProvider computes workspace from local config',
    variant: const TargetPlatformVariant({TargetPlatform.macOS}),
    (tester) async {
      DeckDataState? capturedState;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          SuperDeckProvider(
            config: const DeckConfig.local(
              slidesPath: 'slides-dev.md',
              projectDir: 'demo_project',
              outputDir: '.custom-superdeck',
              assetsPath: 'generated-assets',
            ),
            child: Builder(
              builder: (context) {
                capturedState = SuperDeckProvider.of(context);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      expect(capturedState, isNotNull);
      expect(
        capturedState!.workspace,
        equals(
          DeckWorkspace(
            projectDir: 'demo_project',
            slidesPath: 'slides-dev.md',
            outputDir: '.custom-superdeck',
            assetsPath: 'generated-assets',
          ),
        ),
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
      });
    },
  );
}
