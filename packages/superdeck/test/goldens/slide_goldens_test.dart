import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/rendering/slides/slide_parts.dart';
import 'package:superdeck/src/rendering/slides/slide_view.dart';
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
  });

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
  });

  testWidgets('block aligned center', (tester) async {
    await _pumpGoldenSlide(
      tester,
      SlideFixtures.withAlignment(ContentAlignment.center),
    );

    await expectLater(
      find.byType(SlideView),
      matchesGoldenFile('block_aligned_center.png'),
    );
  });
}

Future<void> _pumpGoldenSlide(WidgetTester tester, Slide slide) async {
  tester.view.physicalSize = kResolution;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final configuration = SlideTestHarness.createConfiguration(
    slide,
    parts: const SlideParts(
      background: ColoredBox(color: Color(0xFF090909)),
    ),
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
