import 'package:superdeck_core/src/deck/block_model.dart';
import 'package:superdeck_core/src/deck/slide_contract.dart';
import 'package:superdeck_core/src/deck/slide_model.dart';
import 'package:test/test.dart';

Map<String, Object?> _propertySchema(
  Map<String, Object?> schema,
  String property,
) {
  final properties = schema['properties'] as Map<String, Object?>;
  return Map<String, Object?>.from(properties[property] as Map);
}

Map<String, Object?> _arrayItemSchema(
  Map<String, Object?> schema,
  String property,
) {
  final arraySchema = _propertySchema(schema, property);
  return Map<String, Object?>.from(arraySchema['items'] as Map);
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
  group('slides contract', () {
    test('parses a raw array of slides', () {
      final slides = parseSlidesContract([
        {'key': 'slide-1'},
        {'key': 'slide-2'},
      ]);

      expect(slides.map((slide) => slide.key), ['slide-1', 'slide-2']);
    });

    test('preserves slide template and custom args', () {
      final slides = parseSlidesContract([
        {
          'key': 'slide-with-options',
          'options': {
            'template': 'hero-template',
            'customArg': 'value',
            'customCount': 42,
          },
        },
      ]);

      final options = slides.single.options;
      expect(options, isNotNull);
      expect(options!.template, 'hero-template');
      expect(options.args['customArg'], 'value');
      expect(options.args['customCount'], 42);
      expect(options.args.containsKey('template'), isFalse);
    });

    test('round-trips slide payloads through toMap', () {
      final original = [
        Slide(
          key: 'rt-slide',
          options: SlideOptions(title: 'RT Title'),
          sections: [
            SectionBlock([ContentBlock('Content')]),
          ],
          comments: ['Note'],
        ),
      ];

      final restored = parseSlidesContract(
        original.map((slide) => slide.toMap()).toList(),
      );

      expect(restored, original);
    });

    test('schema validates a minimal slide list', () {
      expect(slidesContractSchema.safeParse(<dynamic>[]).isOk, isTrue);
    });

    test('json schema exports an array contract', () {
      final jsonSchema = slidesContractSchema.toJsonSchema();

      expect(jsonSchema['type'], 'array');

      final itemsSchema = Map<String, Object?>.from(jsonSchema['items'] as Map);
      final slideOptionsSchema = _propertySchema(itemsSchema, 'options');
      final slideOptionsTitleSchema = _propertySchema(
        slideOptionsSchema,
        'title',
      );
      _expectSchemaIsNotNullable(slideOptionsTitleSchema);
    });

    test('json schema exports closed section options', () {
      final jsonSchema = slidesContractSchema.toJsonSchema();
      final itemsSchema = Map<String, Object?>.from(jsonSchema['items'] as Map);
      final sectionSchema = _arrayItemSchema(itemsSchema, 'sections');
      final sectionProperties = Map<String, Object?>.from(
        sectionSchema['properties'] as Map,
      );

      expect(sectionSchema['additionalProperties'], isFalse);
      expect(sectionProperties.keys, containsAll(['type', 'align', 'flex']));
      expect(sectionProperties.containsKey('blocks'), isTrue);
      expect(sectionProperties.containsKey('scrollable'), isFalse);
    });
  });
}
