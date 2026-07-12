import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;
import 'package:playground/features/ai/quick_agent/core/engine/schemas/deck_schemas.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/google_schema_adapter.dart';
import 'package:superdeck_core/superdeck_core.dart'
    show Slide, aiSlideSchema;

Map<String, Object?> validSlide({
  Map<String, Object?>? block,
  Map<String, Object?>? section,
}) {
  return {
    'key': 'slide-intro',
    'sections': [
      {
        'type': 'section',
        ...?section,
        'blocks': [
          {'type': 'block', 'content': '# Hello', ...?block},
        ],
      },
    ],
  };
}

void main() {
  group('slideGenerationSchema (Google adapter)', () {
    test('adapts with the full canonical block surface intact', () {
      final result = GoogleSchemaAdapter().adapt(
        slideGenerationSchema.toJsonSchemaBuilder(),
      );

      expect(result.schema, isNotNull);

      google_ai.Schema property(google_ai.Schema schema, String key) {
        final value = schema.properties[key];
        expect(value, isNotNull, reason: 'missing property "$key"');
        return value!;
      }

      final slides = property(result.schema!, 'slides').items!;
      final sections = property(slides, 'sections').items!;
      expect(
        sections.properties.keys,
        containsAll(['type', 'align', 'flex', 'spacing', 'blocks']),
      );
      expect(sections.properties.containsKey('scrollable'), isFalse);
      expect(property(sections, 'flex').minimum, 1);
      expect(property(sections, 'spacing').minimum, 0);

      final blocks = property(sections, 'blocks').items!;
      expect(
        blocks.properties.keys,
        containsAll([
          'type',
          'content',
          'name',
          'align',
          'flex',
          'margin',
          'padding',
          'scrollable',
        ]),
      );
      expect(
        property(blocks, 'margin').properties.keys,
        containsAll(['top', 'right', 'bottom', 'left']),
      );
      expect(property(blocks, 'align').enum$, contains('bottomRight'));
      expect(property(blocks, 'flex').minimum, 1);
      expect(
        result.errors.where(
          (error) =>
              error.message.contains('minimum') ||
              error.message.contains('exclusiveMinimum'),
        ),
        isEmpty,
      );
    });

    test('preserves supported numeric bounds exactly', () {
      final result = GoogleSchemaAdapter().adapt(
        dsb.Schema.fromMap({
          'type': 'object',
          'properties': {
            'boundedNumber': {'type': 'number', 'minimum': 1.5, 'maximum': 9.5},
            'boundedInteger': {
              'type': 'integer',
              'exclusiveMinimum': 0,
              'exclusiveMaximum': 10,
            },
          },
        }),
      );

      final boundedNumber = result.schema!.properties['boundedNumber']!;
      final boundedInteger = result.schema!.properties['boundedInteger']!;

      expect(boundedNumber.minimum, 1.5);
      expect(boundedNumber.maximum, 9.5);
      expect(boundedInteger.minimum, 1);
      expect(boundedInteger.maximum, 9);
      expect(result.errors, isEmpty);
    });

    test('reports unsupported exclusive bounds on non-integer schemas', () {
      final result = GoogleSchemaAdapter().adapt(
        dsb.Schema.fromMap({
          'type': 'number',
          'exclusiveMinimum': 0.5,
          'exclusiveMaximum': 10.5,
        }),
      );

      expect(result.schema, isNotNull);
      expect(result.schema!.minimum, isNull);
      expect(result.schema!.maximum, isNull);
      expect(
        result.errors.map((error) => error.message),
        containsAll([
          contains('exclusiveMinimum'),
          contains('exclusiveMaximum'),
        ]),
      );
    });
  });

  group('aiSlideSchema parity with the canonical contract', () {
    test('valid layout data passes the projection and the canonical parser',
        () {
      final slide = validSlide(
        section: {'flex': 2, 'align': 'center', 'spacing': 24},
        block: {
          'flex': 3,
          'align': 'topLeft',
          'padding': {'top': 12, 'right': 24, 'bottom': 12, 'left': 24},
          'margin': {'top': 8, 'right': 8, 'bottom': 8, 'left': 8},
          'scrollable': true,
        },
      );

      expect(aiSlideSchema.safeParse(slide).isOk, isTrue);
      final parsed = Slide.parse(slide);
      final block = parsed.sections.single.blocks.single;
      expect(block.margin?.top, 8);
      expect(block.padding?.right, 24);
      expect(parsed.sections.single.spacing, 24);
    });

    test('rejects non-positive flex like core', () {
      for (final flex in [0, -1]) {
        expect(
          aiSlideSchema.safeParse(validSlide(block: {'flex': flex})).isOk,
          isFalse,
          reason: 'block flex: $flex',
        );
        expect(
          aiSlideSchema.safeParse(validSlide(section: {'flex': flex})).isOk,
          isFalse,
          reason: 'section flex: $flex',
        );
      }
    });

    test('spacing is section-only like core', () {
      expect(
        aiSlideSchema.safeParse(validSlide(section: {'spacing': 40})).isOk,
        isTrue,
      );
      expect(
        aiSlideSchema.safeParse(validSlide(block: {'spacing': 40})).isOk,
        isFalse,
      );
    });

    test('rejects authoring inset shorthand like the compiled contract', () {
      for (final shorthand in [
        16,
        {'horizontal': 24},
      ]) {
        expect(
          aiSlideSchema
              .safeParse(validSlide(block: {'padding': shorthand}))
              .isOk,
          isFalse,
          reason: 'padding: $shorthand',
        );
      }
    });

    test('invalid layout fails the canonical parser with a schema error', () {
      final slide = validSlide(block: {'padding': 16});
      expect(() => Slide.parse(slide), throwsA(anything));
    });

    test('block surface matches the core reserved widget fields', () {
      final blockProperties =
          ((((aiSlideSchema.toJsonSchema()['properties']
                              as Map)['sections']
                          as Map)['items']
                      as Map)['properties']
                  as Map)['blocks'] as Map;
      final properties =
          ((blockProperties['items'] as Map)['properties'] as Map).keys.toSet();

      // Reserved WidgetBlock keys plus the discriminator and content field.
      expect(properties, {
        'type',
        'content',
        'name',
        'align',
        'flex',
        'margin',
        'padding',
        'scrollable',
      });
    });
  });
}
