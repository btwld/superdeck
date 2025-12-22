import 'package:ack/ack.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('Deck Model', () {
    group('constructor', () {
      test('creates with required parameters', () {
        final deck = Deck(
          slides: [],
          configuration: DeckConfiguration(),
        );

        expect(deck.slides, isEmpty);
        expect(deck.configuration, isA<DeckConfiguration>());
      });

      test('creates with slides', () {
        final slides = [
          const Slide(key: 'slide1'),
          const Slide(key: 'slide2'),
        ];

        final deck = Deck(
          slides: slides,
          configuration: DeckConfiguration(),
        );

        expect(deck.slides, hasLength(2));
        expect(deck.slides.first.key, 'slide1');
      });
    });

    group('copyWith', () {
      test('copies with new slides', () {
        final original = Deck(
          slides: [const Slide(key: 'original')],
          configuration: DeckConfiguration(),
        );

        final copy = original.copyWith(
          slides: [const Slide(key: 'new')],
        );

        expect(copy.slides.first.key, 'new');
      });

      test('copies with new configuration', () {
        final original = Deck(
          slides: [],
          configuration: DeckConfiguration(projectDir: '/old'),
        );

        final copy = original.copyWith(
          configuration: DeckConfiguration(projectDir: '/new'),
        );

        expect(copy.configuration.projectDir, '/new');
      });

      test('preserves values when not specified', () {
        final original = Deck(
          slides: [const Slide(key: 'keep')],
          configuration: DeckConfiguration(projectDir: '/keep'),
        );

        final copy = original.copyWith();

        expect(copy.slides.first.key, 'keep');
        expect(copy.configuration.projectDir, '/keep');
      });
    });

    group('toMap', () {
      test('serializes empty deck', () {
        final deck = Deck(
          slides: [],
          configuration: DeckConfiguration(),
        );

        final map = deck.toMap();

        expect(map['slides'], isEmpty);
        expect(map['configuration'], isA<Map>());
      });

      test('serializes slides', () {
        final deck = Deck(
          slides: [
            Slide(
              key: 'slide1',
              sections: [SectionBlock([ContentBlock('Content')])],
            ),
          ],
          configuration: DeckConfiguration(),
        );

        final map = deck.toMap();
        final slides = map['slides'] as List;

        expect(slides, hasLength(1));
        expect(slides.first['key'], 'slide1');
      });

      test('serializes configuration', () {
        final deck = Deck(
          slides: [],
          configuration: DeckConfiguration(
            projectDir: '/project',
            slidesPath: 'slides.md',
          ),
        );

        final map = deck.toMap();
        final config = map['configuration'] as Map;

        expect(config['projectDir'], '/project');
        expect(config['slidesPath'], 'slides.md');
      });
    });

    group('fromMap', () {
      test('deserializes empty deck', () {
        final deck = Deck.fromMap({
          'slides': [],
          'configuration': {},
        });

        expect(deck.slides, isEmpty);
        expect(deck.configuration.projectDir, isNull);
      });

      test('deserializes slides', () {
        final deck = Deck.fromMap({
          'slides': [
            {
              'key': 'slide1',
              'sections': [],
              'comments': [],
            },
          ],
          'configuration': {},
        });

        expect(deck.slides, hasLength(1));
        expect(deck.slides.first.key, 'slide1');
      });

      test('handles missing configuration', () {
        final deck = Deck.fromMap({
          'slides': [],
        });

        expect(deck.configuration, isA<DeckConfiguration>());
      });

      test('handles null slides', () {
        final deck = Deck.fromMap({
          'configuration': {},
        });

        expect(deck.slides, isEmpty);
      });
    });

    group('schema', () {
      test('validates empty deck', () {
        final result = Deck.schema.safeParse({
          'slides': [],
        });

        expect(result.isOk, isTrue);
      });

      test('validates deck with slides', () {
        final result = Deck.schema.safeParse({
          'slides': [
            {
              'key': 'slide1',
              'sections': [],
            },
          ],
        });

        expect(result.isOk, isTrue);
      });

      test('validates deck with configuration', () {
        final result = Deck.schema.safeParse({
          'slides': [],
          'configuration': {
            'projectDir': '/project',
          },
        });

        expect(result.isOk, isTrue);
      });

      test('validates complex deck structure', () {
        final result = Deck.schema.safeParse({
          'slides': [
            {
              'key': 'slide1',
              'options': {
                'title': 'Test',
                'style': 'default',
              },
              'sections': [
                {
                  'type': 'section',
                  'flex': 1,
                  'blocks': [
                    {
                      'type': 'block',
                      'content': '# Hello',
                    },
                  ],
                },
              ],
              'comments': ['Note'],
            },
          ],
          'configuration': {
            'projectDir': '/project',
            'outputDir': 'build',
          },
        });

        expect(result.isOk, isTrue);
      });

      test('allows additional properties', () {
        final result = Deck.schema.safeParse({
          'slides': [],
          'customField': 'custom value',
        });

        expect(result.isOk, isTrue);
      });
    });

    group('parse', () {
      test('parses valid deck', () {
        final deck = Deck.parse({
          'slides': [
            {
              'key': 'slide1',
              'sections': [],
            },
          ],
          'configuration': {},
        });

        expect(deck.slides, hasLength(1));
        expect(deck.slides.first.key, 'slide1');
      });

      test('throws on invalid slides type', () {
        expect(
          () => Deck.parse({
            'slides': 'not an array',
          }),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('safeParse', () {
      test('returns Ok result for valid deck', () {
        final result = Deck.safeParse({
          'slides': [],
          'configuration': {},
        });

        expect(result.isOk, isTrue);
      });

      test('returns Fail result for invalid deck', () {
        final result = Deck.safeParse({
          'slides': 'invalid',
        });

        expect(result.isOk, isFalse);
      });
    });

    group('round-trip serialization', () {
      test('preserves data through toMap/fromMap', () {
        final original = Deck(
          slides: [
            Slide(
              key: 'slide1',
              options: const SlideOptions(title: 'Title', style: 'custom'),
              sections: [
                SectionBlock([
                  ContentBlock('# Hello World'),
                ]),
              ],
              comments: ['Note 1', 'Note 2'],
            ),
          ],
          configuration: DeckConfiguration(
            projectDir: '/project',
            slidesPath: 'deck.md',
            outputDir: 'output',
            assetsPath: 'assets',
          ),
        );

        final restored = Deck.fromMap(original.toMap());

        expect(restored, original);
      });

      test('preserves widget blocks through serialization', () {
        final original = Deck(
          slides: [
            Slide(
              key: 'widget-slide',
              sections: [
                SectionBlock([
                  WidgetBlock(
                    name: 'myWidget',
                    args: {'param': 'value'},
                  ),
                ]),
              ],
            ),
          ],
          configuration: DeckConfiguration(),
        );

        final restored = Deck.fromMap(original.toMap());
        final restoredBlock =
            restored.slides.first.sections.first.blocks.first as WidgetBlock;

        expect(restoredBlock.name, 'myWidget');
        expect(restoredBlock.args['param'], 'value');
      });
    });

    group('equality', () {
      test('equal decks are equal', () {
        final deck1 = Deck(
          slides: [const Slide(key: 'same')],
          configuration: DeckConfiguration(projectDir: '/same'),
        );
        final deck2 = Deck(
          slides: [const Slide(key: 'same')],
          configuration: DeckConfiguration(projectDir: '/same'),
        );

        expect(deck1, deck2);
        expect(deck1.hashCode, deck2.hashCode);
      });

      test('different slides makes decks unequal', () {
        final deck1 = Deck(
          slides: [const Slide(key: 'a')],
          configuration: DeckConfiguration(),
        );
        final deck2 = Deck(
          slides: [const Slide(key: 'b')],
          configuration: DeckConfiguration(),
        );

        expect(deck1, isNot(deck2));
      });

      test('different configuration makes decks unequal', () {
        final deck1 = Deck(
          slides: [],
          configuration: DeckConfiguration(projectDir: '/a'),
        );
        final deck2 = Deck(
          slides: [],
          configuration: DeckConfiguration(projectDir: '/b'),
        );

        expect(deck1, isNot(deck2));
      });

      test('empty decks are equal', () {
        final deck1 = Deck(
          slides: [],
          configuration: DeckConfiguration(),
        );
        final deck2 = Deck(
          slides: [],
          configuration: DeckConfiguration(),
        );

        expect(deck1, deck2);
      });
    });
  });
}
