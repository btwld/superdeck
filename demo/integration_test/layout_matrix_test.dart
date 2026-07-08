import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('layout and feature matrix', () {
    setUpAll(TestApp.initialize);

    testWidgets('renders every authored matrix slide without app errors', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1280, 720)
        ..devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });

      final liveNetwork = _liveNetworkEnabled;
      final localImage = await createLocalPngFixture();
      final slides = _layoutMatrixSlides(
        localImage: localImage,
        includeLiveNetwork: liveNetwork,
      );

      final controller = await tester.pumpTestAppWithSlides(
        slides,
        extraWidgets: _matrixWidgets,
      );

      expect(controller.presentation.totalSlides.value, slides.length);

      for (var index = 0; index < slides.length; index++) {
        await tester.navigateToSlide(
          controller,
          index,
          context: 'layout matrix slide $index',
        );
        expect(controller.presentation.currentSlide.value?.slideIndex, index);
        expect(
          controller.presentation.currentSlide.value?.slide.key,
          slides[index].key,
        );
        assertNoFlutterException(tester);
        assertNoRenderedPresentationErrors(tester);
      }

      final screenshotsDir = await captureAllSlidesForReview(
        tester,
        controller,
        suiteName: 'layout_matrix',
        scenarioName: 'layout_matrix',
      );
      await assertReviewScreenshots(
        outputDir: screenshotsDir,
        expectedCount: slides.length,
      );
    });

    testWidgets('content and widget scrollables move after drag', (
      tester,
    ) async {
      final localImage = await createLocalPngFixture();
      final slides = _layoutMatrixSlides(localImage: localImage);
      final controller = await tester.pumpTestAppWithSlides(
        slides,
        extraWidgets: _matrixWidgets,
      );

      await tester.navigateToSlide(
        controller,
        _indexOf(slides, 'scrollable-content'),
        context: 'scrollable content slide',
      );
      await tester.assertScrollableMoves(find.byType(SingleChildScrollView));

      await tester.navigateToSlide(
        controller,
        _indexOf(slides, 'scrollable-widget'),
        context: 'scrollable widget slide',
      );
      await tester.assertScrollableMoves(find.byType(SingleChildScrollView));
    });

    testWidgets(
      'non-scrollable overflow block is not wrapped in a scrollable',
      (tester) async {
        final localImage = await createLocalPngFixture();
        final slides = _layoutMatrixSlides(localImage: localImage);
        final controller = await tester.pumpTestAppWithSlides(
          slides,
          extraWidgets: _matrixWidgets,
        );

        await tester.navigateToSlide(
          controller,
          _indexOf(slides, 'non-scrollable-overflow'),
          context: 'non-scrollable overflow slide',
        );

        expect(find.byType(SingleChildScrollView), findsNothing);
        assertNoFlutterException(tester);
        assertNoRenderedPresentationErrors(tester);
      },
    );

    testWidgets('local image path modes render without image errors', (
      tester,
    ) async {
      final localImage = await createLocalPngFixture();
      final slides = _layoutMatrixSlides(localImage: localImage);
      final controller = await tester.pumpTestAppWithSlides(
        slides,
        extraWidgets: _matrixWidgets,
      );

      await tester.navigateToSlide(
        controller,
        _indexOf(slides, 'image-source-matrix'),
        context: 'local image source matrix',
      );
      await tester.pumpFor(const Duration(seconds: 1));

      expect(find.textContaining('Error loading image:'), findsNothing);
      assertNoFlutterException(tester);
    });

    testWidgets('remote image and DartPad canary stays healthy when enabled', (
      tester,
    ) async {
      if (!_liveNetworkEnabled) {
        return;
      }

      final localImage = await createLocalPngFixture();
      final slides = _layoutMatrixSlides(
        localImage: localImage,
        includeLiveNetwork: true,
      );
      final controller = await tester.pumpTestAppWithSlides(
        slides,
        extraWidgets: _matrixWidgets,
      );

      await tester.navigateToSlide(
        controller,
        _indexOf(slides, 'remote-image-matrix'),
        context: 'remote image matrix',
      );
      await tester.pumpFor(const Duration(seconds: 3));
      expect(find.textContaining('Error loading image:'), findsNothing);
      assertNoFlutterException(tester);

      await tester.navigateToSlide(
        controller,
        _indexOf(slides, 'dartpad-webview'),
        context: 'DartPad WebView canary',
      );
      await tester.pumpFor(const Duration(seconds: 2));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
      assertNoFlutterException(tester);
    });

    testWidgets('notes panel shows authored comments', (tester) async {
      final localImage = await createLocalPngFixture();
      final slides = _layoutMatrixSlides(localImage: localImage);
      final controller = await tester.pumpTestAppWithSlides(
        slides,
        extraWidgets: _matrixWidgets,
      );

      await tester.navigateToSlide(
        controller,
        _indexOf(slides, 'speaker-notes'),
        context: 'speaker notes slide',
      );
      expect(
        controller.presentation.currentSlide.value?.comments,
        contains('First note from the matrix deck.'),
      );
      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.presentation.isMenuOpen.value,
        debugLabel: 'menu opens for notes',
      );
      await tester.pumpFor(const Duration(milliseconds: 300));
      await tester.tapByLabel('Open notes panel');
      await tester.pumpUntil(
        () => controller.presentation.isNotesOpen.value,
        debugLabel: 'notes panel opens',
      );
      await tester.pumpFor(const Duration(milliseconds: 300));

      expect(
        find.textContaining('First note from the matrix deck'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Second note from the matrix deck'),
        findsOneWidget,
      );
      assertNoFlutterException(tester);
    });

    testWidgets('custom widget registration overrides built-ins', (
      tester,
    ) async {
      final controller = await tester.pumpTestAppWithSlides(
        [
          Slide(
            key: 'override-image',
            sections: [
              SectionBlock([
                WidgetBlock(
                  name: 'image',
                  args: {'src': transparentPixelDataUri},
                ),
              ]),
            ],
          ),
        ],
        extraWidgets: {'image': _overrideImageWidget},
      );

      await tester.navigateToSlide(
        controller,
        0,
        context: 'image override slide',
      );

      expect(find.text('Overridden image widget'), findsOneWidget);
      assertNoFlutterException(tester);
    });

    testWidgets('intentional error states render controlled error UI', (
      tester,
    ) async {
      final controller = await tester.pumpTestAppWithSlides([
        Slide(
          key: 'unknown-widget-error',
          sections: [
            SectionBlock([WidgetBlock(name: 'missing-widget')]),
          ],
        ),
        Slide(
          key: 'broken-image-error',
          sections: [
            SectionBlock([
              WidgetBlock(
                name: 'image',
                args: {'src': 'file:///definitely/missing/superdeck.png'},
              ),
            ]),
          ],
        ),
        Slide(
          key: 'escaped-directive',
          sections: [
            SectionBlock([
              ContentBlock(
                '_@block {align: center}\n\nThis line stays markdown text.',
              ),
            ]),
          ],
        ),
      ]);

      await tester.navigateToSlide(
        controller,
        0,
        context: 'unknown widget error slide',
      );
      expect(find.textContaining('Widget not found:'), findsOneWidget);

      await tester.navigateToSlide(
        controller,
        1,
        context: 'broken image error slide',
      );
      await tester.pumpFor(const Duration(seconds: 1));
      expect(find.textContaining('Error loading image:'), findsOneWidget);

      await tester.navigateToSlide(
        controller,
        2,
        context: 'escaped directive slide',
      );
      expect(find.textContaining('_@block {align: center}'), findsOneWidget);
      assertNoFlutterException(tester);
    });
  });
}

