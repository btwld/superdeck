import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/rendering/slides/slide_view.dart';
import 'package:superdeck/src/styling/components/slide.dart';
import 'package:superdeck/src/styling/default_style.dart';
import 'package:superdeck/src/ui/widgets/cache_image_widget.dart';
import 'package:superdeck/src/ui/widgets/hero_element.dart';
import 'package:superdeck/src/ui/widgets/image_hero_flight.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/slide_test_harness.dart';

const _heroText = 'Constraint driven Hero';
const _imageUri = 'https://example.com/hero.png';
const _transitionDuration = Duration(seconds: 1);
const _animateHeroText = bool.fromEnvironment(
  'SUPERDECK_ANIMATE_HERO_TEXT',
  defaultValue: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final content in [
    ('# Hello World {.redirect}', '### Hello Friend {.redirect}'),
    ('A small idea {.redirect}', '### A small idea {.redirect}'),
    (
      '```dart {.redirect}\nfinal a = 1;\n```',
      '```dart {.redirect}\nfinal answer = 42;\nprint(answer);\n```',
    ),
  ]) {
    testWidgets('redirected page Hero retains its endpoint: ${content.$1}', (
      tester,
    ) async {
      _setSlideViewport(tester);
      final configurations = [
        for (final (index, copy) in [content.$1, content.$2].indexed)
          SlideTestHarness.createConfiguration(
            _slide(key: 'redirect-$index', heroContent: copy),
          ),
      ];
      final router = GoRouter(
        initialLocation: '/slides/0',
        routes: [
          GoRoute(
            path: '/slides/:index',
            pageBuilder: (_, state) {
              final index = int.parse(state.pathParameters['index']!);
              return CustomTransitionPage<void>(
                key: ValueKey('slide-$index'),
                transitionDuration: _transitionDuration,
                child: _SlideRoute(configuration: configurations[index]),
                transitionsBuilder: (_, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Page replacement (router.go), unlike push/pop, rebuilds the shuttle
      // when redirected while the old endpoints still have placeholders.
      for (final index in [1, 0, 1, 0, 1]) {
        router.go('/slides/$index');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull);
        expect(_anyShuttleFinder(), findsWidgets);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(_anyShuttleFinder(), findsNothing);
      expect(find.byType(Hero), findsOneWidget);
    });
  }

  testWidgets(
    'text Hero interpolates typography between different block frames',
    (tester) async {
      _setSlideViewport(tester);
      final from = _slide(
        key: 'text-hero-from',
        heroContent: '# $_heroText {.shared-text}',
      );
      final to = _slide(
        key: 'text-hero-to',
        heroContent: '### $_heroText {.shared-text}',
        constrainHero: true,
      );

      await _pumpHeroRoutes(tester, from: from, to: to);

      final routeText = _routeTextFinder(_heroText);
      final fromSize = tester.getSize(routeText);
      final fromFontSize = tester.widget<Text>(routeText).style!.fontSize!;

      _navigateToNextSlide(tester);
      await tester.pump();
      await tester.pump(_transitionDuration ~/ 2);

      expect(tester.takeException(), isNull);
      final shuttle = find.byType(FittedBox).first;
      final shuttleSize = tester.getSize(shuttle);
      final paragraphs = tester
          .widgetList<RichText>(_anyShuttleFinder())
          .toList();
      expect(paragraphs, isNotEmpty);
      expect(paragraphs.first.text.toPlainText(), _heroText);

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final toSize = tester.getSize(routeText);
      final toFontSize = tester.widget<Text>(routeText).style!.fontSize!;
      expect(toSize.width, lessThan(fromSize.width));
      expect(toSize.height, lessThan(fromSize.height));
      expect(shuttleSize.width, inExclusiveRange(toSize.width, fromSize.width));
      expect(
        shuttleSize.height,
        inExclusiveRange(toSize.height, fromSize.height),
      );
      expect(toFontSize, lessThan(fromFontSize));
    },
  );

  testWidgets(
    'whole-text Hero keeps last glyph visible',
    (tester) async {
      _setSlideViewport(tester);
      await _pumpHeroRoutes(
        tester,
        from: _slide(
          key: 'whole-from',
          heroContent: '# Hello World {.shared-text}',
        ),
        to: _slide(
          key: 'whole-to',
          heroContent: '# Hello Friend {.shared-text}',
        ),
        fromStyle: _h1Style(fontSize: 96, color: Colors.white),
        toStyle: _h1Style(fontSize: 36, color: Colors.red),
      );
      _navigateToNextSlide(tester);
      await tester.pump();
      for (var frame = 1; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        final layers = find.byType(FittedBox);
        expect(layers, findsAtLeastNWidgets(1));
        for (final element in layers.evaluate()) {
          final layer = find.byElementPredicate(
            (candidate) => candidate == element,
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: layer, matching: find.byType(RichText)),
          );
          final copy = paragraph.text.toPlainText();
          expect(copy, isIn(['Hello World', 'Hello Friend']));
          final lastGlyph = paragraph
              .getBoxesForSelection(
                TextSelection(
                  baseOffset: copy.length - 1,
                  extentOffset: copy.length,
                ),
              )
              .single
              .toRect();
          final global = MatrixUtils.transformRect(
            paragraph.getTransformTo(null),
            lastGlyph,
          );
          // Glyph selection bounds can overhang the typographic advance by a
          // fraction of a pixel (0.13 px in Ahem). This is not a clipped line.
          final bounds = tester.getRect(layer).inflate(0.5);
          expect(
            bounds.contains(global.topLeft),
            isTrue,
            reason: 'frame $frame: $copy glyph $global inside $bounds',
          );
          expect(
            bounds.contains(global.bottomRight),
            isTrue,
            reason: 'frame $frame: $copy glyph $global inside $bounds',
          );
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(find.byType(FittedBox), findsNothing);
      expect(_routeTextFinder('Hello Friend'), findsOneWidget);
    },
    skip: const bool.fromEnvironment(
      'SUPERDECK_ANIMATE_HERO_TEXT',
      defaultValue: true,
    ),
  );

  testWidgets('image Hero interpolates its constraint-derived block size', (
    tester,
  ) async {
    _setSlideViewport(tester);
    final from = _slide(
      key: 'image-hero-from',
      heroContent: '![Hero image]($_imageUri){.shared-image}',
    );
    final to = _slide(
      key: 'image-hero-to',
      heroContent: '![Hero image]($_imageUri){.shared-image}',
      constrainHero: true,
    );

    await _pumpHeroRoutes(tester, from: from, to: to);

    final fromData = _imageHeroData(tester).single;

    _navigateToNextSlide(tester);
    await tester.pump();

    final routeData = _imageHeroData(tester, skipOffstage: false);
    final toData = routeData.singleWhere((data) => data.size != fromData.size);
    expect(toData.size.width, lessThan(fromData.size.width));
    expect(toData.size.height, lessThan(fromData.size.height));

    await tester.pump(_transitionDuration ~/ 2);

    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_imageHeroData(tester).single.size, toData.size);
  });

  testWidgets('untagged Markdown and widget images fly by slide order', (
    tester,
  ) async {
    _setSlideViewport(tester);
    final from = Slide(
      key: 'automatic-images-from',
      sections: [
        SectionBlock([
          ContentBlock('![First]($_imageUri)'),
          WidgetBlock(
            name: 'image',
            args: {'src': 'https://example.com/second.png'},
          ),
        ]),
      ],
    );
    final to = Slide(
      key: 'automatic-images-to',
      sections: [
        SectionBlock([
          WidgetBlock(
            name: 'image',
            args: {'src': 'https://example.com/third.png'},
          ),
        ]),
        SectionBlock([
          ContentBlock('![Fourth](https://example.com/fourth.png)'),
        ]),
      ],
    );

    await _pumpHeroRoutes(tester, from: from, to: to);
    expect(_imageHeroTags(tester), {'superdeck:image:0', 'superdeck:image:1'});

    _navigateToNextSlide(tester);
    await tester.pump();
    await tester.pump(_transitionDuration ~/ 2);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_imageHeroTags(tester), {'superdeck:image:0', 'superdeck:image:1'});
    expect(
      _imageHeroData(tester).map((image) => image.uri.toString()).toSet(),
      {'https://example.com/third.png', 'https://example.com/fourth.png'},
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(_transitionDuration ~/ 2);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(_imageHeroTags(tester), {'superdeck:image:0', 'superdeck:image:1'});
  });

  testWidgets('explicit image Hero tags override their automatic positions', (
    tester,
  ) async {
    _setSlideViewport(tester);
    await SlideTestHarness.pumpSlide(
      tester,
      Slide(
        key: 'explicit-image-tags',
        sections: [
          SectionBlock([
            ContentBlock(
              'Inline ![icon]($_imageUri) stays text.\n\n'
              '![First]($_imageUri) {.chosen}\n\n'
              '![Second](https://example.com/second.png)',
            ),
            WidgetBlock(
              name: 'image',
              args: {'src': 'https://example.com/third.png'},
            ),
          ]),
        ],
      ),
    );
    expect(_imageHeroTags(tester), {
      'chosen',
      'superdeck:image:1',
      'superdeck:image:2',
    });
  });

  testWidgets('static slide capture excludes automatic image Heroes', (
    tester,
  ) async {
    await SlideTestHarness.pumpSlide(
      tester,
      Slide(
        key: 'static-images',
        sections: [
          SectionBlock([
            ContentBlock('![Markdown]($_imageUri)'),
            WidgetBlock(
              name: 'image',
              args: {'src': 'https://example.com/widget.png'},
            ),
          ]),
        ],
      ),
      isStaticRendering: true,
    );

    expect(find.byType(Hero), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nested standalone images take no automatic Hero position', (
    tester,
  ) async {
    _setSlideViewport(tester);
    final from = Slide(
      key: 'nested-images-from',
      sections: [
        SectionBlock([
          ContentBlock('> ![Quoted](https://example.com/a.png)'),
          ContentBlock('> [!NOTE]\n> ![Alerted](https://example.com/b.png)'),
          ContentBlock('- ![Listed](https://example.com/c.png)'),
          ContentBlock('![Top](https://example.com/d.png)'),
        ]),
      ],
    );
    final to = Slide(
      key: 'nested-images-to',
      sections: [
        SectionBlock([ContentBlock('![Next]($_imageUri)')]),
      ],
    );

    await _pumpHeroRoutes(tester, from: from, to: to);
    expect(find.byType(Hero), findsOneWidget);
    expect(_imageHeroTags(tester), {'superdeck:image:0'});
    // List items render only their text, so the listed image never mounts.
    expect(find.byType(CachedImage), findsNWidgets(3));

    _navigateToNextSlide(tester);
    await tester.pump();
    await tester.pump(_transitionDuration ~/ 2);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit image Hero tags still apply inside a blockquote', (
    tester,
  ) async {
    await SlideTestHarness.pumpSlide(
      tester,
      Slide(
        key: 'quoted-explicit-tag',
        sections: [
          SectionBlock([ContentBlock('> ![Quoted]($_imageUri) {.chosen}')]),
        ],
      ),
    );

    expect(_imageHeroTags(tester), {'chosen'});
  });

  testWidgets('animateImages false keeps only explicit image Heroes', (
    tester,
  ) async {
    SlideConfiguration still(Slide slide) =>
        SlideTestHarness.createConfiguration(
          slide,
        ).copyWith(animateImages: false);

    await SlideTestHarness.pumpConfiguration(
      tester,
      still(
        Slide(
          key: 'still-images',
          sections: [
            SectionBlock([
              ContentBlock('![Markdown]($_imageUri)'),
              WidgetBlock(
                name: 'image',
                args: {'src': 'https://example.com/widget.png'},
              ),
            ]),
          ],
        ),
      ),
    );
    expect(find.byType(Hero), findsNothing);
    expect(find.byType(CachedImage), findsNWidgets(2));

    await SlideTestHarness.pumpConfiguration(
      tester,
      still(
        Slide(
          key: 'still-explicit-image',
          sections: [
            SectionBlock([ContentBlock('![Chosen]($_imageUri) {.chosen}')]),
          ],
        ),
      ),
    );
    expect(_imageHeroTags(tester), {'chosen'});
  });

  testWidgets('image flight follows the rendered Hero frame', (tester) async {
    _setSlideViewport(tester);
    final from = Slide(
      key: 'sized-image-from',
      sections: [
        SectionBlock([
          WidgetBlock(
            name: 'image',
            args: {'src': _imageUri, 'width': 120, 'height': 80},
          ),
        ]),
      ],
    );
    final to = Slide(
      key: 'sized-image-to',
      sections: [
        SectionBlock([
          WidgetBlock(
            name: 'image',
            args: {'src': _imageUri, 'width': 240, 'height': 160},
          ),
        ]),
      ],
    );
    await _pumpHeroRoutes(tester, from: from, to: to);

    final fromSize = tester.getSize(find.byType(Hero));
    expect(fromSize.width, 120);
    expect(fromSize.height, 80);
    _navigateToNextSlide(tester);
    await tester.pump();
    await tester.pump(_transitionDuration ~/ 2);

    final flightSize = tester.getSize(
      find.byKey(const ValueKey('image-hero-flight')),
    );
    expect(flightSize.width, greaterThan(fromSize.width));
    expect(flightSize.height, greaterThan(fromSize.height));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    final toSize = tester.getSize(find.byType(Hero));
    expect(toSize.width, 240);
    expect(toSize.height, 160);
    expect(flightSize.width, lessThan(toSize.width));
    expect(flightSize.height, lessThan(toSize.height));
  });

  testWidgets('image shuttle uses overlay bounds over stale block dimensions', (
    tester,
  ) async {
    final from = ImageElement(
      spec: const ImageSpec(),
      uri: Uri.parse(_imageUri),
      size: const Size(120, 540),
      flightImage: const ColoredBox(color: Colors.red),
    );
    final to = ImageElement(
      spec: const ImageSpec(),
      uri: Uri.parse(_imageUri),
      size: const Size(240, 540),
      flightImage: const ColoredBox(color: Colors.blue),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 180,
            height: 120,
            child: Builder(
              builder: (context) =>
                  buildImageHeroFlight(context, from, to, 0.5),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('image-hero-flight'))),
      const Size(180, 120),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'text Hero blends resolved endpoint styles without changing layout',
    (tester) async {
      _setSlideViewport(tester);
      const fromColor = Color(0xFFFFFFFF);
      const toColor = Color(0xFFFF0000);
      const fromFontSize = 64.0;
      const toFontSize = 24.0;

      final from = _slide(
        key: 'mix-hero-from',
        heroContent: '# $_heroText {.shared-text}',
      );
      final to = _slide(
        key: 'mix-hero-to',
        heroContent: '# $_heroText {.shared-text}',
      );

      await _pumpHeroRoutes(
        tester,
        from: from,
        to: to,
        fromStyle: _h1Style(fontSize: fromFontSize, color: fromColor),
        toStyle: _h1Style(fontSize: toFontSize, color: toColor),
      );

      final routeText = _routeTextFinder(_heroText);
      expect(tester.widget<Text>(routeText).style!.fontSize, fromFontSize);
      expect(tester.widget<Text>(routeText).style!.color, fromColor);

      _navigateToNextSlide(tester);
      await tester.pump();
      await tester.pump(_transitionDuration * 0.35);

      expect(tester.takeException(), isNull);
      final paragraphs = tester
          .widgetList<RichText>(_anyShuttleFinder())
          .toList();
      expect(paragraphs, hasLength(2));
      expect(paragraphs.map((p) => p.text.style!.fontSize), [
        fromFontSize,
        toFontSize,
      ]);
      expect(paragraphs.map((p) => p.text.style!.color), [fromColor, toColor]);
      final layers = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(IgnorePointer),
          matching: find.byType(Opacity),
        ),
      );
      expect(
        layers.where((layer) => layer.opacity > 0 && layer.opacity < 1),
        isNotEmpty,
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(routeText).style!.fontSize, toFontSize);
      expect(tester.widget<Text>(routeText).style!.color, toColor);
    },
  );

  testWidgets(
    'changed paragraph copy backspaces then types with inline styles',
    (tester) async {
      _setSlideViewport(tester);
      await _pumpHeroRoutes(
        tester,
        from: _slide(
          key: 'paragraph-from',
          heroContent: 'Good transitions preserve **every word**. {.paragraph}',
        ),
        to: _slide(
          key: 'paragraph-to',
          heroContent: 'A narrower column tells **a new story**. {.paragraph}',
          constrainHero: true,
        ),
      );
      _navigateToNextSlide(tester);
      await tester.pump();
      await tester.pump(_transitionDuration * 0.25);
      final outgoing = tester.widget<RichText>(_anyShuttleFinder());
      expect(_visibleRichText(outgoing), startsWith('Good'));
      expect(
        _visibleRichText(outgoing).length,
        _animateHeroText
            ? lessThan(outgoing.text.toPlainText().length)
            : outgoing.text.toPlainText().length,
      );
      await tester.pump(_transitionDuration * 0.5);
      final incoming = tester.widget<RichText>(_anyShuttleFinder());
      expect(_visibleRichText(incoming), startsWith('A narrower'));
      expect(
        _visibleRichText(incoming).length,
        _animateHeroText
            ? lessThan(incoming.text.toPlainText().length)
            : incoming.text.toPlainText().length,
      );
      await tester.pumpAndSettle();
      expect(_anyShuttleFinder(), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('code reveal preserves complete highlighted layouts and reverses', (
    tester,
  ) async {
    _setSlideViewport(tester);
    const source = 'final title = "Hello";\nprint(title);';
    const destination =
        'final slides = ["Hello", "World"];\nfor (final slide in slides) {\n  print(slide);\n}';
    await _pumpHeroRoutes(
      tester,
      from: _slide(
        key: 'code-from',
        heroContent: '```dart {.code}\n$source\n```',
      ),
      to: _slide(
        key: 'code-to',
        heroContent: '```dart {.code}\n$destination\n```',
        constrainHero: true,
      ),
    );
    _navigateToNextSlide(tester);
    await tester.pump();
    await tester.pump(_transitionDuration * 0.25);
    final outgoing = tester.widget<RichText>(_anyShuttleFinder());
    expect(outgoing.text.toPlainText(), source);
    expect(_visibleRichText(outgoing), startsWith('final '));
    expect(
      _visibleRichText(outgoing),
      _animateHeroText ? isNot(contains('print')) : source,
    );
    await tester.pump(_transitionDuration * 0.1);
    final panels = find.byWidgetPredicate(
      (widget) =>
          widget is Stack &&
          widget.children.any((child) => child is Box) &&
          widget.children.any((child) => child is Opacity),
    );
    expect(panels, findsOneWidget);
    final panel = tester.widget<Stack>(panels);
    expect(panel.children.whereType<Box>(), hasLength(1));
    expect(panel.children.whereType<Opacity>(), hasLength(2));
    await tester.pump(_transitionDuration * 0.4);
    final incoming = tester.widget<RichText>(_anyShuttleFinder());
    expect(incoming.text.toPlainText(), destination);
    expect(_visibleRichText(incoming), startsWith('final slides'));
    expect(
      _visibleRichText(incoming).length,
      _animateHeroText ? lessThan(destination.length) : destination.length,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(_transitionDuration * 0.25);
    expect(
      tester.widget<RichText>(_anyShuttleFinder()).text.toPlainText(),
      destination,
    );
    await tester.pump(_transitionDuration * 0.5);
    expect(
      tester.widget<RichText>(_anyShuttleFinder()).text.toPlainText(),
      source,
    );
    await tester.pumpAndSettle();
    expect(_anyShuttleFinder(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('different image sources blend in both navigation directions', (
    tester,
  ) async {
    _setSlideViewport(tester);
    await _pumpHeroRoutes(
      tester,
      from: _slide(key: 'image-a', heroContent: '![A]($_imageUri) {.visual}'),
      to: _slide(
        key: 'image-b',
        heroContent: '![B](https://example.com/other.png) {.visual}',
      ),
    );
    Future<void> checkBlend() async {
      await tester.pump();
      await tester.pump(_transitionDuration ~/ 2);
      final layers = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((layer) => layer.child is CachedImage)
          .toList();
      expect(layers, hasLength(2));
      for (final layer in layers) {
        expect(layer.opacity, inExclusiveRange(0, 1));
      }
      expect(
        layers.map((layer) => (layer.child as CachedImage).uri).toSet(),
        hasLength(2),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    _navigateToNextSlide(tester);
    await checkBlend();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await checkBlend();
  });

  testWidgets(
    'static rendering skips the Hero shuttle so capture cannot record it',
    (tester) async {
      _setSlideViewport(tester);
      final from = _slide(
        key: 'static-hero-from',
        heroContent: '# $_heroText {.shared-text}',
      );
      final to = _slide(
        key: 'static-hero-to',
        heroContent: '# $_heroText {.shared-text}',
        constrainHero: true,
      );

      await _pumpHeroRoutes(
        tester,
        from: from,
        to: to,
        isStaticRendering: true,
      );

      expect(_routeTextFinder(_heroText), findsOneWidget);

      _navigateToNextSlide(tester);
      await tester.pump();
      await tester.pump(_transitionDuration ~/ 2);

      expect(tester.takeException(), isNull);
      expect(_shuttleTextFinder(_heroText), findsNothing);

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_shuttleTextFinder(_heroText), findsNothing);
      expect(_routeTextFinder(_heroText), findsOneWidget);
    },
  );

  testWidgets('text Hero backspaces and types within fixed endpoint layouts', (
    tester,
  ) async {
    _setSlideViewport(tester);
    const fromColor = Color(0xFFFFFFFF);
    const toColor = Color(0xFFFF0000);
    const fromFontSize = 64.0;
    const toFontSize = 24.0;
    const fromCopy = 'Hello World';
    const toCopy = 'Hello Friend';

    await _pumpHeroRoutes(
      tester,
      from: _slide(
        key: 'hero-out-from',
        heroContent: '# $fromCopy {.shared-text}',
      ),
      to: _slide(key: 'hero-in-to', heroContent: '# $toCopy {.shared-text}'),
      fromStyle: _h1Style(fontSize: fromFontSize, color: fromColor),
      toStyle: _h1Style(fontSize: toFontSize, color: toColor),
    );

    expect(_routeTextFinder(fromCopy), findsOneWidget);
    expect(_routeTextFinder(toCopy), findsNothing);

    _navigateToNextSlide(tester);
    await tester.pump();
    await tester.pump(_transitionDuration * 0.25);

    expect(tester.takeException(), isNull);
    final outShuttle = tester.widget<RichText>(_anyShuttleFinder());
    final outVisible = _visibleRichText(outShuttle);
    expect(
      outVisible,
      contains('Wo'),
      reason: 't=0.25 is the out phase: start suffix must still be visible',
    );
    expect(
      outVisible.contains('Fri'),
      isFalse,
      reason: 'incoming suffix must not appear during fade-out',
    );
    expect(outShuttle.text.toPlainText(), fromCopy);
    expect(outShuttle.text.style!.fontSize, fromFontSize);

    await tester.pump(_transitionDuration * 0.5);

    expect(tester.takeException(), isNull);
    final inShuttle = tester.widget<RichText>(_anyShuttleFinder());
    final inVisible = _visibleRichText(inShuttle);
    expect(
      inVisible,
      contains('Fri'),
      reason: 't=0.75 is the in phase: end suffix must be visible',
    );
    expect(
      inVisible.contains('World'),
      isFalse,
      reason: 'outgoing suffix must be gone during fade-in',
    );
    expect(inShuttle.text.toPlainText(), toCopy);
    expect(inShuttle.text.style!.fontSize, toFontSize);

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_routeTextFinder(toCopy), findsOneWidget);
    expect(_routeTextFinder(fromCopy), findsNothing);
    expect(_anyShuttleFinder(), findsNothing);
  });
}

Slide _slide({
  required String key,
  required String heroContent,
  bool constrainHero = false,
}) {
  final heroBlock = ContentBlock(heroContent, align: ContentAlignment.center);
  if (!constrainHero) {
    return Slide(
      key: key,
      sections: [
        SectionBlock([heroBlock]),
      ],
    );
  }

  return Slide(
    key: key,
    sections: [
      SectionBlock([heroBlock, ContentBlock('Side')]),
      SectionBlock([ContentBlock('Below')]),
    ],
  );
}

SlideStyler _h1Style({required double fontSize, required Color color}) {
  return defaultSlideStyle.merge(
    SlideStyler(
      h1: TextStyler().style(TextStyleMix(fontSize: fontSize, color: color)),
    ),
  );
}

Future<void> _pumpHeroRoutes(
  WidgetTester tester, {
  required Slide from,
  required Slide to,
  SlideStyler? fromStyle,
  SlideStyler? toStyle,
  bool isStaticRendering = false,
}) async {
  final fromConfiguration = SlideTestHarness.createConfiguration(
    from,
    style: fromStyle,
    isStaticRendering: isStaticRendering,
  );
  final toConfiguration = SlideTestHarness.createConfiguration(
    to,
    style: toStyle,
    isStaticRendering: isStaticRendering,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: _SlideRoute(configuration: fromConfiguration),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        transitionDuration: _transitionDuration,
        reverseTransitionDuration: _transitionDuration,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _SlideRoute(configuration: toConfiguration),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _navigateToNextSlide(WidgetTester tester) {
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
}

Finder _routeTextFinder(String text) =>
    find.byWidgetPredicate((widget) => widget is Text && widget.data == text);

Finder _shuttleTextFinder(String text) => find.descendant(
  of: find.byType(FittedBox),
  matching: find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText() == text,
  ),
);

Finder _anyShuttleFinder() => find.descendant(
  of: find.byType(FittedBox),
  matching: find.byType(RichText),
);

String _visibleRichText(RichText text) {
  final buffer = StringBuffer();
  void walk(InlineSpan span, double parentAlpha) {
    if (span is! TextSpan) return;
    final alpha = span.style?.color?.a ?? parentAlpha;
    if (span.text != null && alpha > 0.01) buffer.write(span.text);
    for (final child in span.children ?? const <InlineSpan>[]) {
      walk(child, alpha);
    }
  }

  walk(text.text, 1);
  return buffer.toString();
}

List<ImageElement> _imageHeroData(
  WidgetTester tester, {
  bool skipOffstage = true,
}) {
  return tester
      .widgetList<HeroElement<ImageElement>>(
        find.byWidgetPredicate(
          (widget) => widget is HeroElement<ImageElement>,
          skipOffstage: skipOffstage,
        ),
      )
      .map((element) => element.data)
      .toList();
}

Set<String> _imageHeroTags(WidgetTester tester) => tester
    .widgetList<Hero>(find.byType(Hero))
    .map((hero) => hero.tag.toString())
    .toSet();

void _setSlideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _SlideRoute extends StatelessWidget {
  const _SlideRoute({required this.configuration});

  final SlideConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InheritedData(data: configuration, child: SlideView(configuration)),
    );
  }
}
