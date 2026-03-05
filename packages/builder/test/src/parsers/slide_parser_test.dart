import 'package:ack/ack.dart';
import 'package:superdeck_builder/src/parsers/markdown_parser.dart';
import 'package:superdeck_builder/src/parsers/raw_slide_schema.dart';
import 'package:test/test.dart';

void main() {
  final markdownParser = MarkdownParser();

  group('RawSlideMarkdown.parse', () {
    test('creates RawSlideMarkdown for valid map', () {
      final slide = RawSlideMarkdown.parse({
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
        () => RawSlideMarkdown.parse({
          'key': 'slide-1',
          'content': 'Hello World',
          'frontmatter': 'invalid',
        }),
        throwsA(isA<AckException>()),
      );
    });

    test('throws AckException when required keys are missing', () {
      expect(
        () => RawSlideMarkdown.parse({
          'content': 'Hello World',
          'frontmatter': const {},
        }),
        throwsA(isA<AckException>()),
      );
    });
  });

  group('MarkdownParser.parse', () {
    test('handles plain --- separators without frontmatter', () async {
      const markdown = '''
A
---
B
---
C
''';
      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(3));
      expect(slides[0].frontmatter, isEmpty);
      expect(slides[0].content, equals('A'));
      expect(slides[1].frontmatter, isEmpty);
      expect(slides[1].content, equals('B'));
      expect(slides[2].frontmatter, isEmpty);
      expect(slides[2].content, equals('C'));
    });

    test('throws when frontmatter is not a map', () {
      const markdown = '''
---
- item one
- item two
---

Content after non-map frontmatter.
''';

      expect(
        () => markdownParser.parse(markdown),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when frontmatter is malformed', () {
      const markdown = '''
---
title: [unclosed
---

Content after malformed frontmatter.
''';

      expect(
        () => markdownParser.parse(markdown),
        throwsA(isA<FormatException>()),
      );
    });

    test('does not treat @section slide content as malformed frontmatter', () {
      const markdown = '''
---
title: Intro
---
Intro content

---
@section {
  flex: 2
}
@column
Slide body

---
Final slide
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(3));
      expect(slides[0].frontmatter['title'], equals('Intro'));
      expect(slides[0].content, equals('Intro content'));
      expect(
        slides[1].content,
        equals('@section {\n  flex: 2\n}\n@column\nSlide body'),
      );
      expect(slides[2].content, equals('Final slide'));
    });

    test(
      'does not treat plain markdown with colons as frontmatter candidate',
      () {
        const markdown = '''
Slide 1
---
API: Overview
This line is normal markdown content.
---
Slide 3
''';

        final slides = markdownParser.parse(markdown);

        expect(slides.length, equals(3));
        expect(slides[0].content, equals('Slide 1'));
        expect(
          slides[1].content,
          equals('API: Overview\nThis line is normal markdown content.'),
        );
        expect(slides[2].content, equals('Slide 3'));
      },
    );

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

    test('does not split --- inside tilde fenced code blocks', () async {
      const markdown = '''
Slide 1
~~~dart
---
print('inside code');
---
~~~

---

Slide 2
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(2));
      expect(slides[0].frontmatter, isEmpty);
      expect(
        slides[0].content,
        equals("Slide 1\n~~~dart\n---\nprint('inside code');\n---\n~~~"),
      );
      expect(slides[1].frontmatter, isEmpty);
      expect(slides[1].content, equals('Slide 2'));
    });

    test('splits plain --- separators into multiple slides', () {
      const markdown = '''
Slide A

---

Slide B

---

Slide C
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(3));
      expect(slides[0].frontmatter, isEmpty);
      expect(slides[0].content, equals('Slide A'));
      expect(slides[1].frontmatter, isEmpty);
      expect(slides[1].content, equals('Slide B'));
      expect(slides[2].frontmatter, isEmpty);
      expect(slides[2].content, equals('Slide C'));
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

    test(
      'parses frontmatter with blank lines without splitting slides',
      () async {
        const markdown = '''
---
title: Slide 1

description: Has a blank line above
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
        expect(
          slides[0].frontmatter['description'],
          equals('Has a blank line above'),
        );
        expect(slides[0].content, equals('Content for slide 1'));
        expect(slides[1].frontmatter['title'], equals('Slide 2'));
        expect(slides[1].content, equals('Content for slide 2'));
      },
    );

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

    test('applies deterministic key suffixes for hash collisions', () {
      final parser = MarkdownParser();
      const markdown = '''
---
title: Same
---
Repeated content

---
title: Same
---
Repeated content

---
title: Same
---
Repeated content
''';

      final slides = parser.parse(markdown);
      final baseKey = slides.first.key;

      expect(slides[0].key, baseKey);
      expect(slides[1].key, '${baseKey}__2');
      expect(slides.map((slide) => slide.key).toSet().length, slides.length);
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

    test('supports separators before and after plain slides', () {
      const markdown = '''
---
title: First
---
Welcome

---
No frontmatter here

---
title: Second
---

Has YAML again
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(3));
      expect(slides[0].frontmatter['title'], equals('First'));
      expect(slides[0].content, equals('Welcome'));
      expect(slides[1].frontmatter, isEmpty);
      expect(slides[1].content, equals('No frontmatter here'));
      expect(slides[2].frontmatter['title'], equals('Second'));
      expect(slides[2].content, equals('Has YAML again'));
    });

    test('ignores --- inside fenced code when splitting slides', () {
      const markdown = '''
---
title: Slide 1
---
Code block below:

~~~
---
Inside code
---
~~~
''';

      final slides = markdownParser.parse(markdown);

      expect(slides.length, equals(1));
      expect(slides[0].frontmatter['title'], equals('Slide 1'));
      expect(
        slides[0].content,
        equals('Code block below:\n\n~~~\n---\nInside code\n---\n~~~'),
      );
    });
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
