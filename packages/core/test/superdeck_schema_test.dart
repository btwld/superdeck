import 'dart:convert';

import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('SuperdeckSchema', () {
    group('toJsonSchema', () {
      test('generates valid JSON Schema', () {
        final schema = SuperdeckSchema.toJsonSchema();

        expect(schema, isA<Map<String, Object?>>());
        expect(schema['type'], equals('object'));
        expect(schema['properties'], isA<Map>());
      });

      test('includes slides property', () {
        final schema = SuperdeckSchema.toJsonSchema();
        final properties = schema['properties'] as Map<String, Object?>;

        expect(properties.containsKey('slides'), isTrue);
      });

      test('includes configuration property', () {
        final schema = SuperdeckSchema.toJsonSchema();
        final properties = schema['properties'] as Map<String, Object?>;

        expect(properties.containsKey('configuration'), isTrue);
      });

      test('toJsonSchemaString returns valid JSON', () {
        final schemaString = SuperdeckSchema.toJsonSchemaString();

        expect(() => jsonDecode(schemaString), returnsNormally);
      });

      test('toJsonSchemaString pretty prints by default', () {
        final schemaString = SuperdeckSchema.toJsonSchemaString();

        expect(schemaString, contains('\n'));
        expect(schemaString, contains('  '));
      });

      test('toJsonSchemaString compact mode', () {
        final schemaString = SuperdeckSchema.toJsonSchemaString(pretty: false);

        expect(schemaString.contains('\n'), isFalse);
      });
    });

    group('generateSignature', () {
      test('returns a consistent signature', () {
        final sig1 = SuperdeckSchema.generateSignature();
        final sig2 = SuperdeckSchema.generateSignature();

        expect(sig1, equals(sig2));
      });

      test('signature is a valid SHA-256 hash (64 chars)', () {
        final signature = SuperdeckSchema.generateSignature();

        expect(signature.length, equals(64));
        expect(RegExp(r'^[a-f0-9]+$').hasMatch(signature), isTrue);
      });

      test('short signature is 8 characters', () {
        final shortSig = SuperdeckSchema.generateShortSignature();

        expect(shortSig.length, equals(8));
        expect(RegExp(r'^[a-f0-9]+$').hasMatch(shortSig), isTrue);
      });

      test('short signature is prefix of full signature', () {
        final fullSig = SuperdeckSchema.generateSignature();
        final shortSig = SuperdeckSchema.generateShortSignature();

        expect(fullSig.startsWith(shortSig), isTrue);
      });
    });

    group('validate', () {
      test('validates valid deck data', () {
        final validDeck = {
          'slides': [
            {
              'key': 'test123',
              'sections': [
                {
                  'type': 'section',
                  'blocks': [
                    {
                      'type': 'block',
                      'content': '# Hello World',
                    }
                  ],
                }
              ],
            }
          ],
          'configuration': {},
        };

        final result = SuperdeckSchema.validate(validDeck);

        expect(result.isOk, isTrue);
      });

      test('validates deck with empty slides', () {
        final deck = {
          'slides': <Map<String, dynamic>>[],
          'configuration': {},
        };

        final result = SuperdeckSchema.validate(deck);

        expect(result.isOk, isTrue);
      });

      test('rejects deck without slides array', () {
        final invalidDeck = {
          'configuration': {},
        };

        final result = SuperdeckSchema.validate(invalidDeck);

        // The slides field should be required or have a default
        // This test documents the current behavior
        expect(result.isOk, isFalse);
      });

      test('validates deck with widget block', () {
        final deck = {
          'slides': [
            {
              'key': 'widget-slide',
              'sections': [
                {
                  'type': 'section',
                  'blocks': [
                    {
                      'type': 'widget',
                      'name': 'myWidget',
                      'customArg': 'value',
                    }
                  ],
                }
              ],
            }
          ],
        };

        final result = SuperdeckSchema.validate(deck);

        expect(result.isOk, isTrue);
      });
    });

    group('validateOrThrow', () {
      test('does not throw for valid deck', () {
        final validDeck = {
          'slides': [
            {
              'key': 'test123',
              'sections': [],
            }
          ],
        };

        expect(() => SuperdeckSchema.validateOrThrow(validDeck), returnsNormally);
      });

      test('throws for invalid deck', () {
        final invalidDeck = <String, dynamic>{};

        expect(
          () => SuperdeckSchema.validateOrThrow(invalidDeck),
          throwsA(isA<SchemaError>()),
        );
      });
    });

    group('parseJson', () {
      test('parses valid JSON string', () {
        final jsonString = '''
        {
          "slides": [
            {
              "key": "test123",
              "sections": []
            }
          ],
          "configuration": {}
        }
        ''';

        final result = SuperdeckSchema.parseJson(jsonString);

        expect(result.isOk, isTrue);
        expect(result.getOrNull(), isA<Deck>());
        expect(result.getOrNull()?.slides.length, equals(1));
      });

      test('returns error for invalid JSON', () {
        final invalidJson = 'not valid json';

        final result = SuperdeckSchema.parseJson(invalidJson);

        expect(result.isOk, isFalse);
      });

      test('returns error for valid JSON but invalid schema', () {
        final invalidSchema = '{"invalid": "data"}';

        final result = SuperdeckSchema.parseJson(invalidSchema);

        expect(result.isOk, isFalse);
      });
    });

    group('generateSchemaPrompt', () {
      test('includes schema signature', () {
        final prompt = SuperdeckSchema.generateSchemaPrompt();
        final shortSig = SuperdeckSchema.generateShortSignature();

        expect(prompt, contains(shortSig));
      });

      test('includes JSON Schema', () {
        final prompt = SuperdeckSchema.generateSchemaPrompt();

        expect(prompt, contains('"type"'));
        expect(prompt, contains('"properties"'));
      });

      test('includes content alignment values', () {
        final prompt = SuperdeckSchema.generateSchemaPrompt();

        expect(prompt, contains('topLeft'));
        expect(prompt, contains('center'));
        expect(prompt, contains('bottomRight'));
      });

      test('includes example', () {
        final prompt = SuperdeckSchema.generateSchemaPrompt();

        expect(prompt, contains('## Example'));
        expect(prompt, contains('"slides"'));
      });
    });

    group('verifyResponseSignature', () {
      test('returns true when signature is present', () {
        final shortSig = SuperdeckSchema.generateShortSignature();
        final response = 'Here is the deck [schema:$shortSig]';

        expect(SuperdeckSchema.verifyResponseSignature(response), isTrue);
      });

      test('returns false when signature is missing', () {
        final response = 'Here is the deck without signature';

        expect(SuperdeckSchema.verifyResponseSignature(response), isFalse);
      });

      test('returns false when signature is wrong', () {
        final response = 'Here is the deck [schema:wrongsig]';

        expect(SuperdeckSchema.verifyResponseSignature(response), isFalse);
      });
    });

    group('extractJsonFromResponse', () {
      test('extracts JSON from code block', () {
        final response = '''
Here is the deck:

```json
{"slides": []}
```

Done!
''';

        final json = SuperdeckSchema.extractJsonFromResponse(response);

        expect(json, equals('{"slides": []}'));
      });

      test('extracts raw JSON object', () {
        final response = '{"slides": [], "configuration": {}}';

        final json = SuperdeckSchema.extractJsonFromResponse(response);

        expect(json, equals('{"slides": [], "configuration": {}}'));
      });

      test('extracts raw JSON array', () {
        final response = '[{"key": "1"}, {"key": "2"}]';

        final json = SuperdeckSchema.extractJsonFromResponse(response);

        expect(json, equals('[{"key": "1"}, {"key": "2"}]'));
      });

      test('returns null for non-JSON response', () {
        final response = 'This is just plain text without any JSON.';

        final json = SuperdeckSchema.extractJsonFromResponse(response);

        expect(json, isNull);
      });

      test('handles multiline JSON in code block', () {
        final response = '''
```json
{
  "slides": [
    {
      "key": "test"
    }
  ]
}
```
''';

        final json = SuperdeckSchema.extractJsonFromResponse(response);

        expect(json, isNotNull);
        expect(() => jsonDecode(json!), returnsNormally);
      });
    });

    group('parseResponse', () {
      test('parses valid response with code block', () {
        final shortSig = SuperdeckSchema.generateShortSignature();
        final response = '''
Here is the superdeck.json:

```json
{
  "slides": [
    {
      "key": "slide1",
      "sections": []
    }
  ],
  "configuration": {}
}
```

[schema:$shortSig]
''';

        final result = SuperdeckSchema.parseResponse(response);

        expect(result.isOk, isTrue);
        expect(result.getOrNull()?.slides.length, equals(1));
      });

      test('returns error for response without JSON', () {
        final response = 'I could not generate the deck.';

        final result = SuperdeckSchema.parseResponse(response);

        expect(result.isOk, isFalse);
      });

      test('returns error for invalid schema in response', () {
        final response = '''
```json
{"invalid": "structure"}
```
''';

        final result = SuperdeckSchema.parseResponse(response);

        expect(result.isOk, isFalse);
      });
    });

    group('getSchemaInfo', () {
      test('returns schema information map', () {
        final info = SuperdeckSchema.getSchemaInfo();

        expect(info['signature'], isA<String>());
        expect(info['shortSignature'], isA<String>());
        expect(info['version'], equals('1.0.0'));
        expect(info['schemas'], isA<Map>());
        expect(info['contentAlignments'], isA<List>());
      });
    });
  });

  group('Deck', () {
    group('schema', () {
      test('has description', () {
        // Schema has description method called
        expect(Deck.schema, isNotNull);
      });
    });

    group('parse', () {
      test('validates and parses valid deck', () {
        final map = {
          'slides': [
            {
              'key': 'test',
              'sections': [],
            }
          ],
          'configuration': {},
        };

        final deck = Deck.parse(map);

        expect(deck.slides.length, equals(1));
        expect(deck.slides.first.key, equals('test'));
      });

      test('throws on invalid data', () {
        final invalidMap = <String, dynamic>{};

        expect(() => Deck.parse(invalidMap), throwsA(isA<SchemaError>()));
      });
    });

    group('safeParse', () {
      test('returns Ok for valid deck', () {
        final map = {
          'slides': [
            {
              'key': 'test',
              'sections': [],
            }
          ],
        };

        final result = Deck.safeParse(map);

        expect(result.isOk, isTrue);
        expect(result.getOrNull()?.slides.first.key, equals('test'));
      });

      test('returns Fail for invalid deck', () {
        final invalidMap = <String, dynamic>{};

        final result = Deck.safeParse(invalidMap);

        expect(result.isOk, isFalse);
      });
    });
  });

  group('Slide', () {
    test('schema validates slide with all fields', () {
      final slideMap = {
        'key': 'slide123',
        'options': {
          'title': 'My Slide',
          'style': 'default',
        },
        'sections': [
          {
            'type': 'section',
            'blocks': [],
          }
        ],
        'comments': ['Speaker note'],
      };

      expect(() => Slide.parse(slideMap), returnsNormally);
    });

    test('schema validates minimal slide', () {
      final slideMap = {
        'key': 'minimal',
      };

      expect(() => Slide.parse(slideMap), returnsNormally);
    });
  });

  group('Block schemas', () {
    test('ContentBlock schema validates', () {
      final blockMap = {
        'type': 'block',
        'content': '# Hello',
        'align': 'center',
        'flex': 2,
        'scrollable': true,
      };

      expect(() => ContentBlock.schema.parse(blockMap), returnsNormally);
    });

    test('WidgetBlock schema validates', () {
      final blockMap = {
        'type': 'widget',
        'name': 'myWidget',
        'customProp': 'value',
      };

      expect(() => WidgetBlock.schema.parse(blockMap), returnsNormally);
    });

    test('SectionBlock schema validates', () {
      final blockMap = {
        'type': 'section',
        'blocks': [
          {
            'type': 'block',
            'content': 'test',
          }
        ],
      };

      expect(() => SectionBlock.schema.parse(blockMap), returnsNormally);
    });

    test('Block discriminated schema selects correct type', () {
      final contentBlock = {
        'type': 'block',
        'content': 'hello',
      };

      final widgetBlock = {
        'type': 'widget',
        'name': 'test',
      };

      expect(() => Block.parse(contentBlock), returnsNormally);
      expect(() => Block.parse(widgetBlock), returnsNormally);

      final parsedContent = Block.parse(contentBlock);
      final parsedWidget = Block.parse(widgetBlock);

      expect(parsedContent, isA<ContentBlock>());
      expect(parsedWidget, isA<WidgetBlock>());
    });
  });
}
