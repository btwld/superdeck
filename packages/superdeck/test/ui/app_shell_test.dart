import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/export/async_thumbnail.dart';
import 'package:superdeck/src/export/thumbnail_service.dart';
import 'package:superdeck/src/ui/app_shell.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../testing_utils.dart';

class _NoopAssetCacheStore implements AssetCacheStore {
  @override
  Future<void> delete(String assetKey) async {}

  @override
  Future<Uri?> resolve(String assetKey) async => null;

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async => null;
}

class _RecordingThumbnailService extends ThumbnailService {
  final List<List<String>> generatedAssetKeys = [];

  _RecordingThumbnailService() : super(cacheStore: _NoopAssetCacheStore());

  @override
  void generateThumbnails({
    required List<SlideData> slides,
    required BuildContext context,
    required Map<String, AsyncThumbnail> cache,
    required void Function(Map<String, AsyncThumbnail>) onCacheUpdate,
    bool force = false,
  }) {
    generatedAssetKeys.add(
      slides.map((slide) => slide.thumbnailFile).toList(growable: false),
    );

    onCacheUpdate({
      for (final slide in slides)
        slide.thumbnailFile: AsyncThumbnail(
          generator: (_, {required force}) async =>
              Uri.parse('memory:${slide.thumbnailFile}'),
        ),
    });
  }
}

void main() {
  testWidgets('rebinds menu effect when the inherited controller changes', (
    tester,
  ) async {
    final controllerA = DeckController(
      deck: createTestDeck(),
      theme: const DeckTheme(),
    );
    final controllerB = DeckController(
      deck: createTestDeck(),
      theme: const DeckTheme(),
    );

    addTearDown(() {
      controllerA.dispose();
      controllerB.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MixScope(
          colors: SDColors.colorMap,
          child: InheritedData<DeckController>(
            data: controllerA,
            child: const AppShell(child: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        home: MixScope(
          colors: SDColors.colorMap,
          child: InheritedData<DeckController>(
            data: controllerB,
            child: const AppShell(child: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();

    controllerB.openMenu();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('regenerates thumbnails when theme changes with menu open', (
    tester,
  ) async {
    final thumbnailService = _RecordingThumbnailService();
    final controller = DeckController(
      deck: createTestDeck(),
      theme: const DeckTheme(),
      thumbnailService: thumbnailService,
    );

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MixScope(
          colors: SDColors.colorMap,
          child: InheritedData<DeckController>(
            data: controller,
            child: const AppShell(child: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();

    controller.openMenu();
    await tester.pump();
    await tester.pump();

    expect(thumbnailService.generatedAssetKeys, hasLength(1));
    final initialAssetKeys = thumbnailService.generatedAssetKeys.single;

    controller.updateTheme(const DeckTheme(debug: true));
    await tester.pump();
    await tester.pump();

    expect(thumbnailService.generatedAssetKeys, hasLength(2));
    expect(
      thumbnailService.generatedAssetKeys[1],
      isNot(equals(initialAssetKeys)),
    );
    expect(
      thumbnailService.generatedAssetKeys[1].first,
      isNot(equals(initialAssetKeys.first)),
    );
    expect(tester.takeException(), isNull);
  });
}
