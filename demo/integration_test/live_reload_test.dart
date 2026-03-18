import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck/superdeck.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Live Reload', () {
    late Directory tempDir;
    late DeckWorkspace workspace;
    late FileDeckLoader loader;
    var loaderCreated = false;

    setUpAll(() async {
      await TestApp.initialize();
    });

    setUp(() async {
      loaderCreated = false;
      tempDir = await Directory.systemTemp.createTemp('sd_reload_test_');
      workspace = DeckWorkspace(projectDir: tempDir.path);
    });

    tearDown(() async {
      if (loaderCreated) await loader.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('rebuilding overlay appears during build', (tester) async {
      final initialSlides = [makeSlide('s1', '# Initial')];
      await simulateBuildSuccess(workspace, initialSlides, 1);
      loader = FileDeckLoader(workspace: workspace);
      loaderCreated = true;

      final controller = await tester.pumpTestAppWithLoader(loader);
      expect(controller.totalSlides.value, 1);

      await simulateBuilding(workspace, 2);
      await tester.pumpUntil(
        () => controller.isBuildActive.value,
        debugLabel: 'isBuildActive to become true',
        onTimeout: () => describeDeckControllerState(controller),
      );

      expect(find.textContaining('Rebuilding'), findsOneWidget);

      // Verify overlay disappears after successful rebuild
      await simulateBuildSuccess(workspace, initialSlides, 3);
      await tester.pumpUntil(
        () => !controller.isBuildActive.value,
        debugLabel: 'isBuildActive to clear after success',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(find.textContaining('Rebuilding'), findsNothing);
      assertOnlyLayoutOverflowOrNoException(tester);
    });

    testWidgets('build failure shows error banner after successful load', (
      tester,
    ) async {
      final initialSlides = [makeSlide('s1', '# Working')];
      await simulateBuildSuccess(workspace, initialSlides, 1);
      loader = FileDeckLoader(workspace: workspace);
      loaderCreated = true;

      final controller = await tester.pumpTestAppWithLoader(loader);
      expect(controller.totalSlides.value, 1);
      expect(controller.hasError.value, isFalse);

      await simulateBuildFailure(workspace, 'Syntax error on line 5', 2);
      await tester.pumpUntil(
        () => controller.buildFailure.value != null,
        debugLabel: 'buildFailure to be set',
        onTimeout: () => describeDeckControllerState(controller),
      );

      expect(find.textContaining('Build failed'), findsOneWidget);
      expect(find.textContaining('Syntax error on line 5'), findsOneWidget);
      // Slides should still be visible (non-fatal error path)
      expect(controller.totalSlides.value, 1);
      assertOnlyLayoutOverflowOrNoException(tester);
    });

    testWidgets('build failure clears after successful rebuild', (
      tester,
    ) async {
      final initialSlides = [makeSlide('s1', '# Working')];
      await simulateBuildSuccess(workspace, initialSlides, 1);
      loader = FileDeckLoader(workspace: workspace);
      loaderCreated = true;

      final controller = await tester.pumpTestAppWithLoader(loader);

      // Trigger failure
      await simulateBuildFailure(workspace, 'Parse error', 2);
      await tester.pumpUntil(
        () => controller.buildFailure.value != null,
        debugLabel: 'buildFailure to appear',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(find.textContaining('Build failed'), findsOneWidget);

      // Fix and rebuild
      final updatedSlides = [makeSlide('s1', '# Fixed')];
      await simulateBuildSuccess(workspace, updatedSlides, 3);
      await tester.pumpUntil(
        () => controller.buildFailure.value == null,
        debugLabel: 'buildFailure to clear',
        onTimeout: () => describeDeckControllerState(controller),
      );

      expect(find.textContaining('Build failed'), findsNothing);
      expect(controller.hasError.value, isFalse);
      assertOnlyLayoutOverflowOrNoException(tester);
    });

    testWidgets('slide count updates after rebuild', (tester) async {
      final initialSlides = [makeSlide('s1', '# Slide One')];
      await simulateBuildSuccess(workspace, initialSlides, 1);
      loader = FileDeckLoader(workspace: workspace);
      loaderCreated = true;

      final controller = await tester.pumpTestAppWithLoader(loader);
      expect(controller.totalSlides.value, 1);

      // Open menu to see the counter
      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.isMenuOpen.value,
        debugLabel: 'menu open',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(find.textContaining('1 of 1'), findsOneWidget);

      // Rebuild with 2 slides
      final updatedSlides = [
        makeSlide('s1', '# Slide One'),
        makeSlide('s2', '# Slide Two'),
      ];
      await simulateBuildSuccess(workspace, updatedSlides, 2);
      await tester.pumpUntil(
        () => controller.totalSlides.value == 2,
        debugLabel: 'totalSlides to become 2',
        onTimeout: () => describeDeckControllerState(controller),
      );
      await tester.pumpFor(const Duration(milliseconds: 200));

      expect(find.textContaining('1 of 2'), findsOneWidget);
      assertOnlyLayoutOverflowOrNoException(tester);
    });

    testWidgets('currentIndex clamps when slides are removed', (
      tester,
    ) async {
      final initialSlides = [
        makeSlide('s1', '# One'),
        makeSlide('s2', '# Two'),
        makeSlide('s3', '# Three'),
      ];
      await simulateBuildSuccess(workspace, initialSlides, 1);
      loader = FileDeckLoader(workspace: workspace);
      loaderCreated = true;

      final controller = await tester.pumpTestAppWithLoader(loader);
      expect(controller.totalSlides.value, 3);

      // Navigate to the last slide
      await tester.navigateToSlide(controller, 2);
      expect(controller.currentIndex.value, 2);

      // Open menu
      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.isMenuOpen.value,
        debugLabel: 'menu open',
        onTimeout: () => describeDeckControllerState(controller),
      );

      // Rebuild with only 2 slides — index should clamp
      final reducedSlides = [
        makeSlide('s1', '# One'),
        makeSlide('s2', '# Two'),
      ];
      await simulateBuildSuccess(workspace, reducedSlides, 2);
      await tester.pumpUntil(
        () => controller.totalSlides.value == 2,
        debugLabel: 'totalSlides to become 2',
        onTimeout: () => describeDeckControllerState(controller),
      );
      await tester.pumpFor(const Duration(milliseconds: 200));

      expect(controller.currentIndex.value, 1);
      expect(find.textContaining('2 of 2'), findsOneWidget);
      assertOnlyLayoutOverflowOrNoException(tester);
    });

    testWidgets('multiple sequential rebuild cycles complete cleanly', (
      tester,
    ) async {
      final slides1 = [makeSlide('s1', '# Version 1')];
      await simulateBuildSuccess(workspace, slides1, 1);
      loader = FileDeckLoader(workspace: workspace);
      loaderCreated = true;

      final controller = await tester.pumpTestAppWithLoader(loader);
      expect(controller.totalSlides.value, 1);

      // Cycle 1: building → success with 2 slides
      await simulateBuilding(workspace, 2);
      await tester.pumpUntil(
        () => controller.isBuildActive.value,
        debugLabel: 'cycle 1 building',
        onTimeout: () => describeDeckControllerState(controller),
      );

      final slides2 = [
        makeSlide('s1', '# Version 2'),
        makeSlide('s2', '# New Slide'),
      ];
      await simulateBuildSuccess(workspace, slides2, 3);
      await tester.pumpUntil(
        () => controller.totalSlides.value == 2 && !controller.isBuildActive.value,
        debugLabel: 'cycle 1 success',
        onTimeout: () => describeDeckControllerState(controller),
      );

      // Cycle 2: building → success with 3 slides
      await simulateBuilding(workspace, 4);
      await tester.pumpUntil(
        () => controller.isBuildActive.value,
        debugLabel: 'cycle 2 building',
        onTimeout: () => describeDeckControllerState(controller),
      );

      final slides3 = [
        makeSlide('s1', '# Version 3'),
        makeSlide('s2', '# Slide 2'),
        makeSlide('s3', '# Slide 3'),
      ];
      await simulateBuildSuccess(workspace, slides3, 5);
      await tester.pumpUntil(
        () => controller.totalSlides.value == 3 && !controller.isBuildActive.value,
        debugLabel: 'cycle 2 success',
        onTimeout: () => describeDeckControllerState(controller),
      );

      // Verify final state
      expect(controller.hasError.value, isFalse);
      expect(controller.buildFailure.value, isNull);
      expect(controller.totalSlides.value, 3);
      assertOnlyLayoutOverflowOrNoException(tester);
    });
  });
}