bool get _liveNetworkEnabled =>
    Platform.environment['SUPERDECK_LIVE_NETWORK'] == '1';

const _remotePng = 'https://httpbin.org/image/png';
const _remoteJpg = 'https://httpbin.org/image/jpeg';

final Map<String, WidgetFactory> _matrixWidgets = {
  'mix-animation': (_) => const _FiniteMixAnimationWidget(),
  'tall-test-widget': (_) => const _TallTestWidget(),
};

Widget _overrideImageWidget(Map<String, Object?> args) {
  return const Center(child: Text('Overridden image widget'));
}

int _indexOf(List<Slide> slides, String key) {
  return slides.indexWhere((slide) => slide.key == key);
}

List<Slide> _layoutMatrixSlides({
  required LocalImageFixture localImage,
  bool includeLiveNetwork = false,
}) {
  final slides = <Slide>[
    Slide(
      key: 'plain-markdown',
      sections: [
        SectionBlock([
          ContentBlock('''
# Markdown Coverage

Paragraph with *emphasis*, **strong text**, `inline code`, and [a link](https://example.com).

- Bullet one
- Bullet two

1. Ordered one
2. Ordered two

- [x] Completed task
- [ ] Open task

> Blockquote with nested **markdown**.

---

| Name | Value |
| --- | ---: |
| Alpha | 1 |

```dart
void main() {
  print('matrix');
}
```
'''),
        ]),
      ],
    ),
    Slide(
      key: 'github-alerts',
      sections: [
        SectionBlock([
          ContentBlock('''
> [!NOTE]
> Useful note content.

> [!TIP]
> Tip content with `inline code`.

> [!IMPORTANT]
> Important content with nested markdown:
> - one
> - two

> [!WARNING]
> Warning content.

> [!CAUTION]
> Caution content.
'''),
        ]),
      ],
    ),
    Slide(
      key: 'single-column',
      sections: [
        _section([_content('Single column content block.')]),
      ],
    ),
    Slide(
      key: 'two-column-equal',
      sections: [
        _section([_content('Left 1'), _content('Right 1')]),
      ],
    ),
    Slide(
      key: 'two-column-1-2',
      sections: [
        _section([_content('Narrow'), _content('Wide')], flex: [1, 2]),
      ],
    ),
    Slide(
      key: 'two-column-2-1',
      sections: [
        _section([_content('Wide'), _content('Narrow')], flex: [2, 1]),
      ],
    ),
    Slide(
      key: 'two-column-1-10',
      sections: [
        _section([_content('Rail'), _content('Main area')], flex: [1, 10]),
      ],
    ),
    Slide(
      key: 'three-column-equal',
      sections: [
        _section([_content('One'), _content('Two'), _content('Three')]),
      ],
    ),
    Slide(
      key: 'three-column-1-2-1',
      sections: [
        _section(
          [_content('Left'), _content('Center'), _content('Right')],
          flex: [1, 2, 1],
        ),
      ],
    ),
    Slide(
      key: 'multi-section',
      sections: [
        _section([_content('Top section')], sectionFlex: 1),
        _section([_content('Bottom section with more room')], sectionFlex: 2),
      ],
    ),
    Slide(
      key: 'header-body-footer',
      sections: [
        _section([_content('Header')], sectionFlex: 1),
        _section([_content('Body content')], sectionFlex: 3),
        _section([_content('Footer')], sectionFlex: 1),
      ],
    ),
    Slide(
      key: 'mixed-sections-columns',
      sections: [
        _section(
          [_content('Top left'), _content('Top center'), _content('Top right')],
          flex: [1, 2, 1],
          sectionFlex: 3,
        ),
        _section([_content('Lower callout and footer')], sectionFlex: 1),
      ],
    ),
    _alignmentGridSlide(),
    Slide(
      key: 'scrollable-content',
      sections: [
        SectionBlock([
          ContentBlock(
            List.generate(
              80,
              (index) => '- Long markdown row $index',
            ).join('\n'),
            scrollable: true,
          ),
        ]),
      ],
    ),
    Slide(
      key: 'scrollable-widget',
      sections: [
        SectionBlock([WidgetBlock(name: 'tall-test-widget', scrollable: true)]),
      ],
    ),
    Slide(
      key: 'non-scrollable-overflow',
      sections: [
        SectionBlock([
          ContentBlock(
            List.generate(
              80,
              (index) => '- Clipped markdown row $index',
            ).join('\n'),
            scrollable: false,
          ),
        ]),
      ],
    ),
    Slide(
      key: 'image-source-matrix',
      sections: [
        _section([
          _image(transparentPixelDataUri, label: 'data-uri'),
          _image('assets/concepta-icon.png', label: 'asset'),
          _image(localImage.relativePath, label: 'relative'),
        ]),
        _section([
          _image(localImage.absolutePath, label: 'absolute'),
          _image(localImage.fileUri, label: 'file-uri'),
        ]),
      ],
    ),
    _imageLayoutMatrixSlide(localImage),
    Slide(
      key: 'qr-code',
      sections: [
        SectionBlock([
          WidgetBlock(
            name: 'qrcode',
            args: {
              'text': 'https://superdeck.dev',
              'size': 220,
              'errorCorrection': 'highest',
              'foregroundColor': '#102030',
              'backgroundColor': '#F8F8F8',
            },
          ),
        ]),
      ],
    ),
    Slide(
      key: 'custom-demo-widgets',
      sections: [
        _section([
          WidgetBlock(name: 'mix-simple-box'),
          WidgetBlock(name: 'mix-variants'),
          WidgetBlock(name: 'mix-animation'),
        ], sectionFlex: 2),
        _section([
          WidgetBlock(name: 'naked-select'),
          WidgetBlock(name: 'remix-button'),
        ], sectionFlex: 1),
      ],
    ),
    Slide(
      key: 'named-style',
      sections: [
        _section([_content('Deck-level named style.')]),
      ],
      options: SlideOptions(style: 'announcement'),
    ),
    Slide(
      key: 'style-template-corporate',
      sections: [
        _section([_content('Corporate template with visible chrome.')]),
      ],
      options: SlideOptions(template: 'corporate', style: 'highlight'),
    ),
    Slide(
      key: 'style-template-minimal',
      sections: [
        _section([_content('Minimal template.')]),
      ],
      options: SlideOptions(template: 'minimal'),
    ),
    Slide(
      key: 'template-none',
      sections: [
        _section([_content('Template none opt-out.')]),
      ],
      options: SlideOptions(template: 'none'),
    ),
    Slide(
      key: 'speaker-notes',
      sections: [
        _section([_content('Open the notes panel for this slide.')]),
      ],
      comments: const [
        'First note from the matrix deck.',
        'Second note from the matrix deck.',
      ],
    ),
    Slide(
      key: 'hero-before',
      sections: [
        _section([
          ContentBlock('''
# Shared Hero Title {.shared-heading}

![Shared local image](${localImage.fileUri}){.shared-image}

```dart {.shared-code}
final before = 'settled';
```
'''),
        ]),
      ],
    ),
    Slide(
      key: 'hero-after',
      sections: [
        _section([
          ContentBlock('''
# Shared Hero Title {.shared-heading}

![Shared local image](${localImage.fileUri}){.shared-image}

```dart {.shared-code}
final after = 'settled';
```
'''),
        ]),
      ],
    ),
  ];

  if (includeLiveNetwork) {
    slides
      ..add(
        Slide(
          key: 'remote-image-matrix',
          sections: [
            _section([
              _image(_remotePng, label: 'remote-png'),
              _image(_remoteJpg, label: 'remote-jpg'),
            ]),
          ],
        ),
      )
      ..add(
        Slide(
          key: 'dartpad-webview',
          sections: [
            SectionBlock([
              WidgetBlock(
                name: 'dartpad',
                args: {
                  'id': 'dartpad_superdeck_matrix',
                  'theme': 'dark',
                  'embed': true,
                  'run': true,
                },
              ),
            ]),
          ],
        ),
      );
  }

  return slides;
}

