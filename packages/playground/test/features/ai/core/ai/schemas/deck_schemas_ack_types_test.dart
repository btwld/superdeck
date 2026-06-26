import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';

void main() {
  group('Slide ACK types', () {
    test('parse valid block/section/slide payloads', () {
      final block = SlideBlockType.parse({
        'type': 'block',
        'content': 'Hello world',
      });
      final section = SlideSectionType.parse({
        'type': 'section',
        'blocks': [blockSchema.encode(block)!],
      });
      final slide = SlideType.parse({
        'key': 'slide-1',
        'options': {'title': 'Intro'},
        'sections': [sectionSchema.encode(section)!],
      });

      expect(block.type, 'block');
      expect(section.blocks.single.content, 'Hello world');
      expect(slide.key, 'slide-1');
      expect(slide.options?['title'], 'Intro');
      expect(slide.sections.single.type, 'section');
    });

    test('reject invalid slide shapes', () {
      expect(
        SlideType.safeParse({
          'options': {'title': 'Missing key'},
          'sections': [],
        }).getOrNull(),
        isNull,
      );
      expect(
        SlideSectionType.safeParse({
          'type': 'section',
          'blocks': 'not-a-list',
        }).getOrNull(),
        isNull,
      );
    });
  });

  group('Slide generation ACK type', () {
    test('parse full generation payload', () {
      final generation = SlideGenerationType.parse({
        'slides': [
          {
            'key': 'slide-1',
            'options': {'title': 'Intro'},
            'sections': [
              {
                'type': 'section',
                'blocks': [
                  {'type': 'block', 'content': 'Body'},
                ],
              },
            ],
          },
        ],
        'style': _styleMap(),
      });

      expect(generation.slides, hasLength(1));
      expect(generation.slides.single.key, 'slide-1');
      expect(generation.style.name, 'Default');
    });
  });
}

Map<String, Object?> _styleMap() {
  return {
    'name': 'Default',
    'colors': {
      'background': '#FFFFFF',
      'heading': '#112233',
      'body': '#445566',
    },
    'fonts': {'headline': 'montserrat', 'body': 'openSans'},
  };
}
