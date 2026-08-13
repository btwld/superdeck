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
      Map<String, Object?>.from(slide.toMap())..remove('key'),
  ];
}
