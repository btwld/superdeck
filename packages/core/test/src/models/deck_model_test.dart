import 'package:superdeck_core/src/deck_workspace.dart';
import 'package:superdeck_core/src/models/block_model.dart';
import 'package:superdeck_core/src/models/deck_model.dart';
import 'package:superdeck_core/src/models/slide_model.dart';
import 'package:test/test.dart';

Map<String, Object?> _propertySchema(
  Map<String, Object?> schema,
  String property,
) {
  final properties = schema['properties'] as Map<String, Object?>;
  return Map<String, Object?>.from(properties[property] as Map);
}

void _expectSchemaIsNotNullable(Map<String, Object?> schema) {
  expect(schema['type'], isNot('null'));

  final anyOf = schema['anyOf'] as List<dynamic>?;
  if (anyOf != null) {
    final hasNullType = anyOf
        .whereType<Map>()
        .map((item) => item['type'])
        .contains('null');
    expect(hasNullType, isFalse);
  }
}

void main() {
  group('Deck Model', () {
    group('Deck', () {
      test('creates with required parameters', () {
        final deck = Deck(slides: const [], configuration: DeckWorkspace());

        expect(deck.slides, isEmpty);
        expect(deck.configuration, isNotNull);
      });

      test('creates with slides', () {
        final slides = [
          const Slide(key: 'slide-1'),
          const Slide(key: 'slide-2'),
        ];
        final deck = Deck(slides: slides, configuration: DeckWorkspace());

        expect(deck.slides.length, 2);
        expect(deck.slides[0].key, 'slide-1');
        expect(deck.slides[1].key, 'slide-2');
      });

      group('copyWith', () {
        test('copies with new slides', () {
          final original = Deck(
            slides: const [Slide(key: 'original')],
            configuration: DeckWorkspace(),
          );
          final copy = original.copyWith(slides: const [Slide(key: 'new')]);

          expect(copy.slides[0].key, 'new');
        });

        test('copies with new configuration', () {
          final original = Deck(
            slides: const [],
            configuration: DeckWorkspace(),
          );
          final copy = original.copyWith(
            configuration: DeckWorkspace(projectDir: '/new'),
          );

          expect(copy.configuration.projectDir, '/new');
        });

        test('preserves values when not specified', () {
          final original = Deck(
            slides: const [Slide(key: 'keep')],
            configuration: DeckWorkspace(projectDir: '/keep'),
          );
          final copy = original.copyWith();

          expect(copy.slides[0].key, 'keep');
          expect(copy.configuration.projectDir, '/keep');
        });
      });

      group('toMap', () {
        test('serializes empty deck', () {
          final deck = Deck(slides: const [], configuration: DeckWorkspace());
          final map = deck.toMap();

          expect(map['slides'], isEmpty);
          expect(map['configuration'], isA<Map>());
        });

        test('serializes deck with slides', () {
          final deck = Deck(
            slides: [
              Slide(
                key: 'slide-1',
                sections: [
                  SectionBlock([ContentBlock('Content')]),
                ],
              ),
            ],
            configuration: DeckWorkspace(),
          );
          final map = deck.toMap();

          expect((map['slides'] as List).length, 1);
          final slideMap = (map['slides'] as List)[0] as Map;
          expect(slideMap['key'], 'slide-1');
        });

        test('serializes deck with configuration', () {
          final deck = Deck(
            slides: const [],
            configuration: DeckWorkspace(
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
          final map = <String, dynamic>{'slides': <dynamic>[]};
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
            'configuration': {'projectDir': '/test', 'outputDir': '.superdeck'},
          };
          final deck = Deck.fromMap(map);

          expect(deck.configuration.projectDir, '/test');
          expect(deck.configuration.outputDir, '.superdeck');
        });

        test('ignores unknown configuration fields', () {
          final map = {
            'slides': <dynamic>[],
            'configuration': {'projectDir': '/test', 'customConfigField': true},
          };

          final deck = Deck.fromMap(map);

          expect(deck.configuration.projectDir, '/test');
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
                      {'type': 'block', 'content': 'Block 1', 'flex': 1},
                      {'type': 'widget', 'name': 'image', 'src': 'test.png'},
                    ],
                  },
                ],
                'notes': ['Speaker note'],
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
          expect(slide.notes, ['Speaker note']);
        });

        test(
          'preserves template and unknown slide option args via deck fromMap',
          () {
            final map = <String, dynamic>{
              'slides': [
                {
                  'key': 'slide-with-options',
                  'options': {
                    'template': 'hero-template',
                    'customArg': 'value',
                    'customCount': 42,
                  },
                },
              ],
            };

            final deck = Deck.fromMap(map);
            final options = deck.slides.single.options;

            expect(options, isNotNull);
            expect(options!.template, 'hero-template');
            expect(options.args['customArg'], 'value');
            expect(options.args['customCount'], 42);
            expect(options.args.containsKey('template'), isFalse);
          },
        );

        test('ignores unsupported legacy schemaVersion', () {
          final map = <String, dynamic>{
            'schemaVersion': 1,
            'slides': <dynamic>[],
          };

          final deck = Deck.fromMap(map);

          expect(deck.slides, isEmpty);
        });

        test('defaults missing slides to an empty deck', () {
          final deck = Deck.fromMap({});

          expect(deck.slides, isEmpty);
        });

        test('tolerates null configuration fields for legacy payloads', () {
          final deck = Deck.fromMap({
            'slides': <dynamic>[],
            'configuration': {
              'projectDir': null,
              'slidesPath': null,
              'outputDir': null,
              'assetsPath': null,
            },
          });

          expect(deck.configuration.projectDir, isNull);
          expect(deck.configuration.slidesPath, isNull);
          expect(deck.configuration.outputDir, isNull);
          expect(deck.configuration.assetsPath, isNull);
        });

        test('tolerates null slide options for legacy payloads', () {
          final deck = Deck.fromMap({
            'slides': [
              {'key': 'legacy-slide', 'options': null},
            ],
          });

          expect(deck.slides.single.options, isNull);
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
                  SectionBlock([ContentBlock('Content')]),
                ],
                notes: ['Note'],
              ),
            ],
            configuration: DeckWorkspace(
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

      group('fromMap widget blocks', () {
        test('deserializes deck with widget blocks', () {
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
          final deck = Deck.fromMap(map);

          expect(deck.slides.length, 1);
          final section = deck.slides[0].sections[0];
          expect(section.blocks.length, 1);
          expect(section.blocks[0], isA<WidgetBlock>());
          expect((section.blocks[0] as WidgetBlock).name, 'image');
        });
      });

      group('schema', () {
        test('validates minimal deck', () {
          final result = Deck.schema.safeParse({'slides': <dynamic>[]});
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
                'notes': ['note'],
              },
            ],
          });
          expect(result.isOk, isTrue);
        });

        test('fails validation for missing slides', () {
          final result = Deck.schema.safeParse({});
          expect(result.isOk, isFalse);
        });

        test('fails validation for root style field', () {
          final result = Deck.schema.safeParse({
            'slides': [
              {'key': 'test'},
            ],
            'style': {'theme': 'dark'},
          });

          expect(result.isOk, isFalse);
        });

        test(
          'fails validation when configuration optional fields are explicitly null',
          () {
            for (final field in [
              'projectDir',
              'slidesPath',
              'outputDir',
              'assetsPath',
            ]) {
              final result = Deck.schema.safeParse({
                'slides': <dynamic>[],
                'configuration': {field: null},
              });

              expect(result.isOk, isFalse);
            }
          },
        );

        test('fails validation when unsupported schemaVersion is present', () {
          final result = Deck.schema.safeParse({
            'schemaVersion': 1,
            'slides': <dynamic>[],
          });

          expect(result.isOk, isFalse);
        });

        test('json schema also rejects null for optional contract fields', () {
          final jsonSchema = Deck.schema.toJsonSchema();

          final configurationSchema = _propertySchema(
            jsonSchema,
            'configuration',
          );
          final configurationProjectDirSchema = _propertySchema(
            configurationSchema,
            'projectDir',
          );
          _expectSchemaIsNotNullable(configurationProjectDirSchema);

          final slidesSchema = _propertySchema(jsonSchema, 'slides');
          final slideItemSchema = Map<String, Object?>.from(
            slidesSchema['items'] as Map,
          );
          final slideOptionsSchema = _propertySchema(
            slideItemSchema,
            'options',
          );
          final slideOptionsTitleSchema = _propertySchema(
            slideOptionsSchema,
            'title',
          );
          _expectSchemaIsNotNullable(slideOptionsTitleSchema);
        });
      });

      group('equality', () {
        test('equal decks are equal', () {
          final deck1 = Deck(
            slides: const [Slide(key: 'same')],
            configuration: DeckWorkspace(projectDir: '/same'),
          );
          final deck2 = Deck(
            slides: const [Slide(key: 'same')],
            configuration: DeckWorkspace(projectDir: '/same'),
          );

          expect(deck1, deck2);
          expect(deck1.hashCode, deck2.hashCode);
        });

        test('different slides make decks unequal', () {
          final deck1 = Deck(
            slides: const [Slide(key: 'a')],
            configuration: DeckWorkspace(),
          );
          final deck2 = Deck(
            slides: const [Slide(key: 'b')],
            configuration: DeckWorkspace(),
          );

          expect(deck1, isNot(deck2));
        });

        test('different configuration makes decks unequal', () {
          final deck1 = Deck(
            slides: const [],
            configuration: DeckWorkspace(projectDir: '/a'),
          );
          final deck2 = Deck(
            slides: const [],
            configuration: DeckWorkspace(projectDir: '/b'),
          );

          expect(deck1, isNot(deck2));
        });
      });
    });
  });
}
