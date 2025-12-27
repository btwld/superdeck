import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/styling/styling.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck_core/superdeck_core.dart';
export 'fixtures/slide_fixtures.dart';

/// Creates a list of test slides for testing navigation and presentation
List<SlideConfiguration> createTestSlides(int count) {
  return List.generate(
    count,
    (index) => SlideConfiguration(
      slideIndex: index,
      style: SlideStyle(),
      slide: Slide(
        key: 'slide-$index',
        sections: [
          SectionBlock([ContentBlock('Test slide $index content')]),
        ],
      ),
      thumbnailFile: 'thumbnail-$index.png',
    ),
  );
}

/// Creates a test slide configuration with custom content
SlideConfiguration createTestSlide({
  required int index,
  String? content,
  SlideStyle? style,
  String? thumbnailFile,
}) {
  return SlideConfiguration(
    slideIndex: index,
    style: style ?? SlideStyle(),
    slide: Slide(
      key: 'slide-$index',
      sections: [
        SectionBlock([ContentBlock(content ?? 'Test slide $index content')]),
      ],
    ),
    thumbnailFile: thumbnailFile ?? 'thumbnail-$index.png',
  );
}

/// Creates a test deck with the given slides
Deck createTestDeck({List<Slide>? slides, DeckConfiguration? config}) {
  final testSlides = slides ??
      List.generate(
        3,
        (index) => Slide(
          key: 'slide-$index',
          sections: [
            SectionBlock([ContentBlock('Test slide $index content')]),
          ],
        ),
      );

  return Deck(slides: testSlides, configuration: config ?? createMockConfig());
}

/// Creates a mock configuration
DeckConfiguration createMockConfig() => DeckConfiguration();

/// Pumps a widget and settles all animations
Future<void> pumpAndSettleWidget(
  WidgetTester tester,
  Widget widget, {
  Duration? duration,
}) async {
  await tester.pumpWidget(widget);
  if (duration != null) {
    await tester.pumpAndSettle(duration);
  } else {
    await tester.pumpAndSettle();
  }
}

/// Finds a widget by its key
Finder findByKey(String key) => find.byKey(Key(key));

/// Finds a widget by its text content
Finder findByText(String text) => find.text(text);

/// Verifies that a widget exists and is visible
void expectWidgetVisible(Finder finder) {
  expect(finder, findsOneWidget);
}

/// Verifies that a widget does not exist
void expectWidgetNotFound(Finder finder) {
  expect(finder, findsNothing);
}

// ---------------------------------------------------------------------------
// Additional helpers (additive; backward compatible)
// ---------------------------------------------------------------------------

int _testSlideId = 0;

String _nextKey(String prefix) => '$prefix-${_testSlideId++}';

/// Creates a Slide from a list of sections for inline test setup.
Slide createSlideFromSections(
  List<SectionBlock> sections, {
  String? key,
  SlideOptions? options,
}) {
  return Slide(
    key: key ?? _nextKey('test-slide'),
    sections: sections,
    options: options,
  );
}

/// Creates a simple single-section slide with given blocks.
Slide createSlideFromBlocks(
  List<Block> blocks, {
  String? key,
  int sectionFlex = 1,
}) {
  return Slide(
    key: key ?? _nextKey('test-slide'),
    sections: [SectionBlock(blocks, flex: sectionFlex)],
  );
}

/// Creates a content block with common defaults.
ContentBlock createContentBlock(
  String content, {
  int flex = 1,
  ContentAlignment? align,
  bool scrollable = false,
}) {
  return ContentBlock(
    content,
    flex: flex,
    align: align,
    scrollable: scrollable,
  );
}
