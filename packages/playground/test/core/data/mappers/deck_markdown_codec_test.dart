import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/data/mappers/deck_markdown_codec.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  const codec = DeckMarkdownCodec();

  test('decodes Markdown with options, sections, widgets, and comments', () {
    const markdown = '''
---
title: Demo
layout: fullscreen
custom: preserved
---

@section { flex: 2 }
@block
# Heading

@image {
  src: hero.png
  fit: cover
}

<!-- Speaker note -->
''';

    final slide = codec.decode(markdown).single;

    expect(slide.options?.title, 'Demo');
    expect(slide.options?.layout, SlideLayout.fullscreen);
    expect(slide.options?.args, containsPair('custom', 'preserved'));
    expect(slide.sections.single.flex, 2);
    expect(
      slide.sections.single.blocks.whereType<WidgetBlock>().single,
      isA<WidgetBlock>()
          .having((block) => block.name, 'name', 'image')
          .having((block) => block.args['src'], 'src', 'hero.png')
          .having((block) => block.args['fit'], 'fit', 'cover'),
    );
    expect(slide.comments, ['Speaker note']);
  });

  test('encodes with the canonical SlideSerializer', () {
    final slides = [
      Slide(
        key: 'transient',
        options: SlideOptions(title: 'Canonical'),
        sections: [SectionBlock.text('# Canonical')],
      ),
    ];

    expect(codec.encode(slides), const SlideSerializer().serialize(slides));
  });

  test('throws a typed deck format error for invalid Markdown', () {
    const markdown = '''
---
layout: diagonal
---

# Invalid layout
''';

    expect(
      () => codec.decode(markdown),
      throwsA(
        isA<DeckFormatException>().having(
          (error) => error.source,
          'source',
          markdown,
        ),
      ),
    );
  });

  group('front matter recognition parity with MarkdownParser', () {
    // The same fixtures as packages/builder markdown_parser_test.dart. Both
    // paths run one parser, and these keep that true.
    const bulletList = '''
---
- First bullet
- Second bullet
---

# Second slide

---

# Third slide
''';

    const proseAboveMapping = '''
---
This sentence introduces the slide
Key: value
---
''';

    const mappingWithSequences = '''
---
title: Slide 1
tags:
  - dart
nested:
- flutter
---
Body
''';

    const markedNote = '''
---
@block
Note: remember this
---

# Second slide

---

# Third slide
''';

    const unmarkedNote = '''
---
Note: remember this
---
''';

    const malformed = '''
---
title: "unclosed
---
Body
''';

    /// The editor and the builder run one parser, so both must agree on the
    /// slide boundaries and on which text stayed content.
    void expectParity(String markdown) {
      final raw = const MarkdownParser().parse(markdown);
      final decoded = codec.decode(markdown);

      expect(decoded, hasLength(raw.length));
      for (var i = 0; i < raw.length; i++) {
        expect(decoded[i].key, raw[i].key, reason: 'slide $i key');
      }
    }

    test('a standalone bullet list is slide content', () {
      final slides = codec.decode(bulletList);

      expect(slides, hasLength(3));
      expect(slides.first.options?.args ?? {}, isEmpty);
      expect(codec.encode(slides), contains('- First bullet'));
      expectParity(bulletList);
    });

    test('prose above a mapping line is slide content', () {
      final slides = codec.decode(proseAboveMapping);

      expect(slides, hasLength(1));
      expect(codec.encode(slides), contains('Key: value'));
      expectParity(proseAboveMapping);
    });

    test('sequences under a key stay front matter', () {
      final slides = codec.decode(mappingWithSequences);

      expect(slides, hasLength(1));
      expect(slides.single.options?.title, 'Slide 1');
      expect(slides.single.options?.args['tags'], equals(['dart']));
      expect(slides.single.options?.args['nested'], equals(['flutter']));
      expectParity(mappingWithSequences);
    });

    test('@block keeps mapping-shaped text as content', () {
      final slides = codec.decode(markedNote);

      expect(slides, hasLength(3));
      expect(codec.encode(slides), contains('Note: remember this'));
      expectParity(markedNote);
    });

    test('an unmarked mapping-shaped line stays front matter', () {
      final slides = codec.decode(unmarkedNote);

      expect(slides, hasLength(1));
      expect(slides.single.options?.args['Note'], 'remember this');
      expectParity(unmarkedNote);
    });

    test('malformed front matter fails the decode', () {
      expect(
        () => codec.decode(malformed),
        throwsA(isA<DeckFormatException>()),
      );
      expect(
        () => const MarkdownParser().parse(malformed),
        throwsFormatException,
      );
    });
  });

  test('decode-encode-decode preserves structural slide data', () {
    const markdown = '''
---
title: Round trip
template: cover
custom: value
---

@section {
  flex: 2
  align: center
}
@chart {
  kind: bar
  values: [1, 2, 3]
}

<!-- Keep this note -->
''';

    final decoded = codec.decode(markdown);
    final reparsed = codec.decode(codec.encode(decoded));

    expect(_withoutKeys(reparsed), _withoutKeys(decoded));
  });
}

List<Map<String, Object?>> _withoutKeys(List<Slide> slides) {
  return [
    for (final slide in slides)
      Map<String, Object?>.from(slide.toJson())..remove('key'),
  ];
}