Slide _alignmentGridSlide() {
  const alignments = [
    ContentAlignment.topLeft,
    ContentAlignment.topCenter,
    ContentAlignment.topRight,
    ContentAlignment.centerLeft,
    ContentAlignment.center,
    ContentAlignment.centerRight,
    ContentAlignment.bottomLeft,
    ContentAlignment.bottomCenter,
    ContentAlignment.bottomRight,
  ];

  return Slide(
    key: 'alignment-grid',
    sections: [
      _section(
        [
          for (final alignment in alignments.take(3))
            _content(alignment.name, alignment: alignment),
        ],
        flex: [1, 1, 1],
      ),
      _section(
        [
          for (final alignment in alignments.skip(3).take(3))
            _content(alignment.name, alignment: alignment),
        ],
        flex: [1, 1, 1],
      ),
      _section(
        [
          for (final alignment in alignments.skip(6))
            _content(alignment.name, alignment: alignment),
        ],
        flex: [1, 1, 1],
      ),
    ],
  );
}

Slide _imageLayoutMatrixSlide(LocalImageFixture localImage) {
  return Slide(
    key: 'image-layout-matrix',
    sections: [
      _section([
        _image(localImage.fileUri, label: 'full-slide-contain', fit: 'contain'),
      ], sectionFlex: 2),
      _section(
        [
          _image(localImage.fileUri, label: 'cover image', fit: 'cover'),
          _content('Text beside image in a two-column section.'),
        ],
        flex: [1, 1],
        sectionFlex: 1,
      ),
      _section(
        [
          _image(localImage.fileUri, label: 'fill image', fit: 'fill'),
          _image(
            localImage.fileUri,
            label: 'scaleDown image',
            fit: 'scaleDown',
          ),
          _image(
            localImage.fileUri,
            label: 'explicit size',
            fit: 'contain',
            width: 96,
            height: 96,
          ),
        ],
        flex: [1, 1, 1],
        sectionFlex: 1,
      ),
      _section([
        _image(localImage.fileUri, label: 'lower-section'),
      ], sectionFlex: 1),
    ],
  );
}

