import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck/src/ui/app_shell.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/mock_deck_loader.dart';
import '../../helpers/test_helpers.dart';

class _RecordingThumbnailService extends ThumbnailService {
  _RecordingThumbnailService() : super(cacheStore: NoopAssetCacheStore());

  int callCount = 0;
  final List<List<String>> slideKeysPerCall = <List<String>>[];

  @override
  void generateThumbnails({
    required List<SlideConfiguration> slides,
    required BuildContext context,
    required Map<String, AsyncThumbnail> cache,
    required void Function(Map<String, AsyncThumbnail>) onCacheUpdate,
    bool force = false,
  }) {
    callCount++;
    slideKeysPerCall.add(
      slides.map((slide) => slide.key).toList(growable: false),
    );
    onCacheUpdate(cache);
  }
}

class _AppShellHarness extends StatelessWidget {
  const _AppShellHarness({required this.controller});

  final DeckController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: controller.router,
      builder: (context, child) {
        return MixScope(
          colors: SDColors.colorMap,
          child: InheritedData(
            data: controller,
            child: AppShell(child: child ?? const SizedBox()),
          ),
        );
      },
    );
  }
}

void main() {
  group('SuperDeckApp', () {
    testWidgets(
      'custom loader without workspace or asset cache store fails fast',
      (tester) async {
        final loader = MockDeckLoader()..disableAutoLoad();
        addTearDown(loader.dispose);

        await tester.pumpWidget(
          SuperDeckApp(options: DeckOptions(), deckLoader: loader),
        );

        expect(
          tester.takeException(),
          anyOf(isA<AssertionError>(), isA<ArgumentError>()),
        );
      },
    );

    testWidgets('custom loader with workspace succeeds', (tester) async {
      final loader = MockDeckLoader()..disableAutoLoad();
      addTearDown(loader.dispose);

      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(),
          deckLoader: loader,
          workspace: DeckWorkspace(projectDir: '/tmp/test-deck'),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('custom loader with asset cache store succeeds', (
      tester,
    ) async {
      final loader = MockDeckLoader()..disableAutoLoad();
      addTearDown(loader.dispose);

      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(),
          deckLoader: loader,
          assetCacheStore: NoopAssetCacheStore(),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('AppShell thumbnail warmup', () {
    testWidgets('warms thumbnails after the first loaded frame', (
      tester,
    ) async {
      final loader = MockDeckLoader();
      final thumbnailService = _RecordingThumbnailService();
      final controller = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
        thumbnailService: thumbnailService,
        transitionDuration: Duration.zero,
      );
      addTearDown(() async {
        controller.dispose();
        await loader.dispose();
      });

      await tester.pumpWidget(_AppShellHarness(controller: controller));
      await tester.pump();
      await tester.pump();

      expect(thumbnailService.callCount, 1);
      expect(
        thumbnailService.slideKeysPerCall.single,
        equals(['slide-0', 'slide-1', 'slide-2']),
      );
    });

    testWidgets(
      'opening the menu does not trigger extra thumbnail generation',
      (tester) async {
        final loader = MockDeckLoader();
        final thumbnailService = _RecordingThumbnailService();
        final controller = DeckController(
          deckLoader: loader,
          options: DeckOptions(),
          thumbnailService: thumbnailService,
          transitionDuration: Duration.zero,
        );
        addTearDown(() async {
          controller.dispose();
          await loader.dispose();
        });

        await tester.pumpWidget(_AppShellHarness(controller: controller));
        await tester.pump();
        await tester.pump();
        expect(thumbnailService.callCount, 1);

        controller.openMenu();
        await tester.pump();
        await tester.pump();

        expect(thumbnailService.callCount, 1);
      },
    );

    testWidgets('warms thumbnails again after slide data changes', (
      tester,
    ) async {
      final loader = MockDeckLoader();
      final thumbnailService = _RecordingThumbnailService();
      final controller = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
        thumbnailService: thumbnailService,
        transitionDuration: Duration.zero,
      );
      addTearDown(() async {
        controller.dispose();
        await loader.dispose();
      });

      await tester.pumpWidget(_AppShellHarness(controller: controller));
      await tester.pump();
      await tester.pump();
      expect(thumbnailService.callCount, 1);

      loader.emitEvent(
        SlidesLoadedEvent(
          createTestSlidesPayload(
            slides: [
              Slide(
                key: 'updated-0',
                sections: [
                  SectionBlock([ContentBlock('Updated slide 0')]),
                ],
              ),
              Slide(
                key: 'updated-1',
                sections: [
                  SectionBlock([ContentBlock('Updated slide 1')]),
                ],
              ),
            ],
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(thumbnailService.callCount, 2);
      expect(
        thumbnailService.slideKeysPerCall.last,
        equals(['updated-0', 'updated-1']),
      );
    });
  });
}
