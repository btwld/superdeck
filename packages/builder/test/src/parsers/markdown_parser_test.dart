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

    test(
      'returns the correct slide count when slides without frontmatter are separated by --- (issue #63)',
      () async {
        const markdown = '''
# Slide 1

---

# Slide 2

---

# Slide 3
''';

        final slides = markdownParser.parse(markdown);

        expect(slides.length, equals(3));
        expect(slides[0].content, equals('# Slide 1'));
        expect(slides[1].content, equals('# Slide 2'));
        expect(slides[2].content, equals('# Slide 3'));
      },
    );
  });

  group('front matter recognition', () {
    test('a standalone bullet list is slide content', () {
      const markdown = '''
---
- First bullet
- Second bullet
---

# Second slide

---

# Third slide
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(3));
      expect(slides[0].frontmatter, isEmpty);
      expect(slides[0].content, equals('- First bullet\n- Second bullet'));
      expect(slides[1].content, equals('# Second slide'));
      expect(slides[2].content, equals('# Third slide'));
    });

    test('prose above a mapping line is slide content', () {
      const markdown = '''
---
This sentence introduces the slide
Key: value
---
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(1));
      expect(slides.single.frontmatter, isEmpty);
      expect(
        slides.single.content,
        equals('This sentence introduces the slide\nKey: value'),
      );
    });

    test('prose below a mapping line is slide content', () {
      const markdown = '''
---
title: Slide 1
This sentence is not YAML
---
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(1));
      expect(slides.single.frontmatter, isEmpty);
      expect(slides.single.content, contains('This sentence is not YAML'));
    });

    test('an indented sequence under a key is frontmatter', () {
      const markdown = '''
---
title: Slide 1
tags:
  - dart
  - flutter
---
Body
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(1));
      expect(slides.single.frontmatter['tags'], equals(['dart', 'flutter']));
      expect(slides.single.content, equals('Body'));
    });

    test('an indentless sequence under a key is frontmatter', () {
      const markdown = '''
---
title: Slide 1
tags:
- dart
- flutter
---
Body
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(1));
      expect(slides.single.frontmatter['tags'], equals(['dart', 'flutter']));
      expect(slides.single.content, equals('Body'));
    });

    test('a quoted key beside an unquoted key stays frontmatter', () {
      const markdown = '''
---
title: Slide 1
"my key": quoted value
---
Body
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(1));
      expect(
        slides.single.frontmatter,
        equals({'title': 'Slide 1', 'my key': 'quoted value'}),
      );
      expect(slides.single.content, equals('Body'));
    });

    test('a quoted key alone is slide content', () {
      // Characterization: the opening line of a block must be an unquoted
      // key for the block to be read as front matter.
      const markdown = '''
---
"my key": quoted value
---
Body
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(2));
      expect(slides[0].frontmatter, isEmpty);
      expect(slides[0].content, equals('"my key": quoted value'));
      expect(slides[1].content, equals('Body'));
    });

    test('a literal block value stays frontmatter', () {
      const markdown = '''
---
description: |
  line one
  line two
---
Body
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(1));
      expect(
        slides.single.frontmatter['description'],
        equals('line one\nline two'),
      );
      expect(slides.single.content, equals('Body'));
    });

    test('a folded block value stays frontmatter', () {
      const markdown = '''
---
summary: >
  folded one
  folded two
---
Body
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(1));
      expect(
        slides.single.frontmatter['summary'],
        equals('folded one folded two'),
      );
      expect(slides.single.content, equals('Body'));
    });

    test('a heading inside a literal block rules out frontmatter', () {
      // Characterization of known legacy behaviour: `#`, `@`, `>` and `!` mark
      // slide content wherever they open a line, including inside a block
      // scalar. Mark such text with `@block` to keep it as content on purpose.
      const markdown = '''
---
description: |
  # not a heading
---
Body
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(2));
      expect(slides[0].frontmatter, isEmpty);
      expect(slides[0].content, contains('# not a heading'));
    });

    test('an unmarked mapping-shaped line stays frontmatter', () {
      // Known legacy behaviour: a single `Key: value` line is both valid YAML
      // and plausible prose, and no predicate separates them. Authors mark it
      // as content with `@block`.
      const markdown = '''
---
Note: remember this
---
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(1));
      expect(
        slides.single.frontmatter,
        equals({'Note': 'remember this'}),
      );
      expect(slides.single.content, isEmpty);
    });

    test('@block keeps mapping-shaped text as content', () {
      const markdown = '''
---
@block
Note: remember this
---

# Second slide

---

# Third slide
''';

      final slides = markdownParser.parse(markdown);

      expect(slides, hasLength(3));
      expect(slides[0].frontmatter, isEmpty);
      expect(slides[0].content, contains('Note: remember this'));
      expect(slides[1].content, equals('# Second slide'));
      expect(slides[2].content, equals('# Third slide'));
    });

    test('malformed YAML in a recognized block reports an error', () {
      const markdown = '''
---
title: "unclosed
---
Body
''';

      expect(
        () => markdownParser.parse(markdown),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('front matter'),
          ),
        ),
      );
    });
  });

  group('fenced code does not split slides', () {
    test('--- inside a backtick fence stays on one slide', () {
      const markdown = '''
# Code

```
---
not a separator
```
''';
      final slides = markdownParser.parse(markdown);
      expect(slides, hasLength(1));
      expect(slides.single.content, contains('---'));
      expect(slides.single.content, contains('not a separator'));
    });

    test('--- inside a tilde fence stays on one slide', () {
      const markdown = '''
# Code

~~~
---
not a separator
~~~
''';
      final slides = markdownParser.parse(markdown);
      expect(slides, hasLength(1));
      expect(slides.single.content, contains('---'));
    });

    test('--- inside a language + {.hero} fence stays on one slide', () {
      const markdown = '''
# Hero fence

```dart {.hero}
---
@override
void main() {}
```
''';
      final slides = markdownParser.parse(markdown);
      expect(slides, hasLength(1));
      expect(slides.single.content, contains('@override'));
      expect(slides.single.content, contains('---'));
    });

    test('--- inside an unclosed fence stays on one slide', () {
      const markdown = '''
# Open fence

```
---
still the same slide
''';
      final slides = markdownParser.parse(markdown);
      expect(slides, hasLength(1));
      expect(slides.single.content, contains('still the same slide'));
    });

    test('```{.code} closer lets a following --- split slides', () {
      const markdown = '''
### Code Blocks

```dart
void main() {}
```{.code}

---

## Custom Widgets
''';
      final slides = markdownParser.parse(markdown);
      expect(slides, hasLength(2));
      expect(slides[0].content, contains('### Code Blocks'));
      expect(slides[1].content, contains('## Custom Widgets'));
    });

    test('--- after a closed fence still splits slides', () {
      const markdown = '''
# One

```
code
```

---

# Two
''';
      final slides = markdownParser.parse(markdown);
      expect(slides, hasLength(2));
      expect(slides[0].content, contains('# One'));
      expect(slides[1].content, contains('# Two'));
    });
  });
}
