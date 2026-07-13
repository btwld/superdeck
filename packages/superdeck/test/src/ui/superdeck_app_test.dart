import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck/src/deck/default_deck_setup.dart';
import 'package:superdeck/src/ui/app_shell.dart';
import 'package:superdeck/src/ui/panels/bottom_bar.dart';
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
      routerConfig: controller.presentation.router,
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

final class _TestRuntimePlugin extends DeckRuntimePlugin {
  const _TestRuntimePlugin({required this.pluginId, this.actions = const []});

  final String pluginId;

  @override
  final List<DeckAction> actions;

  @override
  String get id => pluginId;
}

Future<void> _openDeckMenu(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Open menu'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
}

ByteData _utf8ByteData(String value) {
  return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
}

void _mockBundledDeckAsset(DeckWorkspace workspace, List<Slide> slides) {
  final payload = jsonEncode(
    slides.map((slide) => slide.toMap()).toList(growable: false),
  );
  rootBundle.evict(workspace.bundledDeckJsonPath);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final assetKey = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        if (assetKey != workspace.bundledDeckJsonPath) return null;

        return _utf8ByteData(payload);
      });
}

void main() {
  group('SuperDeckApp', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

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

    testWidgets('force-bundled loader recipe loads bundled slides', (
      tester,
    ) async {
      final workspace = DeckWorkspace();
      _mockBundledDeckAsset(workspace, [
        createSlideFromBlocks([ContentBlock('Bundled recipe slide')]),
      ]);

      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(),
          deckLoader: BundledDeckLoader(workspace: workspace),
          workspace: workspace,
          transitionDuration: Duration.zero,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Bundled recipe slide'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('auto-selects bundled loader when no project root is found', (
      tester,
    ) async {
      debugSetDefaultDeckSetupFindRootOverride((_) => null);
      addTearDown(() {
        debugSetDefaultDeckSetupFindRootOverride(null);
      });

      final workspace = DeckWorkspace();
      _mockBundledDeckAsset(workspace, [
        createSlideFromBlocks([ContentBlock('Auto bundled slide')]),
      ]);

      await tester.pumpWidget(
        SuperDeckApp(options: DeckOptions(), transitionDuration: Duration.zero),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Auto bundled slide'), findsOneWidget);
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

    testWidgets('passes runtime plugin actions to the bottom bar', (
      tester,
    ) async {
      final loader = MockDeckLoader();
      addTearDown(loader.dispose);

      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(),
          deckLoader: loader,
          assetCacheStore: NoopAssetCacheStore(),
          transitionDuration: Duration.zero,
          plugins: [
            _TestRuntimePlugin(
              pluginId: 'test.pdf',
              actions: [
                DeckAction(
                  id: 'test.actions.export',
                  label: 'Test deck action',
                  icon: Icons.picture_as_pdf,
                  onPressed: (_, _) {},
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await _openDeckMenu(tester);

      expect(find.bySemanticsLabel('Test deck action'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invokes runtime plugin actions with the active controller', (
      tester,
    ) async {
      final loader = MockDeckLoader();
      DeckController? callbackDeck;
      var tapCount = 0;
      addTearDown(loader.dispose);

      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(),
          deckLoader: loader,
          assetCacheStore: NoopAssetCacheStore(),
          transitionDuration: Duration.zero,
          plugins: [
            _TestRuntimePlugin(
              pluginId: 'test.inspect',
              actions: [
                DeckAction(
                  id: 'test.actions.inspect',
                  label: 'Inspect deck',
                  icon: Icons.info_outline,
                  onPressed: (_, deck) {
                    callbackDeck = deck;
                    tapCount++;
                  },
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await _openDeckMenu(tester);

      final actionFinder = find.bySemanticsLabel('Inspect deck');
      await tester.tap(actionFinder);
      await tester.pump();

      expect(tapCount, 1);
      expect(callbackDeck, isNotNull);
      expect(callbackDeck!.slides.value, isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rejects empty runtime plugin ids', (tester) async {
      final loader = MockDeckLoader();
      addTearDown(loader.dispose);

      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(),
          deckLoader: loader,
          assetCacheStore: NoopAssetCacheStore(),
          transitionDuration: Duration.zero,
          plugins: const [_TestRuntimePlugin(pluginId: '')],
        ),
      );

      expect(
        tester.takeException(),
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'Runtime plugin id must not be empty.',
        ),
      );
    });

    testWidgets('rejects duplicate runtime plugin ids', (tester) async {
      final loader = MockDeckLoader();
      addTearDown(loader.dispose);

      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(),
          deckLoader: loader,
          assetCacheStore: NoopAssetCacheStore(),
          transitionDuration: Duration.zero,
          plugins: const [
            _TestRuntimePlugin(pluginId: 'test.duplicate'),
            _TestRuntimePlugin(pluginId: 'test.duplicate'),
          ],
        ),
      );

      expect(
        tester.takeException(),
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'Duplicate runtime plugin id "test.duplicate".',
        ),
      );
    });

    testWidgets('rejects duplicate runtime action ids', (tester) async {
      final loader = MockDeckLoader();
      addTearDown(loader.dispose);

      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(),
          deckLoader: loader,
          assetCacheStore: NoopAssetCacheStore(),
          transitionDuration: Duration.zero,
          plugins: [
            _TestRuntimePlugin(
              pluginId: 'test.first',
              actions: [
                DeckAction(
                  id: 'test.action.duplicate',
                  label: 'First action',
                  icon: Icons.picture_as_pdf,
                  onPressed: (_, _) {},
                ),
              ],
            ),
            _TestRuntimePlugin(
              pluginId: 'test.second',
              actions: [
                DeckAction(
                  id: 'test.action.duplicate',
                  label: 'Second action',
                  icon: Icons.picture_as_pdf,
                  onPressed: (_, _) {},
                ),
              ],
            ),
          ],
        ),
      );

      expect(
        tester.takeException(),
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'Duplicate deck action id "test.action.duplicate" from runtime '
              'plugin "test.second".',
        ),
      );
    });

    testWidgets('shell modal host exposes modal controller to descendants', (
      tester,
    ) async {
      DeckShellModalEntry? modalEntry;

      await tester.pumpWidget(
        MaterialApp(
          home: DeckShellModalHost(
            child: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    modalEntry = DeckShellModal.maybeOf(context)?.show(
                      builder: (_) => const ColoredBox(
                        color: Colors.black,
                        child: Center(child: Text('Shell modal content')),
                      ),
                    );
                  },
                  child: const Text('Open shell modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open shell modal'));
      await tester.pump();

      expect(modalEntry, isNotNull);
      expect(find.text('Shell modal content'), findsOneWidget);

      modalEntry!.close();
      await tester.pump();

      expect(find.text('Shell modal content'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('DeckBottomBar actions', () {
    testWidgets('invokes action callbacks with the current controller', (
      tester,
    ) async {
      final loader = MockDeckLoader();
      DeckController? callbackDeck;
      var tapCount = 0;
      final controller = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
        transitionDuration: Duration.zero,
      );
      addTearDown(() async {
        controller.dispose();
        await loader.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MixScope(
            colors: SDColors.colorMap,
            child: InheritedData(
              data: controller,
              child: Center(
                child: SizedBox(
                  width: 800,
                  child: DeckBottomBar(
                    actions: [
                      DeckAction(
                        id: 'test.actions.export',
                        label: 'Test deck action',
                        icon: Icons.picture_as_pdf,
                        onPressed: (context, deck) {
                          callbackDeck = deck;
                          tapCount++;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Test deck action'));
      await tester.pump();

      expect(tapCount, 1);
      expect(callbackDeck, isNotNull);
      expect(callbackDeck!.slides.value, isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports asynchronous action failures', (tester) async {
      final loader = MockDeckLoader();
      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = errors.add;

      final controller = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
        transitionDuration: Duration.zero,
      );
      addTearDown(() async {
        FlutterError.onError = originalOnError;
        controller.dispose();
        await loader.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MixScope(
            colors: SDColors.colorMap,
            child: InheritedData(
              data: controller,
              child: Center(
                child: SizedBox(
                  width: 800,
                  child: DeckBottomBar(
                    actions: [
                      DeckAction(
                        id: 'test.actions.fail',
                        label: 'Failing deck action',
                        icon: Icons.picture_as_pdf,
                        onPressed: (_, _) async {
                          throw StateError('action failed');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Failing deck action'));
      await tester.pump();

      expect(errors, hasLength(1));
      expect(errors.single.exception, isA<StateError>());
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

        controller.presentation.openMenu();
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
