import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart' show BlockVariant, SlideStyler;
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/rendering/blocks/block_widget.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../fixtures/slide_fixtures.dart';
import '../../helpers/layout_assertions.dart';
import '../../helpers/slide_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BlockWidget', () {
    group('basic rendering', () {
      testWidgets('renders markdown content', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.singleColumn(content: '# Hello World'),
        );

        expect(find.byType(BlockWidget), findsOneWidget);
        expect(find.textContaining('Hello World'), findsOneWidget);
      });

      testWidgets('renders with debug flag without errors', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.singleColumn(),
          debug: true,
        );
        expect(find.byType(BlockWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('alignment', () {
      for (final alignment in ContentAlignment.values) {
        testWidgets('content aligned to $alignment', (tester) async {
          await SlideTestHarness.pumpSlide(
            tester,
            SlideFixtures.withAlignment(alignment),
          );

          final alignWidget = find.byType(Align).first;
          final align = tester.widget<Align>(alignWidget);
          expect(align.alignment, _toAlignment(alignment));
        });
      }

      testWidgets('all 9 alignments render in grid', (tester) async {
        await SlideTestHarness.pumpSlide(tester, SlideFixtures.allAlignments());
        tester.expectBlockCount(9);
        expect(tester.takeException(), isNull);
      });

      testWidgets('block without explicit align defaults to centerLeft', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'default-align',
            sections: [
              SectionBlock([ContentBlock('# No explicit align')]),
            ],
          ),
        );

        final align = tester.widget<Align>(find.byType(Align).first);
        expect(align.alignment, Alignment.centerLeft);
      });
    });

    group('scrollable behavior', () {
      testWidgets('scrollable block wraps content in ScrollView', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.scrollableBlock(lineCount: 80),
        );
        tester.expectScrollable(find.byType(BlockWidget));
      });

      testWidgets('scrollable block responds to drag gestures', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.scrollableBlock(lineCount: 160),
        );

        final scrollable = find.byType(Scrollable).first;
        final state = tester.state<ScrollableState>(scrollable);

        expect(state.position.pixels, 0);

        await tester.drag(scrollable, const Offset(0, -320));
        await tester.pumpAndSettle();

        expect(state.position.pixels, greaterThan(0));
      });

      testWidgets('scrollable widget block responds to drag gestures', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'scrollable-widget',
            sections: [
              SectionBlock([
                WidgetBlock(name: 'tall-widget', scrollable: true),
              ]),
            ],
          ),
          widgets: {'tall-widget': (_) => const _TallWidget()},
        );

        tester.expectScrollable(find.byType(CustomBlockWidget));

        final scrollable = find.byType(Scrollable).first;
        final state = tester.state<ScrollableState>(scrollable);

        expect(state.position.pixels, 0);

        await tester.drag(scrollable, const Offset(0, -320));
        await tester.pumpAndSettle();

        expect(state.position.pixels, greaterThan(0));
      });

      testWidgets('non-scrollable block clips overflow', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.nonScrollableBlock(lineCount: 80),
        );
        tester.expectNotScrollable(find.byType(BlockWidget));
      });

      testWidgets(
        'scrollable block is NOT scrollable during static rendering',
        (tester) async {
          await SlideTestHarness.pumpSlide(
            tester,
            SlideFixtures.scrollableBlock(lineCount: 80),
            isStaticRendering: true,
          );
          tester.expectNotScrollable(find.byType(BlockWidget));
        },
      );

      testWidgets(
        'scrollable widget block is NOT scrollable during static rendering',
        (tester) async {
          await SlideTestHarness.pumpSlide(
            tester,
            Slide(
              key: 'static-widget',
              sections: [
                SectionBlock([
                  WidgetBlock(name: 'short-widget', scrollable: true),
                ]),
              ],
            ),
            widgets: {
              'short-widget': (_) =>
                  const SizedBox(height: 80, child: Text('Static widget')),
            },
            isStaticRendering: true,
          );

          tester.expectNotScrollable(find.byType(CustomBlockWidget));
        },
      );
    });

    group('error handling', () {
      testWidgets('CustomBlockWidget shows error for unknown widget', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.withCustomWidget(widgetName: 'nonexistent_widget_xyz'),
        );
        expect(find.textContaining('Widget not found'), findsOneWidget);
      });

      testWidgets('CustomBlockWidget shows error for throwing factory', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.withCustomWidget(widgetName: 'throwing-widget'),
          widgets: {
            'throwing-widget': (_) => throw StateError('factory failed'),
          },
        );

        expect(find.textContaining('Error building widget'), findsOneWidget);
        expect(find.textContaining('factory failed'), findsOneWidget);
      });
    });

    group('size constraints', () {
      testWidgets('block fills section width', (tester) async {
        await SlideTestHarness.pumpSlide(tester, SlideFixtures.singleColumn());

        final block = find.byType(BlockWidget);
        final size = tester.getSize(block);
        expect(
          size.width,
          greaterThan(700),
        ); // viewport may be smaller than kResolution
        expect(size.height, greaterThan(300)); // header/footer reduce height
      });
    });

    group('named widget block variants', () {
      testWidgets(
        'changes only the matching custom widget container and its usable size',
        (tester) async {
          _setSlideViewport(tester);
          late Size chartSize;
          late Size siblingSize;

          await SlideTestHarness.pumpSlide(
            tester,
            Slide(
              key: 'custom-block-variant',
              sections: [
                SectionBlock([
                  WidgetBlock(name: 'chart'),
                  WidgetBlock(name: 'sibling'),
                ]),
              ],
            ),
            style: SlideStyler(
              blockContainer: BoxStyler(padding: EdgeInsetsGeometryMix.all(40))
                  .variants([
                    VariantStyle(
                      const BlockVariant('chart'),
                      BoxStyler(padding: EdgeInsetsGeometryMix.all(0)),
                    ),
                  ]),
            ),
            widgets: {
              'chart': (_) =>
                  _BlockSizeProbe(onBuild: (size) => chartSize = size),
              'sibling': (_) =>
                  _BlockSizeProbe(onBuild: (size) => siblingSize = size),
            },
          );

          expect(chartSize, const Size(640, 620));
          expect(siblingSize, const Size(560, 540));
        },
      );

      testWidgets(
        'applies the same selector to equivalent resolved widget blocks',
        (tester) async {
          _setSlideViewport(tester);
          final sizes = <String, Size>{};

          await SlideTestHarness.pumpSlide(
            tester,
            Slide(
              key: 'equivalent-webview-blocks',
              sections: [
                SectionBlock([
                  WidgetBlock(
                    name: 'webview',
                    args: const {'source': 'shorthand'},
                  ),
                  WidgetBlock(
                    name: 'webview',
                    args: const {'source': 'widget'},
                  ),
                ]),
              ],
            ),
            style: SlideStyler(
              blockContainer: BoxStyler(padding: EdgeInsetsGeometryMix.all(40))
                  .variants([
                    VariantStyle(
                      const BlockVariant('webview'),
                      BoxStyler(padding: EdgeInsetsGeometryMix.all(0)),
                    ),
                  ]),
            ),
            widgets: {
              'webview': (args) => _BlockSizeProbe(
                onBuild: (size) => sizes[args['source']! as String] = size,
              ),
            },
          );

          expect(sizes, {
            'shorthand': const Size(640, 620),
            'widget': const Size(640, 620),
          });
        },
      );

      testWidgets('keeps plain NamedVariant rules inactive for named blocks', (
        tester,
      ) async {
        _setSlideViewport(tester);
        late Size imageSize;

        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'legacy-named-variant',
            sections: [
              SectionBlock([WidgetBlock(name: 'image')]),
            ],
          ),
          style: SlideStyler(
            blockContainer: BoxStyler(padding: EdgeInsetsGeometryMix.all(40))
                .variants([
                  VariantStyle(
                    const NamedVariant('image'),
                    BoxStyler(padding: EdgeInsetsGeometryMix.all(0)),
                  ),
                ]),
          ),
          widgets: {
            'image': (_) =>
                _BlockSizeProbe(onBuild: (size) => imageSize = size),
          },
        );

        expect(imageSize, const Size(1200, 540));
      });

      testWidgets('keeps default image and gist container spacing unchanged', (
        tester,
      ) async {
        _setSlideViewport(tester);
        late Size imageSize;
        late Size gistSize;

        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'default-image-gist-spacing',
            sections: [
              SectionBlock([
                WidgetBlock(name: 'image'),
                WidgetBlock(name: 'gist'),
              ]),
            ],
          ),
          widgets: {
            'image': (_) =>
                _BlockSizeProbe(onBuild: (size) => imageSize = size),
            'gist': (_) => _BlockSizeProbe(onBuild: (size) => gistSize = size),
          },
        );

        expect(imageSize, const Size(560, 540));
        expect(gistSize, const Size(560, 540));
      });

      testWidgets('gives webview blocks zero padding and margin by default', (
        tester,
      ) async {
        _setSlideViewport(tester);
        late Size webviewSize;

        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'default-webview-spacing',
            sections: [
              SectionBlock([WidgetBlock(name: 'webview')]),
            ],
          ),
          widgets: {
            'webview': (_) =>
                _BlockSizeProbe(onBuild: (size) => webviewSize = size),
          },
        );

        // Full block size with no padding/margin subtracted (default 40 padding
        // would yield 1200x540).
        expect(webviewSize, const Size(1280, 620));
      });

      testWidgets(
        'exposes the active selector to a nested Mix-styled descendant',
        (tester) async {
          _setSlideViewport(tester);
          await SlideTestHarness.pumpSlide(
            tester,
            Slide(
              key: 'nested-mix-descendant',
              sections: [
                SectionBlock([WidgetBlock(name: 'webview')]),
              ],
            ),
            widgets: {'webview': (_) => const _VariantAwareWidget()},
          );

          final paddings = tester
              .widgetList<Container>(find.byType(Container))
              .map((container) => container.padding)
              .toList();

          expect(paddings, contains(const EdgeInsets.all(24)));
        },
      );

      testWidgets(
        'uses matching variant margin and padding once in BlockConfiguration',
        (tester) async {
          _setSlideViewport(tester);
          late Size blockSize;

          await SlideTestHarness.pumpSlide(
            tester,
            Slide(
              key: 'variant-layout-offset',
              sections: [
                SectionBlock([WidgetBlock(name: 'webview')]),
              ],
            ),
            style: SlideStyler(
              blockContainer:
                  BoxStyler(
                    padding: EdgeInsetsGeometryMix.all(10),
                    margin: EdgeInsetsGeometryMix.all(5),
                  ).variants([
                    VariantStyle(
                      const BlockVariant('webview'),
                      BoxStyler(
                        padding: EdgeInsetsGeometryMix.all(20),
                        margin: EdgeInsetsGeometryMix.all(10),
                      ),
                    ),
                  ]),
            ),
            widgets: {
              'webview': (_) =>
                  _BlockSizeProbe(onBuild: (size) => blockSize = size),
            },
          );

          expect(blockSize, const Size(1220, 560));
          expect(tester.takeException(), isNull);
        },
      );
    });

    group('markdown content types', () {
      testWidgets('renders headings and lists', (tester) async {
        await SlideTestHarness.pumpSlide(tester, SlideFixtures.mixedMarkdown());

        expect(find.textContaining('Title'), findsOneWidget);
        expect(find.textContaining('Item 1'), findsOneWidget);
      });

      testWidgets('renders code block', (tester) async {
        await SlideTestHarness.pumpSlide(tester, SlideFixtures.withCodeBlock());
        expect(find.byType(BlockWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

class _TallWidget extends StatelessWidget {
  const _TallWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < 60; index++)
            SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Tall widget row $index'),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockSizeProbe extends StatelessWidget {
  const _BlockSizeProbe({required this.onBuild});

  final ValueChanged<Size> onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(BlockConfiguration.of(context).size);
    return const SizedBox.shrink();
  }
}

class _VariantAwareWidget extends StatelessWidget {
  const _VariantAwareWidget();

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler(padding: EdgeInsetsGeometryMix.all(4)).variants([
        VariantStyle(
          const BlockVariant('webview'),
          BoxStyler(padding: EdgeInsetsGeometryMix.all(24)),
        ),
      ]),
      child: const SizedBox(width: 1, height: 1),
    );
  }
}

void _setSlideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Alignment _toAlignment(ContentAlignment alignment) {
  return switch (alignment) {
    ContentAlignment.topLeft => Alignment.topLeft,
    ContentAlignment.topCenter => Alignment.topCenter,
    ContentAlignment.topRight => Alignment.topRight,
    ContentAlignment.centerLeft => Alignment.centerLeft,
    ContentAlignment.center => Alignment.center,
    ContentAlignment.centerRight => Alignment.centerRight,
    ContentAlignment.bottomLeft => Alignment.bottomLeft,
    ContentAlignment.bottomCenter => Alignment.bottomCenter,
    ContentAlignment.bottomRight => Alignment.bottomRight,
  };
}
