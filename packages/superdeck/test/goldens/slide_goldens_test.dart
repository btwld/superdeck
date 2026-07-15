import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart' show BlockStyler, SlideStyler;
import 'package:superdeck/src/builtins/image_widget.dart';
import 'package:superdeck/src/builtins/widgets.dart';
import 'package:superdeck/src/rendering/slides/slide_parts.dart';
import 'package:superdeck/src/rendering/slides/slide_view.dart';
import 'package:superdeck/src/styling/default_style.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/src/utils/constants.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../fixtures/slide_fixtures.dart';
import '../helpers/slide_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plain markdown slide', (tester) async {
    await _pumpGoldenSlide(
      tester,
      Slide(
        key: 'golden-plain-markdown',
        sections: [
          SectionBlock([
            ContentBlock('''
# Plain Markdown

This slide keeps regular markdown content together.

- Heading
- Paragraph
- List
'''),
          ]),
        ],
        options: SlideOptions(title: 'Plain Markdown'),
      ),
    );

    await expectLater(
      find.byType(SlideView),
      matchesGoldenFile('plain_markdown_slide.png'),
    );
  }, tags: ['ci-excluded', 'golden']);

  testWidgets('section with two blocks', (tester) async {
    await _pumpGoldenSlide(
      tester,
      SlideFixtures.twoColumnEqual(
        left: '''
## Left Column

Author text in the first column.
''',
        right: '''
## Right Column

Author text in the second column.
''',
      ),
    );

    await expectLater(
      find.byType(SlideView),
      matchesGoldenFile('section_two_blocks.png'),
    );
  }, tags: ['ci-excluded', 'golden']);

  testWidgets('block aligned center', (tester) async {
    await _pumpGoldenSlide(
      tester,
      SlideFixtures.withAlignment(ContentAlignment.center),
    );

    await expectLater(
      find.byType(SlideView),
      matchesGoldenFile('block_aligned_center.png'),
    );
  }, tags: ['ci-excluded', 'golden']);

  testWidgets('image fit and scale framing matrix', (tester) async {
    final sourceFile = File('../../demo/web/icons/Icon-512.png').absolute;
    final source = Uri.dataFromBytes(
      sourceFile.readAsBytesSync(),
      mimeType: 'image/png',
    ).toString();
    const frameWidth = 420.0;
    const frameHeight = 240.0;

    WidgetBlock image({required String fit, required double scale}) {
      return WidgetBlock(
        name: 'image',
        padding: BlockInsets.all(0),
        args: {
          'src': source,
          'fit': fit,
          'width': frameWidth,
          'height': frameHeight,
          'scale': scale,
        },
      );
    }

    await _pumpGoldenSlide(
      tester,
      Slide(
        key: 'golden-image-scale-framing',
        sections: [
          SectionBlock(
            [
              image(fit: 'contain', scale: 1),
              image(fit: 'contain', scale: 1.35),
            ],
            spacing: 40,
            align: ContentAlignment.center,
          ),
          SectionBlock(
            [image(fit: 'cover', scale: 1), image(fit: 'cover', scale: 1.35)],
            spacing: 40,
            align: ContentAlignment.center,
          ),
        ],
      ),
    );

    expect(sourceFile.existsSync(), isTrue);
    expect(find.byType(ImageWidget), findsNWidgets(4));
    expect(find.byType(Image), findsNWidgets(4));
    for (var index = 0; index < 4; index++) {
      expect(
        tester.getSize(find.byType(Image).at(index)),
        const Size(420, 240),
      );
    }
    expect(find.textContaining('Error loading image'), findsNothing);
    expect(tester.takeException(), isNull);

    final imageElements = find.byType(Image).evaluate().toList(growable: false);
    await tester.runAsync(() async {
      for (final element in imageElements) {
        final image = element.widget as Image;
        await precacheImage(image.image, element);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SlideView),
      matchesGoldenFile('image_scale_framing.png'),
    );
  }, tags: ['ci-excluded', 'golden']);

  testWidgets(
    'decorated block frame fills its allocated cell',
    (tester) async {
      await _pumpGoldenSlide(
        tester,
        Slide(
          key: 'golden-decorated-block-frame',
          sections: [
            SectionBlock([
              ContentBlock(
                '## Decoration fills the frame\n\nContent alignment stays inside.',
                align: ContentAlignment.bottomRight,
              ),
            ]),
          ],
        ),
        style: SlideStyler(
          blockContainer: BlockStyler(
            margin: EdgeInsetsGeometryMix.all(56),
            padding: EdgeInsetsGeometryMix.all(36),
            decoration: BoxDecorationMix(
              color: const Color(0xFF172A46),
              border: BorderMix.all(
                BorderSideMix(color: const Color(0xFF45D4FF), width: 6),
              ),
              borderRadius: BorderRadiusMix.circular(24),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(SlideView),
        matchesGoldenFile('decorated_block_frame.png'),
      );
    },
    tags: ['ci-excluded', 'golden'],
  );

  testWidgets(
    'inset slide container defines the section frame',
    (tester) async {
      await _pumpGoldenSlide(
        tester,
        Slide(
          key: 'golden-inset-slide-container',
          sections: [
            SectionBlock([
              ContentBlock(
                '## Inset slide container\n\nThe section uses the inner frame.',
              ),
            ]),
          ],
        ),
        style: SlideStyler(
          slideContainer: BoxStyler(
            margin: EdgeInsetsGeometryMix.all(48),
            padding: EdgeInsetsGeometryMix.all(32),
            decoration: BoxDecorationMix(
              color: const Color(0xFF111A2A),
              border: BorderMix.all(
                BorderSideMix(color: const Color(0xFFB26BFF), width: 8),
              ),
            ),
          ),
          blockContainer: BlockStyler(
            padding: EdgeInsetsGeometryMix.all(24),
            decoration: BoxDecorationMix(color: const Color(0xFF233554)),
          ),
        ),
        parts: const SlideParts(
          header: null,
          footer: null,
          background: ColoredBox(color: Color(0xFF090909)),
        ),
      );

      await expectLater(
        find.byType(SlideView),
        matchesGoldenFile('inset_slide_container.png'),
      );
    },
    tags: ['ci-excluded', 'golden'],
  );

  testWidgets(
    'debug layout shows sections, blocks, margin, and padding',
    (tester) async {
      await _pumpGoldenSlide(
        tester,
        Slide(
          key: 'golden-debug-layout',
          sections: [
            SectionBlock([
              ContentBlock(
                '### First block\n\nBoth insets are visible.',
                margin: BlockInsets.all(16),
                padding: BlockInsets.all(32),
              ),
              ContentBlock(
                '### Second block\n\nDifferent insets.',
                margin: BlockInsets.symmetric(horizontal: 28, vertical: 12),
                padding: BlockInsets.symmetric(horizontal: 40, vertical: 24),
              ),
            ], spacing: 24),
            SectionBlock([
              ContentBlock(
                '### Second section\n\nOutlined independently.',
                margin: BlockInsets.symmetric(horizontal: 48, vertical: 20),
                padding: BlockInsets.all(36),
              ),
            ]),
          ],
        ),
        debug: true,
      );

      expect(find.textContaining('SECTION 1'), findsOneWidget);
      expect(find.textContaining('SECTION 2'), findsOneWidget);
      expect(find.textContaining('BLOCK 1'), findsNWidgets(2));
      expect(find.textContaining('BLOCK 2'), findsOneWidget);
      expect(find.text('SECTION'), findsOneWidget);
      expect(find.text('BLOCK'), findsOneWidget);
      expect(find.text('MARGIN'), findsOneWidget);
      expect(find.text('PADDING'), findsOneWidget);

      await expectLater(
        find.byType(SlideView),
        matchesGoldenFile('debug_layout_overlay.png'),
      );
    },
    tags: ['ci-excluded', 'golden'],
  );
}

Future<void> _pumpGoldenSlide(
  WidgetTester tester,
  Slide slide, {
  SlideStyler? style,
  SlideParts? parts,
  bool debug = false,
}) async {
  tester.view.physicalSize = kResolution;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final configuration = SlideTestHarness.createConfiguration(
    slide,
    style: style == null ? null : defaultSlideStyle.merge(style),
    widgets: builtInWidgets,
    debug: debug,
    parts:
        parts ??
        const SlideParts(background: ColoredBox(color: Color(0xFF090909))),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF090909),
        body: MixScope(
          colors: SDColors.colorMap,
          child: InheritedData(
            data: configuration,
            child: SizedBox.fromSize(
              size: kResolution,
              child: SlideView(configuration),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 10));
}
