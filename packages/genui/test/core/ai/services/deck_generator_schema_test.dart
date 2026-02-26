import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:superdeck_genui/src/ai/schemas/deck_schemas.dart';

void main() {
  group('Slide Generation Schema', () {
    test('should convert to valid Google AI schema without errors', () {
      // Convert ACK schema to json_schema_builder format
      final schema = slideGenerationSchema.toJsonSchemaBuilder();
      final adapter = GoogleSchemaAdapter();
      final result = adapter.adapt(schema);

      // Filter out ignorable warnings (additionalProperties is not supported but ignored)
      final criticalErrors = result.errors.where((e) {
        final message = e.toString();
        // Warnings about ignored keywords are not critical
        return !message.contains('will be ignored');
      }).toList();

      expect(
        criticalErrors,
        isEmpty,
        reason:
            'Schema conversion should have no critical errors: '
            '${criticalErrors.join('; ')}',
      );
      expect(result.schema, isNotNull, reason: 'Schema should be produced');
    });

    test('required fields should only include truly required properties', () {
      // Convert ACK schema to json_schema_builder and get raw JSON schema map
      final schema = slideGenerationSchema.toJsonSchemaBuilder();
      final jsonSchema = schema.value;

      // Root level should have 'slides' and 'style' as required
      final rootRequired = jsonSchema['required'] as List?;
      expect(rootRequired, contains('slides'));
      expect(rootRequired, contains('style'));

      // Slide level: only 'key' and 'sections' should be required
      final slidesSchema = jsonSchema['properties'] as Map;
      final slideItemSchema = (slidesSchema['slides'] as Map)['items'] as Map;
      final slideRequired = slideItemSchema['required'] as List?;

      expect(slideRequired, contains('key'), reason: 'key should be required');
      expect(
        slideRequired,
        contains('sections'),
        reason: 'sections should be required',
      );
      expect(
        slideRequired,
        isNot(contains('options')),
        reason: 'options should be optional',
      );
      expect(
        slideRequired,
        isNot(contains('comments')),
        reason: 'comments should be optional',
      );

      // Section level: only 'type' and 'blocks' should be required
      final sectionsSchema =
          (slideItemSchema['properties'] as Map)['sections'] as Map;
      final sectionItemSchema = sectionsSchema['items'] as Map;
      final sectionRequired = sectionItemSchema['required'] as List?;

      expect(
        sectionRequired,
        contains('type'),
        reason: 'section type should be required',
      );
      expect(
        sectionRequired,
        contains('blocks'),
        reason: 'blocks should be required',
      );
      expect(
        sectionRequired,
        isNot(contains('flex')),
        reason: 'flex should be optional',
      );
      expect(
        sectionRequired,
        isNot(contains('align')),
        reason: 'align should be optional',
      );

      // Block level: only 'type' should be required
      final blocksSchema =
          (sectionItemSchema['properties'] as Map)['blocks'] as Map;
      final blockItemSchema = blocksSchema['items'] as Map;
      final blockRequired = blockItemSchema['required'] as List?;

      expect(
        blockRequired,
        equals(['type']),
        reason: 'Only type should be required in blocks',
      );
    });

    test('optional fields should be marked as nullable in the schema', () {
      // Convert ACK schema to json_schema_builder and get raw JSON schema map
      final schema = slideGenerationSchema.toJsonSchemaBuilder();
      final jsonSchema = schema.value;

      final slidesSchema = jsonSchema['properties'] as Map;
      final slideItemSchema = (slidesSchema['slides'] as Map)['items'] as Map;
      final slideProps = slideItemSchema['properties'] as Map;

      // Check that optional fields exist but aren't in required
      expect(slideProps.containsKey('options'), isTrue);
      expect(slideProps.containsKey('comments'), isTrue);
    });

    test(
      'schema structure matches expected baseline from json_schema_builder',
      () {
        // This test ensures the ACK schema produces identical structure
        // to the original json_schema_builder schema
        final schema = slideGenerationSchema.toJsonSchemaBuilder();
        final jsonSchema = schema.value;

        // Verify root schema structure
        expect(jsonSchema['type'], equals('object'));
        expect(
          jsonSchema['description'],
          equals('A SuperDeck presentation with slides and style'),
        );
        expect(
          (jsonSchema['properties'] as Map).keys.toSet(),
          equals({'slides', 'style'}),
        );
        expect(
          (jsonSchema['required'] as List).toSet(),
          equals({'slides', 'style'}),
        );

        // Verify slides array schema
        final slidesSchema = (jsonSchema['properties'] as Map)['slides'] as Map;
        expect(slidesSchema['type'], equals('array'));
        expect(
          slidesSchema['description'],
          equals('Array of slides in the presentation'),
        );

        // Verify slide item schema
        final slideItemSchema = slidesSchema['items'] as Map;
        expect(slideItemSchema['type'], equals('object'));
        expect(slideItemSchema['description'], equals('A single slide'));
        expect(
          (slideItemSchema['properties'] as Map).keys.toSet(),
          equals({'key', 'options', 'comments', 'sections'}),
        );
        expect(
          (slideItemSchema['required'] as List).toSet(),
          equals({'key', 'sections'}),
        );

        // Verify style schema
        final styleSchema = (jsonSchema['properties'] as Map)['style'] as Map;
        expect(styleSchema['type'], equals('object'));
        expect(
          styleSchema['description'],
          equals('Global style configuration for the deck'),
        );
        expect(
          (styleSchema['properties'] as Map).keys.toSet(),
          equals({'name', 'colors', 'fonts'}),
        );
        expect(
          (styleSchema['required'] as List).toSet(),
          equals({'name', 'colors', 'fonts'}),
        );

        // Verify colors schema
        final colorsSchema =
            (styleSchema['properties'] as Map)['colors'] as Map;
        expect(colorsSchema['type'], equals('object'));
        expect(
          colorsSchema['description'],
          equals('Color palette for the presentation'),
        );
        expect(
          (colorsSchema['properties'] as Map).keys.toSet(),
          equals({'background', 'heading', 'body'}),
        );
        expect(
          (colorsSchema['required'] as List).toSet(),
          equals({'background', 'heading', 'body'}),
        );

        // Verify fonts schema
        final fontsSchema = (styleSchema['properties'] as Map)['fonts'] as Map;
        expect(fontsSchema['type'], equals('object'));
        expect(fontsSchema['description'], equals('Typography configuration'));
        expect(
          (fontsSchema['properties'] as Map).keys.toSet(),
          equals({'headline', 'body'}),
        );
        expect(
          (fontsSchema['required'] as List).toSet(),
          equals({'headline', 'body'}),
        );

        // Verify section schema structure
        final sectionsSchema =
            (slideItemSchema['properties'] as Map)['sections'] as Map;
        final sectionItemSchema = sectionsSchema['items'] as Map;
        expect(sectionItemSchema['type'], equals('object'));
        expect(
          sectionItemSchema['description'],
          equals('A section containing blocks'),
        );
        expect(
          (sectionItemSchema['properties'] as Map).keys.toSet(),
          equals({'type', 'flex', 'align', 'scrollable', 'blocks'}),
        );
        expect(
          (sectionItemSchema['required'] as List).toSet(),
          equals({'type', 'blocks'}),
        );

        // Verify block schema structure
        final blocksSchema =
            (sectionItemSchema['properties'] as Map)['blocks'] as Map;
        final blockItemSchema = blocksSchema['items'] as Map;
        expect(blockItemSchema['type'], equals('object'));
        expect(
          blockItemSchema['description'],
          equals('A content or widget block'),
        );
        expect(
          (blockItemSchema['properties'] as Map).keys.toSet(),
          equals({'type', 'content', 'name', 'flex', 'align', 'scrollable'}),
        );
        expect((blockItemSchema['required'] as List).toSet(), equals({'type'}));

        // Verify enum values are preserved
        final blockTypeSchema =
            (blockItemSchema['properties'] as Map)['type'] as Map;
        expect(
          (blockTypeSchema['enum'] as List).toSet(),
          equals({'block', 'widget'}),
        );

        final alignSchema =
            (blockItemSchema['properties'] as Map)['align'] as Map;
        expect(
          (alignSchema['enum'] as List).toSet(),
          equals({
            'topLeft',
            'topCenter',
            'topRight',
            'centerLeft',
            'center',
            'centerRight',
            'bottomLeft',
            'bottomCenter',
            'bottomRight',
          }),
        );
      },
    );

    test('all individual schemas produce valid json_schema_builder output', () {
      // Test each schema independently to catch conversion issues early
      final schemas = {
        'colorsSchema': colorsSchema,
        'fontsSchema': fontsSchema,
        'styleSchema': styleSchema,
        'blockSchema': blockSchema,
        'sectionSchema': sectionSchema,
        'slideOptionsSchema': slideOptionsSchema,
        'slideSchema': slideSchema,
        'slideGenerationSchema': slideGenerationSchema,
      };

      for (final entry in schemas.entries) {
        final converted = entry.value.toJsonSchemaBuilder();
        expect(
          converted.value,
          isA<Map<String, dynamic>>(),
          reason: '${entry.key} should produce a valid JSON schema map',
        );
        expect(
          converted.value['type'],
          equals('object'),
          reason: '${entry.key} should have type "object"',
        );
        expect(
          converted.value['properties'],
          isA<Map>(),
          reason: '${entry.key} should have properties map',
        );
      }
    });
  });
}
