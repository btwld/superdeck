import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart'
    show BlockStyler, BlockVariant, SlideParts, SlideStyler;
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/rendering/blocks/block_widget.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/src/ui/widgets/overflow_clip.dart';
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

          final alignWidget = find
              .descendant(
                of: find.byType(BlockWidget),
                matching: find.byType(Align),
              )
              .first;
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

        final align = tester.widget<Align>(
          find
              .descendant(
                of: find.byType(BlockWidget),
                matching: find.byType(Align),
              )
              .first,
        );
        expect(align.alignment, Alignment.centerLeft);
      });

      testWidgets('block inherits section alignment', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'section-align',
            sections: [
              SectionBlock([
                ContentBlock('# Inherited'),
              ], align: ContentAlignment.bottomRight),
            ],
          ),
        );

        final align = tester.widget<Align>(
          find
              .descendant(
                of: find.byType(BlockWidget),
                matching: find.byType(Align),
              )
              .first,
        );
        expect(align.alignment, Alignment.bottomRight);
      });

      testWidgets('resolved alignment reaches BlockConfiguration', (
        tester,
      ) async {
        ContentAlignment? observedAlignment;
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'section-configuration-align',
            sections: [
              SectionBlock([
                WidgetBlock(name: 'alignment-probe'),
              ], align: ContentAlignment.topCenter),
            ],
          ),
          widgets: {
            'alignment-probe': (_) => _AlignmentProbe(
              onBuild: (alignment) => observedAlignment = alignment,
            ),
          },
        );

        expect(observedAlignment, ContentAlignment.topCenter);
      });

      testWidgets('explicit block alignment overrides section alignment', (
        tester,
      ) async {
        ContentAlignment? observedAlignment;
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'block-configuration-align',
            sections: [
              SectionBlock([
                WidgetBlock(
                  name: 'alignment-probe',
                  align: ContentAlignment.centerRight,
                ),
              ], align: ContentAlignment.topLeft),
            ],
          ),
          widgets: {
            'alignment-probe': (_) => _AlignmentProbe(
              onBuild: (alignment) => observedAlignment = alignment,
            ),
          },
        );

        final align = tester.widget<Align>(
          find
              .descendant(
                of: find.byType(CustomBlockWidget),
                matching: find.byType(Align),
              )
              .first,
        );
        expect(align.alignment, Alignment.centerRight);
        expect(observedAlignment, ContentAlignment.centerRight);
      });

      for (final alignment in ContentAlignment.values) {
        testWidgets('$alignment positions content inside a full block frame', (
          tester,
        ) async {
          const markerKey = ValueKey('alignment-marker');
          await SlideTestHarness.pumpSlide(
            tester,
            Slide(
              key: 'frame-${alignment.name}',
              sections: [
                SectionBlock([WidgetBlock(name: 'fixed', align: alignment)]),
              ],
            ),
            parts: const SlideParts(header: null, footer: null),
            widgets: {
              'fixed': (_) =>
                  const SizedBox(key: markerKey, width: 20, height: 10),
            },
          );

          final blockRect = tester.getRect(find.byType(CustomBlockWidget));
          final boxRect = tester.getRect(
            find.descendant(
              of: find.byType(CustomBlockWidget),
              matching: find.byType(Box),
            ),
          );
          final markerRect = tester.getRect(find.byKey(markerKey));
          final innerRect = Rect.fromLTRB(
            blockRect.left + 40,
            blockRect.top + 40,
            blockRect.right - 40,
            blockRect.bottom - 40,
          );

          expect(boxRect, blockRect);
          expect(
            markerRect,
            _toAlignment(alignment).inscribe(markerRect.size, innerRect),
          );
        });
      }
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
        'static scrollable widget lays out naturally and clips to its frame',
        (tester) async {
          const childKey = ValueKey('static-scrollable-child');
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
              'short-widget': (_) => const SizedBox(
                key: childKey,
                height: 1000,
                child: Text('Static widget'),
              ),
            },
            isStaticRendering: true,
          );

          tester.expectNotScrollable(find.byType(CustomBlockWidget));
          expect(
            tester.getSize(find.byKey(childKey)).height,
            greaterThan(tester.getSize(find.byType(CustomBlockWidget)).height),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'static scrollable widget preserves live unbounded child layout',
        (tester) async {
          const markerKey = ValueKey('scrollable-widget-top-marker');
          final observedMaxHeights = <double>[];
          final slide = Slide(
            key: 'scrollable-widget-layout-parity',
            sections: [
              SectionBlock([
                WidgetBlock(
                  name: 'constraint-probe',
                  align: ContentAlignment.bottomRight,
                  scrollable: true,
                ),
              ]),
            ],
          );
          final widgets = {
            'constraint-probe': (_) => LayoutBuilder(
              builder: (context, constraints) {
                observedMaxHeights.add(constraints.maxHeight);
                return const SizedBox(
                  height: 1000,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(key: markerKey, width: 10, height: 10),
                  ),
                );
              },
            ),
          };

          await SlideTestHarness.pumpSlide(tester, slide, widgets: widgets);
          final liveMaxHeight = observedMaxHeights.last;
          final liveMarkerOffset =
              tester.getTopLeft(find.byKey(markerKey)) -
              tester.getTopLeft(find.byType(CustomBlockWidget));

          observedMaxHeights.clear();
          await SlideTestHarness.pumpSlide(
            tester,
            slide,
            widgets: widgets,
            isStaticRendering: true,
          );
          final staticMaxHeight = observedMaxHeights.last;
          final staticMarkerOffset =
              tester.getTopLeft(find.byKey(markerKey)) -
              tester.getTopLeft(find.byType(CustomBlockWidget));

          expect(liveMaxHeight.isInfinite, isTrue);
          expect(staticMaxHeight, liveMaxHeight);
          expect(staticMarkerOffset, liveMarkerOffset);
          tester.expectNotScrollable(find.byType(CustomBlockWidget));
        },
      );
    });

    group('overflow diagnostics', () {
      late List<String> logs;

      setUp(() {
        logs = [];
        OverflowDiagnostics.resetForTesting();
        OverflowDiagnostics.logger = logs.add;
      });

      tearDown(OverflowDiagnostics.resetForTesting);

      testWidgets('does not report content that fits', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.singleColumn(content: 'Content that fits.'),
          debug: true,
        );

        expect(find.byType(OverflowDiagnosticProbe), findsOneWidget);
        expect(OverflowDiagnostics.activeIssuesForTesting, isEmpty);
        expect(logs, isEmpty);
      });

      testWidgets('preserves the assigned markdown wrapping width', (
        tester,
      ) async {
        final content = List.filled(60, 'wrapping sentinel').join(' ');
        final slide = Slide(
          key: 'wrapping-width',
          sections: [
            SectionBlock([ContentBlock(content)]),
          ],
        );
        final textFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == content,
        );

        await SlideTestHarness.pumpSlide(
          tester,
          slide,
          debug: true,
          isStaticRendering: true,
        );
        final withoutDiagnostics = tester.getSize(textFinder);

        await SlideTestHarness.pumpSlide(tester, slide, debug: true);
        final withDiagnostics = tester.getSize(textFinder);

        expect(withDiagnostics, withoutDiagnostics);
      });

      testWidgets('reports vertical markdown overflow with stable identity', (
        tester,
      ) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.nonScrollableBlock(lineCount: 100),
          debug: true,
        );

        expect(logs, hasLength(1));
        expect(
          logs.single,
          allOf(
            contains('slide=fixture-non-scrollable-block'),
            contains('block=fixture-non-scrollable-block:s0:b0'),
            contains('available='),
            contains('measured='),
            contains('axis=vertical'),
          ),
        );
        final issue = OverflowDiagnostics.activeIssuesForTesting.values.single;
        expect(issue.axes, contains(Axis.vertical));
      });

      testWidgets('reports unwrapped horizontal markdown overflow', (
        tester,
      ) async {
        final content = List.filled(400, 'W').join();
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'horizontal-overflow',
            sections: [
              SectionBlock([ContentBlock(content)]),
            ],
          ),
          style: SlideStyler(p: TextStyler(softWrap: false)),
          debug: true,
        );

        expect(logs, hasLength(1));
        expect(logs.single, contains('axis=horizontal'));
        final issue = OverflowDiagnostics.activeIssuesForTesting.values.single;
        expect(issue.axes, contains(Axis.horizontal));
      });

      testWidgets(
        'deduplicates stable issues and logs again after resolution',
        (tester) async {
          Slide slide(String content) => Slide(
            key: 'resolving-overflow',
            sections: [
              SectionBlock([ContentBlock(content)]),
            ],
          );
          final overflow = List.filled(100, 'Overflow line').join('\n');

          await SlideTestHarness.pumpSlide(
            tester,
            slide(overflow),
            debug: true,
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          expect(logs, hasLength(1));

          await SlideTestHarness.pumpSlide(
            tester,
            slide('Resolved content.'),
            debug: true,
          );
          expect(OverflowDiagnostics.activeIssuesForTesting, isEmpty);

          await SlideTestHarness.pumpSlide(
            tester,
            slide(overflow),
            debug: true,
          );
          expect(logs, hasLength(2));
        },
      );

      testWidgets('logs when the overflow axis changes', (tester) async {
        final vertical = List.filled(100, 'Overflow line').join('\n');
        final horizontal = List.filled(400, 'W').join();

        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'changing-overflow',
            sections: [
              SectionBlock([ContentBlock(vertical)]),
            ],
          ),
          debug: true,
        );
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'changing-overflow',
            sections: [
              SectionBlock([ContentBlock(horizontal)]),
            ],
          ),
          style: SlideStyler(p: TextStyler(softWrap: false)),
          debug: true,
        );

        expect(logs, hasLength(2));
        expect(logs.first, contains('axis=vertical'));
        expect(logs.last, contains('axis=horizontal'));
      });

      testWidgets('skips scrollable and static content', (tester) async {
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.scrollableBlock(lineCount: 100),
          debug: true,
        );
        expect(find.byType(OverflowDiagnosticProbe), findsNothing);

        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.nonScrollableBlock(lineCount: 100),
          debug: true,
          isStaticRendering: true,
        );
        expect(find.byType(OverflowDiagnosticProbe), findsNothing);
        expect(logs, isEmpty);
      });

      testWidgets('probes custom widgets once through the shared frame', (
        tester,
      ) async {
        var buildCount = 0;
        await SlideTestHarness.pumpSlide(
          tester,
          SlideFixtures.withCustomWidget(widgetName: 'counting-widget'),
          widgets: {
            'counting-widget': (_) => Builder(
              builder: (context) {
                buildCount += 1;
                return const OverflowBox(
                  maxWidth: 2400,
                  maxHeight: 2400,
                  child: SizedBox(width: 2400, height: 2400),
                );
              },
            ),
          },
          debug: true,
        );

        expect(buildCount, 1);
        expect(find.byType(OverflowDiagnosticProbe), findsOneWidget);
        expect(logs, hasLength(1));
        expect(
          logs.single,
          contains('block=fixture-custom-widget-counting-widget:s0:b0'),
        );
      });

      testWidgets(
        'outlines an overflowing frame without covering aligned content',
        (tester) async {
          tester.view.physicalSize = const Size(100, 100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          const boundaryKey = ValueKey('overflow-indicator-boundary');

          await tester.pumpWidget(
            const Directionality(
              textDirection: TextDirection.ltr,
              child: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: OverflowDiagnosticProbe(
                    slideKey: 'indicator-slide',
                    runtimeKey: 'indicator-slide:s0:b0',
                    availableSize: Size(100, 100),
                    child: OverflowBox(
                      maxWidth: 200,
                      maxHeight: 200,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: ColoredBox(color: Color(0xFF0000FF)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(OverflowDiagnostics.activeIssuesForTesting, isNotEmpty);

          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundaryKey),
          );
          final pixels = await tester.runAsync(() async {
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              );
              List<int> pixel(int x, int y) {
                final pixelOffset = (y * image.width + x) * 4;
                return bytes!.buffer.asUint8List(pixelOffset, 4).toList();
              }

              return {
                'topEdge': pixel(50, 0),
                'rightEdge': pixel(99, 50),
                'topRightInterior': pixel(95, 5),
              };
            } finally {
              image.dispose();
            }
          });

          // The frame outline paints on the edges...
          expect(pixels!['topEdge'], [255, 59, 48, 255]);
          expect(pixels['rightEdge'], [255, 59, 48, 255]);
          // ...but content aligned to the top-right corner stays visible.
          expect(pixels['topRightInterior'], [0, 0, 255, 255]);
        },
      );

      testWidgets('allows Hero flights between changing constraints', (
        tester,
      ) async {
        Widget route(Size size, Color color) {
          return Scaffold(
            body: Center(
              child: SizedBox.fromSize(
                size: size,
                child: OverflowDiagnosticProbe(
                  slideKey: 'hero-slide',
                  runtimeKey: 'hero-slide:s0:b0',
                  availableSize: size,
                  child: Hero(
                    tag: 'diagnostic-hero',
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            home: route(const Size(320, 200), Colors.blue),
            routes: {'/next': (_) => route(const Size(180, 120), Colors.green)},
          ),
        );

        tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
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

    group('block container safety', () {
      testWidgets('sanitizes low-level raw styles at the render boundary', (
        tester,
      ) async {
        _setSlideViewport(tester);
        late BlockConfiguration blockData;
        final animation = AnimationConfig.linear(
          const Duration(milliseconds: 100),
        );

        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'raw-block-container-style',
            sections: [
              SectionBlock([WidgetBlock(name: 'custom')]),
            ],
          ),
          style: SlideStyler.create(
            blockContainer: Prop.value(
              StyleSpec(
                spec: BoxSpec(
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 100),
                  transform: Matrix4.diagonal3Values(2, 2, 1),
                  alignment: Alignment.center,
                ),
                animation: animation,
                widgetModifiers: const [],
              ),
            ),
          ),
          widgets: {
            'custom': (_) =>
                _BlockDataProbe(onBuild: (data) => blockData = data),
          },
        );

        final container = blockData.spec.blockContainer;
        expect(container.spec.padding, const EdgeInsets.all(12));
        expect(container.spec.constraints, isNull);
        expect(container.spec.transform, isNull);
        expect(container.spec.alignment, isNull);
        expect(container.widgetModifiers, isNull);
        expect(container.animation, same(animation));
      });
    });

    group('inset overrides', () {
      testWidgets('absent override retains resolved style padding', (
        tester,
      ) async {
        _setSlideViewport(tester);
        late Size blockSize;
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'default-padding',
            sections: [
              SectionBlock([WidgetBlock(name: 'custom')]),
            ],
          ),
          widgets: {
            'custom': (_) =>
                _BlockSizeProbe(onBuild: (size) => blockSize = size),
          },
        );

        expect(blockSize, const Size(1200, 540));
      });

      testWidgets('padding zero makes a block edge-to-edge', (tester) async {
        _setSlideViewport(tester);
        late Size blockSize;
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'zero-padding',
            sections: [
              SectionBlock([
                WidgetBlock.fromJson({
                  'type': 'widget',
                  'name': 'custom',
                  'padding': {'top': 0, 'right': 0, 'bottom': 0, 'left': 0},
                }),
              ]),
            ],
          ),
          widgets: {
            'custom': (_) =>
                _BlockSizeProbe(onBuild: (size) => blockSize = size),
          },
        );

        expect(blockSize, const Size(1280, 620));
      });

      testWidgets('padding zero makes markdown content edge-to-edge', (
        tester,
      ) async {
        _setSlideViewport(tester);
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'zero-content-padding',
            sections: [
              SectionBlock([
                ContentBlock('Content', padding: BlockInsets.all(0)),
              ]),
            ],
          ),
        );

        final provider = tester.widget<InheritedData<BlockConfiguration>>(
          find.byWidgetPredicate(
            (widget) => widget is InheritedData<BlockConfiguration>,
          ),
        );
        expect(provider.data.size, const Size(1280, 620));
      });

      testWidgets('asymmetric padding determines exact usable size', (
        tester,
      ) async {
        _setSlideViewport(tester);
        late Size blockSize;
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'asymmetric-padding',
            sections: [
              SectionBlock([
                WidgetBlock.fromJson({
                  'type': 'widget',
                  'name': 'custom',
                  'padding': {'top': 30, 'right': 20, 'bottom': 40, 'left': 10},
                }),
              ]),
            ],
          ),
          widgets: {
            'custom': (_) =>
                _BlockSizeProbe(onBuild: (size) => blockSize = size),
          },
        );

        expect(blockSize, const Size(1250, 550));
      });

      testWidgets(
        'overrides replace only matching insets after variants resolve',
        (tester) async {
          _setSlideViewport(tester);
          late BlockConfiguration blockData;
          const variantColor = Color(0xFFCC3344);
          final animation = AnimationConfig.ease(
            const Duration(milliseconds: 120),
          );
          await SlideTestHarness.pumpSlide(
            tester,
            Slide(
              key: 'preserved-variant-geometry',
              sections: [
                SectionBlock([
                  WidgetBlock.fromJson({
                    'type': 'widget',
                    'name': 'chart',
                    'padding': {'top': 4, 'right': 4, 'bottom': 4, 'left': 4},
                    'margin': {'top': 6, 'right': 6, 'bottom': 6, 'left': 6},
                  }),
                ]),
              ],
            ),
            style: SlideStyler(
              blockContainer:
                  BlockStyler(
                    padding: EdgeInsetsGeometryMix.all(10),
                    margin: EdgeInsetsGeometryMix.all(5),
                    decoration: BoxDecorationMix(
                      color: const Color(0xFF224466),
                      border: BorderMix.all(BorderSideMix(width: 2)),
                    ),
                  ).animate(animation).variants([
                    VariantStyle(
                      const BlockVariant('chart'),
                      BlockStyler(
                        padding: EdgeInsetsGeometryMix.all(20),
                        margin: EdgeInsetsGeometryMix.all(10),
                        decoration: BoxDecorationMix(
                          color: variantColor,
                          border: BorderMix.all(BorderSideMix(width: 3)),
                        ),
                      ),
                    ),
                  ]),
            ),
            widgets: {
              'chart': (_) =>
                  _BlockDataProbe(onBuild: (data) => blockData = data),
            },
          );

          final container = blockData.spec.blockContainer.spec;
          final decoration = container.decoration! as BoxDecoration;
          // 1280/620 minus padding 4*2, margin 6*2, border 3*2.
          expect(blockData.size, const Size(1254, 594));
          expect(container.padding, const EdgeInsets.all(4));
          expect(container.margin, const EdgeInsets.all(6));
          expect(decoration.color, variantColor);
          expect(decoration.border!.dimensions, const EdgeInsets.all(3));
          expect(blockData.spec.blockContainer.animation, same(animation));
          // No modifier can wrap the framework-owned block container.
          expect(blockData.spec.blockContainer.widgetModifiers, isNull);
        },
      );

      for (final name in ['image', 'gist', 'webview', 'custom']) {
        testWidgets('$name padding overrides its resolved variant', (
          tester,
        ) async {
          _setSlideViewport(tester);
          late Size blockSize;
          await SlideTestHarness.pumpSlide(
            tester,
            Slide(
              key: '$name-padding',
              sections: [
                SectionBlock([
                  WidgetBlock.fromJson({
                    'type': 'widget',
                    'name': name,
                    'padding': {
                      'top': 12,
                      'right': 12,
                      'bottom': 12,
                      'left': 12,
                    },
                  }),
                ]),
              ],
            ),
            widgets: {
              name: (_) => _BlockSizeProbe(onBuild: (size) => blockSize = size),
            },
          );

          expect(blockSize, const Size(1256, 596));
        });
      }

      testWidgets('asymmetric margin determines exact usable size', (
        tester,
      ) async {
        _setSlideViewport(tester);
        late Size blockSize;
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'asymmetric-margin',
            sections: [
              SectionBlock([
                WidgetBlock.fromJson({
                  'type': 'widget',
                  'name': 'custom',
                  'margin': {'top': 10, 'right': 20, 'bottom': 30, 'left': 40},
                }),
              ]),
            ],
          ),
          widgets: {
            'custom': (_) =>
                _BlockSizeProbe(onBuild: (size) => blockSize = size),
          },
        );

        // Default style padding 40 plus the authored margin edges.
        expect(blockSize, const Size(1140, 500));
      });

      testWidgets('symmetric content-block margin reduces usable size', (
        tester,
      ) async {
        _setSlideViewport(tester);
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'content-margin',
            sections: [
              SectionBlock([
                ContentBlock(
                  'Content',
                  margin: BlockInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ]),
            ],
          ),
        );

        final provider = tester.widget<InheritedData<BlockConfiguration>>(
          find.byWidgetPredicate(
            (widget) => widget is InheritedData<BlockConfiguration>,
          ),
        );
        // Default style padding 40 plus margin 10 on every edge.
        expect(provider.data.size, const Size(1180, 520));
      });

      testWidgets('margin zero with zero padding stays edge-to-edge', (
        tester,
      ) async {
        _setSlideViewport(tester);
        late Size blockSize;
        await SlideTestHarness.pumpSlide(
          tester,
          Slide(
            key: 'zero-insets',
            sections: [
              SectionBlock([
                WidgetBlock(
                  name: 'custom',
                  margin: BlockInsets.all(0),
                  padding: BlockInsets.all(0),
                ),
              ]),
            ],
          ),
          widgets: {
            'custom': (_) =>
                _BlockSizeProbe(onBuild: (size) => blockSize = size),
          },
        );

        expect(blockSize, const Size(1280, 620));
      });

      testWidgets(
        'margin consumes only its own frame; spacing and flex are unchanged',
        (tester) async {
          _setSlideViewport(tester);
          late Size marginedSize;
          late Size siblingSize;
          await SlideTestHarness.pumpSlide(
            tester,
            Slide(
              key: 'spacing-plus-margin',
              sections: [
                SectionBlock([
                  WidgetBlock(name: 'margined', margin: BlockInsets.all(10)),
                  WidgetBlock(name: 'sibling'),
                ], spacing: 40),
              ],
            ),
            widgets: {
              'margined': (_) =>
                  _BlockSizeProbe(onBuild: (size) => marginedSize = size),
              'sibling': (_) =>
                  _BlockSizeProbe(onBuild: (size) => siblingSize = size),
            },
          );

          // Equal flex splits (1280 - 40 spacing) into 620-wide frames. The
          // margin reduces only the margined block's usable area; the sibling
          // keeps the full frame minus default padding.
          expect(marginedSize, const Size(520, 520));
          expect(siblingSize, const Size(540, 540));
        },
      );
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
              blockContainer:
                  BlockStyler(padding: EdgeInsetsGeometryMix.all(40)).variants([
                    VariantStyle(
                      const BlockVariant('chart'),
                      BlockStyler(padding: EdgeInsetsGeometryMix.all(0)),
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
              blockContainer:
                  BlockStyler(padding: EdgeInsetsGeometryMix.all(40)).variants([
                    VariantStyle(
                      const BlockVariant('webview'),
                      BlockStyler(padding: EdgeInsetsGeometryMix.all(0)),
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
            blockContainer: BlockStyler(padding: EdgeInsetsGeometryMix.all(40))
                .variants([
                  VariantStyle(
                    const NamedVariant('image'),
                    BlockStyler(padding: EdgeInsetsGeometryMix.all(0)),
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
                  BlockStyler(
                    padding: EdgeInsetsGeometryMix.all(10),
                    margin: EdgeInsetsGeometryMix.all(5),
                  ).variants([
                    VariantStyle(
                      const BlockVariant('webview'),
                      BlockStyler(
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

class _BlockDataProbe extends StatelessWidget {
  const _BlockDataProbe({required this.onBuild});

  final ValueChanged<BlockConfiguration> onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(BlockConfiguration.of(context));
    return const SizedBox.shrink();
  }
}

class _AlignmentProbe extends StatelessWidget {
  const _AlignmentProbe({required this.onBuild});

  final ValueChanged<ContentAlignment> onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(BlockConfiguration.of(context).align);
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
