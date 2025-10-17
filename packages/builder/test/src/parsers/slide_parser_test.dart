import 'package:ack/ack.dart';
import 'package:superdeck_builder/src/parsers/markdown_parser.dart';
import 'package:superdeck_builder/src/parsers/raw_slide_schema.dart';
import 'package:test/test.dart';

void main() {
  final markdownParser = MarkdownParser();

  group('RawSlideMarkdownType.parse', () {
    test('creates RawSlideMarkdownType for valid map', () {
      final slide = RawSlideMarkdownType.parse({
        'key': 'slide-1',
        'content': 'Hello World',
        'frontmatter': {'title': 'Slide 1'},
      });

      expect(slide.key, equals('slide-1'));
      expect(slide.content, equals('Hello World'));
      expect(slide.frontmatter['title'], equals('Slide 1'));
    });

    test('throws AckException when frontmatter is not a map', () {
      expect(
        () => RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': 'Hello World',
          'frontmatter': 'invalid',
        }),
        throwsA(isA<AckException>()),
      );
    });

    test('throws AckException when required keys are missing', () {
      expect(
        () => RawSlideMarkdownType.parse({
          'content': 'Hello World',
          'frontmatter': const {},
        }),
        throwsA(isA<AckException>()),
      );
    });
  });

  group('MarkdownParser.parse', () {
    test('parses valid markdown into RawSlides', () async {
      const markdown = '''
---
title: Slide 1
---

Content for slide 1

---
title: Slide 2 
---  

Content for slide 2

---

Content for slide 3
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(3));
      expect(slides[0].frontmatter['title'], equals('Slide 1'));
      expect(slides[0].content, equals('Content for slide 1'));
      expect(slides[1].frontmatter['title'], equals('Slide 2'));
      expect(slides[1].content, equals('Content for slide 2'));
      expect(slides[2].frontmatter, {});
      expect(slides[2].content, equals('Content for slide 3'));
    });

    test(
      'parses RawSlides with additional properties in YAML frontmatter',
      () async {
        const markdown = '''
---
title: Slide 1
---
Content for slide 1

---
title: Slide 2 
---  
Content for slide 2
''';

        final slides = markdownParser.parse(markdown);

        expect(slides.length, equals(2));
        expect(slides[0].frontmatter['title'], equals('Slide 1'));

        expect(slides[0].content, equals('Content for slide 1'));
        expect(slides[1].frontmatter['title'], equals('Slide 2'));

        expect(slides[1].content, equals('Content for slide 2'));
      },
    );

    test('handles RawSlides with no properties in frontmatter', () async {
      const markdown = '''
---
---
Content for slide 1

---
---
Content for slide 2
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(2));
      expect(slides[0].frontmatter, {});
      expect(slides[0].content, equals('Content for slide 1'));
      expect(slides[1].frontmatter, {});
      expect(slides[1].content, equals('Content for slide 2'));
    });

    test('handles RawSlides with empty frontmatter', () async {
      const markdown = '''
---
title: 
---
Content for slide 1

---
title: 
---  
Content for slide 2
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(2));
      expect(slides[0].frontmatter, {'title': null});
      expect(slides[0].content, equals('Content for slide 1'));
      expect(slides[1].frontmatter, {'title': null});
      expect(slides[1].content, equals('Content for slide 2'));
    });

    test('handles empty markdown string', () async {
      const markdown = '';

      final slides = markdownParser.parse(markdown);

      expect(slides, isEmpty);
    });

    test('ignores content outside slide separators', () async {
      const markdown = '''
This content is outside slides
---
title: Slide 1
---
Content for slide 1

This last content is also outside slides
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(2));
      expect(slides[0].frontmatter, {});
      expect(slides[1].frontmatter['title'], equals('Slide 1'));
      expect(
        slides[1].content,
        equals(
          'Content for slide 1\n\nThis last content is also outside slides',
        ),
      );
    });

    test('parses RawSlide with no content but valid frontmatter', () async {
      const markdown = '''
---
title: Slide 1
---
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(1));
      expect(slides[0].frontmatter['title'], equals('Slide 1'));
      expect(slides[0].content, isEmpty);
    });

    test(
      'parses multiple RawSlides with some missing content or frontmatter',
      () async {
        const markdown = '''
---
title: Slide 1
---
Content for slide 1

---
title: Slide 2
---
---
title: Slide 3
---
Content for slide 3
''';

        final slides = markdownParser.parse(markdown);

        expect(slides.length, equals(3));
        expect(slides[0].frontmatter['title'], equals('Slide 1'));
        expect(slides[0].content, equals('Content for slide 1'));

        expect(slides[1].frontmatter['title'], equals('Slide 2'));
        expect(slides[1].content, isEmpty);

        expect(slides[2].frontmatter['title'], equals('Slide 3'));
        expect(slides[2].content, equals('Content for slide 3'));
      },
    );
  });

  // Group test notes from comments
  group('Correctly parses slide notes from markdown comments', () {
    test('parses notes from markdown comments', () async {
      const markdown = '''
---
title: Slide 1
---
Content for slide 1

<!-- This is a note for slide 1 -->

---
title: Slide 2
---

Content for slide 2

''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(2));
      expect(slides[0].frontmatter['title'], equals('Slide 1'));
      expect(
        slides[0].content,
        equals('Content for slide 1\n\n<!-- This is a note for slide 1 -->'),
      );

      expect(slides[1].frontmatter['title'], equals('Slide 2'));
      expect(slides[1].content, equals('Content for slide 2'));
    });

    test('parses multiple notes from markdown comments', () async {
      const markdown = '''
---
title: Slide 1
---
Content for slide 1

<!-- This is a note for slide 1 -->

<!-- This is another note for slide 1 -->

<!-- This is a third note for 
slide 1 -->

---
title: Slide 2
---

Content for slide 2

''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(2));
      expect(slides[0].frontmatter['title'], equals('Slide 1'));
      expect(
        slides[0].content,
        equals(
          'Content for slide 1\n\n<!-- This is a note for slide 1 -->\n\n<!-- This is another note for slide 1 -->\n\n<!-- This is a third note for \nslide 1 -->',
        ),
      );

      expect(slides[0].frontmatter['title'], equals('Slide 1'));

      expect(slides[1].frontmatter['title'], equals('Slide 2'));
      expect(slides[1].content, equals('Content for slide 2'));
    });
  });

  // Test that mixes single --- with frontmatter
  group('Handles slides with mixed frontmatter and ---', () {
    test('parses slides with mixed frontmatter and ---', () async {
      const markdown = '''
---
title: Slide 1
--- 
Content for slide 1

---

Content for the second slide
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(2));

      expect(slides[0].frontmatter['title'], equals('Slide 1'));
      expect(slides[0].content, equals('Content for slide 1'));

      expect(slides[1].frontmatter, {});
      expect(slides[1].content, equals('Content for the second slide'));
    });
  });
}
