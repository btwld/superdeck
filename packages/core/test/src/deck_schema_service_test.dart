import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('DeckSchemaService', () {
    late DeckSchemaService service;

    setUp(() {
      service = DeckSchemaService.instance;
      service.clearCache();
    });

    group('instance', () {
      test('returns singleton instance', () {
        final instance1 = DeckSchemaService.instance;
        final instance2 = DeckSchemaService.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('schemaVersion', () {
      test('has a valid version string', () {
        expect(DeckSchemaService.schemaVersion, isNotEmpty);
        expect(
          DeckSchemaService.schemaVersion,
          matches(RegExp(r'^\d+\.\d+\.\d+$')),
        );
      });
    });

    group('schemas', () {
      test('deckSchema returns ObjectSchema', () {
        expect(service.deckSchema, isA<ObjectSchema>());
      });

      test('slideSchema returns ObjectSchema', () {
        expect(service.slideSchema, isA<ObjectSchema>());
      });

      test('sectionSchema returns ObjectSchema', () {
        expect(service.sectionSchema, isA<ObjectSchema>());
      });

      test('contentBlockSchema returns ObjectSchema', () {
        expect(service.contentBlockSchema, isA<ObjectSchema>());
      });

      test('widgetBlockSchema returns ObjectSchema', () {
        expect(service.widgetBlockSchema, isA<ObjectSchema>());
      });

      test('configurationSchema returns ObjectSchema', () {
        expect(service.configurationSchema, isA<ObjectSchema>());
      });
    });

    group('toJsonSchema', () {
      test('returns valid JSON schema structure', () {
        final schema = service.toJsonSchema();

        expect(schema['\$schema'], contains('json-schema.org'));
        expect(schema['title'], 'SuperDeck');
        expect(schema['type'], 'object');
        expect(schema['required'], contains('slides'));
      });

      test('includes slides array definition', () {
        final schema = service.toJsonSchema();
        final properties = schema['properties'] as Map<String, dynamic>;

        expect(properties.containsKey('slides'), isTrue);
        expect(properties['slides']['type'], 'array');
      });

      test('includes configuration definition', () {
        final schema = service.toJsonSchema();
        final properties = schema['properties'] as Map<String, dynamic>;

        expect(properties.containsKey('configuration'), isTrue);
        expect(properties['configuration']['type'], 'object');
      });

      test('includes version', () {
        final schema = service.toJsonSchema();

        expect(schema['version'], DeckSchemaService.schemaVersion);
      });

      test('caches result', () {
        final schema1 = service.toJsonSchema();
        final schema2 = service.toJsonSchema();

        expect(identical(schema1, schema2), isTrue);
      });

      test('slide schema includes key property', () {
        final schema = service.toJsonSchema();
        final slides = schema['properties']['slides'] as Map<String, dynamic>;
        final slideSchema = slides['items'] as Map<String, dynamic>;
        final slideProps = slideSchema['properties'] as Map<String, dynamic>;

        expect(slideProps.containsKey('key'), isTrue);
        expect(slideProps['key']['type'], 'string');
      });

      test('slide schema includes sections array', () {
        final schema = service.toJsonSchema();
        final slides = schema['properties']['slides'] as Map<String, dynamic>;
        final slideSchema = slides['items'] as Map<String, dynamic>;
        final slideProps = slideSchema['properties'] as Map<String, dynamic>;

        expect(slideProps.containsKey('sections'), isTrue);
        expect(slideProps['sections']['type'], 'array');
      });

      test('block schema includes alignment enum', () {
        final schema = service.toJsonSchema();
        final slides = schema['properties']['slides'] as Map<String, dynamic>;
        final slideSchema = slides['items'] as Map<String, dynamic>;
        final slideProps = slideSchema['properties'] as Map<String, dynamic>;
        final sections = slideProps['sections'] as Map<String, dynamic>;
        final sectionSchema = sections['items'] as Map<String, dynamic>;
        final sectionProps = sectionSchema['properties'] as Map<String, dynamic>;

        expect(sectionProps.containsKey('align'), isTrue);
        expect(sectionProps['align']['enum'], isNotEmpty);
        expect(sectionProps['align']['enum'], contains('center'));
      });
    });

    group('generateSignature', () {
      test('returns non-empty string', () {
        final signature = service.generateSignature();

        expect(signature, isNotEmpty);
      });

      test('returns consistent signature', () {
        final signature1 = service.generateSignature();
        final signature2 = service.generateSignature();

        expect(signature1, signature2);
      });

      test('returns 16 character signature', () {
        final signature = service.generateSignature();

        expect(signature.length, 16);
      });

      test('caches result', () {
        final signature1 = service.generateSignature();
        service.clearCache();
        final signature2 = service.generateSignature();

        // Even after cache clear, should be same since schema hasn't changed
        expect(signature1, signature2);
      });
    });

    group('validate', () {
      test('validates valid deck data', () {
        final validData = {
          'slides': [
            {
              'key': 'slide1',
              'sections': [],
              'comments': [],
            },
          ],
          'configuration': {},
        };

        final result = service.validate(validData);

        expect(result.isValid, isTrue);
        expect(result.deck, isA<Deck>());
        expect(result.errors, isEmpty);
        expect(result.signature, isNotEmpty);
      });

      test('validates minimal valid deck', () {
        final minimalData = {
          'slides': [],
        };

        final result = service.validate(minimalData);

        expect(result.isValid, isTrue);
        expect(result.deck.slides, isEmpty);
      });

      test('validates deck with content block', () {
        final data = {
          'slides': [
            {
              'key': 'slide1',
              'sections': [
                {
                  'type': 'section',
                  'flex': 1,
                  'blocks': [
                    {
                      'type': 'block',
                      'content': '# Hello World',
                      'flex': 1,
                    },
                  ],
                },
              ],
            },
          ],
        };

        final result = service.validate(data);

        expect(result.isValid, isTrue);
        expect(result.deck.slides.first.sections.first.blocks, hasLength(1));
      });

      test('validates deck with widget block', () {
        final data = {
          'slides': [
            {
              'key': 'slide1',
              'sections': [
                {
                  'type': 'section',
                  'blocks': [
                    {
                      'type': 'widget',
                      'name': 'myWidget',
                      'customArg': 'value',
                    },
                  ],
                },
              ],
            },
          ],
        };

        final result = service.validate(data);

        expect(result.isValid, isTrue);
        final block =
            result.deck.slides.first.sections.first.blocks.first as WidgetBlock;
        expect(block.name, 'myWidget');
        expect(block.args['customArg'], 'value');
      });

      test('returns errors for invalid data', () {
        final invalidData = {
          'slides': 'not an array',
        };

        final result = service.validate(invalidData);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.signatureMismatch, isFalse);
      });

      test('includes signature in result', () {
        final data = {'slides': []};

        final result = service.validate(data);

        expect(result.signature, service.generateSignature());
      });

      test('throws StateError when accessing deck on invalid result', () {
        final invalidData = {'slides': 'invalid'};

        final result = service.validate(invalidData);

        expect(() => result.deck, throwsStateError);
      });

      test('returns null for deckOrNull on invalid result', () {
        final invalidData = {'slides': 'invalid'};

        final result = service.validate(invalidData);

        expect(result.deckOrNull, isNull);
      });
    });

    group('validateWithSignature', () {
      test('validates with matching signature', () {
        final data = {'slides': []};
        final expectedSignature = service.generateSignature();

        final result = service.validateWithSignature(
          data: data,
          expectedSignature: expectedSignature,
        );

        expect(result.isValid, isTrue);
        expect(result.signatureMismatch, isFalse);
      });

      test('fails with mismatched signature', () {
        final data = {'slides': []};

        final result = service.validateWithSignature(
          data: data,
          expectedSignature: 'invalid-signature',
        );

        expect(result.isValid, isFalse);
        expect(result.signatureMismatch, isTrue);
        expect(result.errors.first.message, contains('signature mismatch'));
      });

      test('includes both signatures in error message', () {
        final data = {'slides': []};
        final currentSignature = service.generateSignature();

        final result = service.validateWithSignature(
          data: data,
          expectedSignature: 'wrong-sig',
        );

        expect(result.errors.first.message, contains('wrong-sig'));
        expect(result.errors.first.message, contains(currentSignature));
      });
    });

    group('toPromptSchema', () {
      test('returns non-empty string', () {
        final prompt = service.toPromptSchema();

        expect(prompt, isNotEmpty);
      });

      test('includes version', () {
        final prompt = service.toPromptSchema();

        expect(prompt, contains(DeckSchemaService.schemaVersion));
      });

      test('includes signature', () {
        final prompt = service.toPromptSchema();
        final signature = service.generateSignature();

        expect(prompt, contains(signature));
      });

      test('includes JSON schema', () {
        final prompt = service.toPromptSchema();

        expect(prompt, contains('```json'));
        expect(prompt, contains('"type": "object"'));
      });

      test('includes instructions', () {
        final prompt = service.toPromptSchema();

        expect(prompt, contains('Instructions'));
        expect(prompt, contains('validation'));
      });
    });

    group('clearCache', () {
      test('clears cached signature', () {
        // Generate and cache
        service.generateSignature();
        service.toJsonSchema();

        // Clear cache
        service.clearCache();

        // Should regenerate (same value but new objects)
        final newSignature = service.generateSignature();
        expect(newSignature, isNotEmpty);
      });
    });

    group('DeckValidationResult', () {
      test('success result has valid deck', () {
        final deck = Deck(
          slides: [],
          configuration: DeckConfiguration(),
        );

        final result = DeckValidationResult.success(
          deck: deck,
          signature: 'test-sig',
        );

        expect(result.isValid, isTrue);
        expect(result.deck, deck);
        expect(result.errors, isEmpty);
        expect(result.signatureMismatch, isFalse);
      });

      test('failure result has errors', () {
        final result = DeckValidationResult.failure(
          errors: [DeckValidationError(path: '/slides', message: 'Invalid')],
          signature: 'test-sig',
        );

        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.deckOrNull, isNull);
      });

      test('toMap includes all fields for success', () {
        final deck = Deck(
          slides: [],
          configuration: DeckConfiguration(),
        );

        final result = DeckValidationResult.success(
          deck: deck,
          signature: 'test-sig',
        );

        final map = result.toMap();

        expect(map['isValid'], isTrue);
        expect(map['signature'], 'test-sig');
        expect(map['signatureMismatch'], isFalse);
        expect(map['deck'], isA<Map>());
        expect(map.containsKey('errors'), isFalse);
      });

      test('toMap includes errors for failure', () {
        final result = DeckValidationResult.failure(
          errors: [DeckValidationError(path: '/test', message: 'Error')],
          signature: 'test-sig',
        );

        final map = result.toMap();

        expect(map['isValid'], isFalse);
        expect(map['errors'], isA<List>());
        expect((map['errors'] as List).first['path'], '/test');
      });
    });

    group('DeckValidationError', () {
      test('creates with path and message', () {
        final error = DeckValidationError(
          path: '/slides/0/key',
          message: 'Required field',
        );

        expect(error.path, '/slides/0/key');
        expect(error.message, 'Required field');
      });

      test('toMap returns correct structure', () {
        final error = DeckValidationError(
          path: '/path',
          message: 'msg',
        );

        final map = error.toMap();

        expect(map['path'], '/path');
        expect(map['message'], 'msg');
      });

      test('toString is descriptive', () {
        final error = DeckValidationError(
          path: '/test',
          message: 'Error message',
        );

        expect(error.toString(), contains('/test'));
        expect(error.toString(), contains('Error message'));
      });
    });

    group('integration with real deck data', () {
      test('validates complex deck structure', () {
        final complexData = {
          'slides': [
            {
              'key': 'intro',
              'options': {
                'title': 'Introduction',
                'style': 'default',
              },
              'sections': [
                {
                  'type': 'section',
                  'flex': 2,
                  'align': 'center',
                  'blocks': [
                    {
                      'type': 'block',
                      'content': '# Welcome\n\nThis is a presentation.',
                      'flex': 1,
                      'align': 'centerLeft',
                    },
                    {
                      'type': 'widget',
                      'name': 'imageGallery',
                      'images': ['a.png', 'b.png'],
                    },
                  ],
                },
              ],
              'comments': ['Speaker note 1', 'Speaker note 2'],
            },
            {
              'key': 'slide2',
              'sections': [],
            },
          ],
          'configuration': {
            'projectDir': '/my/project',
            'slidesPath': 'slides.md',
          },
        };

        final result = service.validate(complexData);

        expect(result.isValid, isTrue);
        expect(result.deck.slides, hasLength(2));
        expect(result.deck.slides.first.key, 'intro');
        expect(result.deck.slides.first.options?.title, 'Introduction');
        expect(result.deck.slides.first.sections.first.blocks, hasLength(2));
        expect(result.deck.slides.first.comments, hasLength(2));
        expect(result.deck.configuration.projectDir, '/my/project');
      });

      test('supports legacy column block type', () {
        final data = {
          'slides': [
            {
              'key': 'slide1',
              'sections': [
                {
                  'type': 'section',
                  'blocks': [
                    {
                      'type': 'column', // Legacy type
                      'content': 'Legacy content',
                    },
                  ],
                },
              ],
            },
          ],
        };

        final result = service.validate(data);

        expect(result.isValid, isTrue);
        expect(
          result.deck.slides.first.sections.first.blocks.first,
          isA<ContentBlock>(),
        );
      });
    });
  });
}
