import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart'
    as wizard;
import 'package:playground/features/ai/core/tools/deck_tools_schemas.dart';

void main() {
  group('Deck tool request schemas', () {
    test('parse valid keyless request payloads', () {
      final createRequest = CreateSlideRequestType.parse({
        'slide': _deckToolSlide(title: 'Intro'),
      });
      final updateRequest = UpdateSlideRequestType.parse({
        'index': 0,
        'slide': _deckToolSlide(title: 'Updated'),
      });
      final moveRequest = MoveSlideRequestType.parse({
        'fromIndex': 0,
        'toIndex': 1,
      });

      expect(createRequest.slide.options?.title, 'Intro');
      expect(updateRequest.slide.options?.title, 'Updated');
      expect(moveRequest.toIndex, 1);
    });

    test('reject incoming key before service logic', () {
      final parsed = CreateSlideRequestType.safeParse({
        'slide': {..._deckToolSlide(), 'key': 'stale-key'},
      }).getOrNull();

      expect(parsed, isNull);
    });

    test('deck-edit indices validate integer type only', () {
      expect(
        ReadSlideRequestType.safeParse({'index': -1}).getOrNull(),
        isNotNull,
      );
      expect(
        CreateSlideRequestType.safeParse({
          'slide': _deckToolSlide(),
          'atIndex': -1,
        }).getOrNull(),
        isNotNull,
      );
      expect(
        ReadSlideRequestType.safeParse({'index': '0'}).getOrNull(),
        isNull,
      );
    });

    test('wizard slide schemas remain key-based', () {
      final parsed = wizard.CreateSlideType.safeParse({
        'key': 'wizard-key',
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {'type': 'block', 'content': 'Body'},
            ],
          },
        ],
      }).getOrNull();

      expect(parsed?.key, 'wizard-key');
    });
  });

  group('DeckToolSlide fidelity', () {
    test('preserves options args and arbitrary widget args', () {
      final slide = DeckToolSlideType.parse({
        'options': {'title': 'Intro', 'template': 'hero', 'speaker': 'notes'},
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {
                'type': 'widget',
                'name': 'image',
                'src': 'asset.png',
                'fit': 'cover',
              },
            ],
          },
        ],
      });

      final widgetBlock = slide.sections.single.blocks!.single;

      expect(slide.options?.template, 'hero');
      expect(slide.options?.args['speaker'], 'notes');
      expect(widgetBlock, isA<DeckToolWidgetBlockType>());
      expect((widgetBlock as DeckToolWidgetBlockType).args['src'], 'asset.png');
      expect(widgetBlock.args['fit'], 'cover');
    });
  });
}

Map<String, Object?> _deckToolSlide({String title = 'Slide'}) {
  return {
    'options': {'title': title},
    'sections': [
      {
        'type': 'section',
        'blocks': [
          {'type': 'block', 'content': 'Body'},
        ],
      },
    ],
  };
}