SectionBlock _section(
  List<Block> blocks, {
  List<int>? flex,
  int sectionFlex = 1,
}) {
  return SectionBlock(_applyBlockFlex(blocks, flex), flex: sectionFlex);
}

ContentBlock _content(String markdown, {ContentAlignment? alignment}) {
  return ContentBlock(markdown, align: alignment);
}

WidgetBlock _image(
  String src, {
  required String label,
  String fit = 'contain',
  double? width,
  double? height,
}) {
  return WidgetBlock(
    name: 'image',
    args: {
      'src': src,
      'fit': fit,
      'width': ?width,
      'height': ?height,
    },
  );
}

List<Block> _applyBlockFlex(List<Block> blocks, List<int>? flex) {
  if (flex == null) return blocks;
  assert(flex.length == blocks.length);

  return [
    for (var index = 0; index < blocks.length; index++)
      switch (blocks[index]) {
        ContentBlock block => ContentBlock(
          block.content,
          align: block.align,
          flex: flex[index],
          scrollable: block.scrollable,
        ),
        WidgetBlock block => WidgetBlock(
          name: block.name,
          args: block.args,
          align: block.align,
          flex: flex[index],
          scrollable: block.scrollable,
        ),
      },
  ];
}

class _TallTestWidget extends StatelessWidget {
  const _TallTestWidget();

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

class _FiniteMixAnimationWidget extends StatelessWidget {
  const _FiniteMixAnimationWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 250),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: const Text('mix-animation'),
      ),
    );
  }
}
