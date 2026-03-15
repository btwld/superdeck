import 'package:ack/ack.dart';
import 'package:superdeck_core/src/deck/block_model.dart';
import 'package:superdeck_core/src/deck/deck_model.dart';
import 'package:superdeck_core/src/deck/slide_model.dart';
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
  if (anyOf == null) {
    return;
  }

  final hasNullType = anyOf
      .whereType<Map>()
      .map((item) => item['type'])
      .contains('null');
  expect(hasNullType, isFalse);
}

void main() {
  group('Deck', () {
    test('creates with slides', () {
      final deck = Deck(
        slides: [
          Slide(key: 'slide-1'),
          Slide(key: 'slide-2'),
        ],
      );

      expect(deck.slides, hasLength(2));
    });

    test('slides list is unmodifiable', () {
      final deck = Deck(slides: [Slide(key: 'slide-1')]);

      expect(
        () => (deck.slides as List).add(Slide(key: 'slide-2')),
        throwsUnsupportedError,
      );
    });

    test('copyWith updates values and preserves unspecified fields', () {
      final original = Deck(slides: [Slide(key: 'original')]);

      final copy = original.copyWith(slides: [Slide(key: 'updated')]);

      expect(copy.slides.single.key, 'updated');
    });

    test('toMap serializes slides without runtime configuration', () {
      final deck = Deck(slides: [Slide(key: 'slide-1')]);

      final map = deck.toMap();

      expect(map.containsKey('revision'), isFalse);
      expect((map['slides'] as List).single, containsPair('key', 'slide-1'));
      expect(map.containsKey('configuration'), isFalse);
    });

    test('fromMap deserializes minimal map', () {
      final deck = Deck.fromMap({
        'slides': [
          {'key': 'slide-1'},
        ],
      });

      expect(deck.slides.single.key, 'slide-1');
    });

    test('parse preserves slide template and custom args', () {
      final deck = Deck.parse({
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
      });

      final options = deck.slides.single.options;
      expect(options, isNotNull);
      expect(options!.template, 'hero-template');
      expect(options.args['customArg'], 'value');
      expect(options.args['customCount'], 42);
      expect(options.args.containsKey('template'), isFalse);
    });

    test('parse rejects missing slides', () {
      expect(
        () => Deck.parse({}),
        throwsA(
          isA<AckException>().having(
            (error) => error.toJson(),
            'message',
            contains('slides'),
          ),
        ),
      );
    });

    test('parse rejects unsupported legacy schemaVersion', () {
      expect(
        () => Deck.parse({'schemaVersion': 1, 'slides': <dynamic>[]}),
        throwsA(isA<AckException>()),
      );
    });

    test('parse ignores legacy configuration payloads', () {
      final deck = Deck.parse({
        'slides': [
          {'key': 'slide-1'},
        ],
        'configuration': {'projectDir': '/old', 'slidesPath': 'custom.md'},
      });

      expect(deck.slides.single.key, 'slide-1');
    });

    test('round-trips through toMap/fromMap', () {
      final original = Deck(
        slides: [
          Slide(
            key: 'rt-slide',
            options: SlideOptions(title: 'RT Title'),
            sections: [
              SectionBlock([ContentBlock('Content')]),
            ],
            comments: ['Note'],
          ),
        ],
      );

      final restored = Deck.fromMap(original.toMap());

      expect(restored, original);
    });

    test('schema validates minimal deck', () {
      expect(Deck.schema.safeParse({'slides': <dynamic>[]}).isOk, isTrue);
    });

    test('json schema keeps optional fields non-nullable', () {
      final jsonSchema = Deck.schema.toJsonSchema();

      final slidesSchema = _propertySchema(jsonSchema, 'slides');
      final slideItemSchema = Map<String, Object?>.from(
        slidesSchema['items'] as Map,
      );
      final slideOptionsSchema = _propertySchema(slideItemSchema, 'options');
      final slideOptionsTitleSchema = _propertySchema(
        slideOptionsSchema,
        'title',
      );
      _expectSchemaIsNotNullable(slideOptionsTitleSchema);
    });

    test('equality tracks slides', () {
      final deck1 = Deck(slides: [Slide(key: 'same')]);
      final deck2 = Deck(slides: [Slide(key: 'same')]);
      final deck3 = Deck(slides: [Slide(key: 'different')]);

      expect(deck1, deck2);
      expect(deck1.hashCode, deck2.hashCode);
      expect(deck1, isNot(deck3));
    });
  });
}
