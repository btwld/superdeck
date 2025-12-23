import 'package:superdeck_core/src/deck_configuration.dart';
import 'package:superdeck_core/src/models/block_model.dart';
import 'package:superdeck_core/src/models/deck_model.dart';
import 'package:superdeck_core/src/models/slide_model.dart';
import 'package:test/test.dart';

void main() {
  group('Deck Model', () {
    group('Deck', () {
      test('creates with required parameters', () {
        final deck = Deck(
          slides: const [],
          configuration: DeckConfiguration(),
        );

        expect(deck.slides, isEmpty);
        expect(deck.configuration, isNotNull);
      });

      test('creates with slides', () {
        final slides = [
          const Slide(key: 'slide-1'),
          const Slide(key: 'slide-2'),
        ];
        final deck = Deck(
          slides: slides,
          configuration: DeckConfiguration(),
        );

        expect(deck.slides.length, 2);
        expect(deck.slides[0].key, 'slide-1');
        expect(deck.slides[1].key, 'slide-2');
      });

      group('copyWith', () {
        test('copies with new slides', () {
          final original = Deck(
            slides: const [Slide(key: 'original')],
            configuration: DeckConfiguration(),
          );
          final copy = original.copyWith(
            slides: const [Slide(key: 'new')],
          );

          expect(copy.slides[0].key, 'new');
        });

        test('copies with new configuration', () {
          final original = Deck(
            slides: const [],
            configuration: DeckConfiguration(),
          );
          final copy = original.copyWith(
            configuration: DeckConfiguration(projectDir: '/new'),
          );

          expect(copy.configuration.projectDir, '/new');
        });

        test('preserves values when not specified', () {
          final original = Deck(
            slides: const [Slide(key: 'keep')],
            configuration: DeckConfiguration(projectDir: '/keep'),
          );
          final copy = original.copyWith();

          expect(copy.slides[0].key, 'keep');
          expect(copy.configuration.projectDir, '/keep');
        });
      });

      group('toMap', () {
        test('serializes empty deck', () {
          final deck = Deck(
            slides: const [],
            configuration: DeckConfiguration(),
          );
          final map = deck.toMap();

          expect(map['slides'], isEmpty);
          expect(map['configuration'], isA<Map>());
        });

        test('serializes deck with slides', () {
          final deck = Deck(
            slides: [
              Slide(
                key: 'slide-1',
                sections: [SectionBlock([ContentBlock('Content')])],
              ),
            ],
            configuration: DeckConfiguration(),
          );
          final map = deck.toMap();

          expect((map['slides'] as List).length, 1);
          final slideMap = (map['slides'] as List)[0] as Map;
          expect(slideMap['key'], 'slide-1');
        });

        test('serializes deck with configuration', () {
          final deck = Deck(
            slides: const [],
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
        test('deserializes minimal map', () {
          final map = <String, dynamic>{
            'slides': <dynamic>[],
          };
          final deck = Deck.fromMap(map);

          expect(deck.slides, isEmpty);
          expect(deck.configuration, isNotNull);
        });

        test('deserializes map with slides', () {
          final map = {
            'slides': [
              {'key': 'slide-1'},
              {'key': 'slide-2'},
            ],
          };
          final deck = Deck.fromMap(map);

          expect(deck.slides.length, 2);
          expect(deck.slides[0].key, 'slide-1');
        });

        test('deserializes map with configuration', () {
          final map = {
            'slides': <dynamic>[],
            'configuration': {
              'projectDir': '/test',
              'outputDir': '.superdeck',
            },
          };
          final deck = Deck.fromMap(map);

          expect(deck.configuration.projectDir, '/test');
          expect(deck.configuration.outputDir, '.superdeck');
        });

        test('deserializes complex slide structure', () {
          final map = <String, dynamic>{
            'slides': [
              {
                'key': 'complex',
                'options': {'title': 'Complex Slide', 'style': 'demo'},
                'sections': [
                  {
                    'type': 'section',
                    'flex': 2,
                    'blocks': [
                      {'type': 'column', 'content': 'Block 1', 'flex': 1},
                      {'type': 'widget', 'name': 'image', 'src': 'test.png'},
                    ],
                  },
                ],
                'comments': ['Speaker note'],
              },
            ],
            'configuration': <String, dynamic>{},
          };
          final deck = Deck.fromMap(map);

          expect(deck.slides.length, 1);
          final slide = deck.slides[0];
          expect(slide.key, 'complex');
          expect(slide.options?.title, 'Complex Slide');
          expect(slide.sections.length, 1);
          expect(slide.sections[0].blocks.length, 2);
          expect(slide.comments, ['Speaker note']);
        });
      });

      group('round-trip serialization', () {
        test('preserves data through toMap/fromMap', () {
          final original = Deck(
            slides: [
              Slide(
                key: 'rt-slide',
                options: const SlideOptions(title: 'RT Title'),
                sections: [
                  SectionBlock([
                    ContentBlock('Content', align: ContentAlignment.center),
                  ]),
                ],
                comments: ['Note'],
              ),
            ],
            configuration: DeckConfiguration(
              projectDir: '/rt-project',
              slidesPath: 'slides.md',
            ),
          );

          final restored = Deck.fromMap(original.toMap());

          expect(restored.slides.length, original.slides.length);
          expect(restored.slides[0].key, original.slides[0].key);
          expect(
            restored.configuration.projectDir,
            original.configuration.projectDir,
          );
        });
      });

      group('parse', () {
        test('parses valid map', () {
          final map = {
            'slides': [
              {'key': 'parsed'},
            ],
          };
          final deck = Deck.parse(map);

          expect(deck.slides.length, 1);
          expect(deck.slides[0].key, 'parsed');
        });

        test('parses map with all fields', () {
          final map = {
            'slides': [
              {
                'key': 'full',
                'options': {'title': 'Title'},
                'sections': [
                  {
                    'type': 'section',
                    'blocks': [
                      {'type': 'block', 'content': 'Content'},
                    ],
                  },
                ],
                'comments': ['Note'],
              },
            ],
            'configuration': {
              'projectDir': '/test',
            },
          };
          final deck = Deck.parse(map);

          expect(deck.slides[0].key, 'full');
          expect(deck.slides[0].options?.title, 'Title');
          expect(deck.configuration.projectDir, '/test');
        });

        test('parses deck with widget blocks', () {
          final map = {
            'slides': [
              {
                'key': 'widget-slide',
                'sections': [
                  {
                    'type': 'section',
                    'blocks': [
                      {
                        'type': 'widget',
                        'name': 'image',
                        'src': 'test.png',
                        'flex': 1,
                      },
                    ],
                  },
                ],
              },
            ],
          };
          final deck = Deck.parse(map);

          expect(deck.slides.length, 1);
          final section = deck.slides[0].sections[0];
          expect(section.blocks.length, 1);
          expect(section.blocks[0], isA<WidgetBlock>());
          expect((section.blocks[0] as WidgetBlock).name, 'image');
        });
      });

      group('schema', () {
        test('validates minimal deck', () {
          final result = Deck.schema.safeParse({
            'slides': <dynamic>[],
          });
          expect(result.isOk, isTrue);
        });

        test('validates deck with slides', () {
          final result = Deck.schema.safeParse({
            'slides': [
              {'key': 'test'},
            ],
          });
          expect(result.isOk, isTrue);
        });

        test('validates deck with full structure', () {
          final result = Deck.schema.safeParse({
            'slides': [
              {
                'key': 'full',
                'options': {'title': 'T', 'style': 'S'},
                'sections': [
                  {
                    'type': 'section',
                    'flex': 1,
                    'blocks': [
                      {'type': 'block', 'content': 'C'},
                      {'type': 'widget', 'name': 'image'},
                    ],
                  },
                ],
                'comments': ['note'],
              },
            ],
            'configuration': {
              'projectDir': '/test',
            },
          });
          expect(result.isOk, isTrue);
        });

        test('validates deck with nullable configuration', () {
          final result = Deck.schema.safeParse({
            'slides': <dynamic>[],
            'configuration': null,
          });
          expect(result.isOk, isTrue);
        });

        test('fails validation for missing slides', () {
          final result = Deck.schema.safeParse({});
          expect(result.isOk, isFalse);
        });
      });

      group('equality', () {
        test('equal decks are equal', () {
          final deck1 = Deck(
            slides: const [Slide(key: 'same')],
            configuration: DeckConfiguration(projectDir: '/same'),
          );
          final deck2 = Deck(
            slides: const [Slide(key: 'same')],
            configuration: DeckConfiguration(projectDir: '/same'),
          );

          expect(deck1, deck2);
          expect(deck1.hashCode, deck2.hashCode);
        });

        test('different slides make decks unequal', () {
          final deck1 = Deck(
            slides: const [Slide(key: 'a')],
            configuration: DeckConfiguration(),
          );
          final deck2 = Deck(
            slides: const [Slide(key: 'b')],
            configuration: DeckConfiguration(),
          );

          expect(deck1, isNot(deck2));
        });

        test('different configuration makes decks unequal', () {
          final deck1 = Deck(
            slides: const [],
            configuration: DeckConfiguration(projectDir: '/a'),
          );
          final deck2 = Deck(
            slides: const [],
            configuration: DeckConfiguration(projectDir: '/b'),
          );

          expect(deck1, isNot(deck2));
        });
      });
    });
  });
}
