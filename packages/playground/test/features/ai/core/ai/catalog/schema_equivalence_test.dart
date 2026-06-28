import 'package:flutter_test/flutter_test.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// ACK schemas (converted via toJsonSchemaBuilder)
import 'package:playground/features/ai/core/ai/catalog/summary_card.dart';
import 'package:playground/features/ai/core/ai/prompts/font_styles.dart';
import 'package:playground/features/ai/core/ai/prompts/image_style_prompts.dart';
import 'package:playground/features/ai/core/ai/schemas/genui_action_schema.dart';

/// Tests to verify ACK schemas produce equivalent output to the original
/// json_schema_builder schemas that were replaced during migration.
void main() {
  group('Schema Equivalence Tests', () {
    group('summary_card', () {
      test('schema structure matches original', () {
        final oldSchema = Schema.object(
          description:
              'A summary card that displays a recap of all user selections before finalizing. '
              'This should be used to show the user a complete overview of their choices '
              '(audience, approach, style, etc.) so they can review before proceeding.',
          properties: {
            'title': Schema.string(
              description: 'The main heading of the summary card.',
            ),
            'items': Schema.list(
              description:
                  'The list of summary items representing each user selection to display.',
              items: Schema.object(
                properties: {
                  'label': Schema.string(
                    description: 'The category label for this selection.',
                  ),
                  'kind': Schema.string(
                    description: 'Discriminator for summary payload shape',
                    enumValues: ['text', 'style', 'imageStyle'],
                  ),
                  'title': Schema.string(
                    description:
                        'The primary text representing the user\'s choice.',
                  ),
                  'description': Schema.string(
                    description: 'Additional details about the selection.',
                  ),
                  'text': Schema.string(
                    description: 'Plain text content for simple display items.',
                  ),
                  'colors': Schema.list(
                    description:
                        'List of hex color strings for the style palette. Include for style selections.',
                    items: Schema.string(description: 'Hex color value.'),
                  ),
                  'headlineFont': Schema.string(
                    description: HeadlineFont.schemaDescription,
                    enumValues: HeadlineFont.values.map((f) => f.name).toList(),
                  ),
                  'bodyFont': Schema.string(
                    description: BodyFont.schemaDescription,
                    enumValues: BodyFont.values.map((f) => f.name).toList(),
                  ),
                  'imageStyleId': Schema.string(
                    description: ImageStyle.schemaDescription(),
                    enumValues: ImageStyle.values.map((f) => f.name).toList(),
                  ),
                },
                required: ['label'],
              ),
            ),
            'generateSlidesAction': actionSchema.toJsonSchemaBuilder(),
          },
          required: ['title', 'items', 'generateSlidesAction'],
        );

        final newSchema = summaryCard.dataSchema;

        _compareSchemaStructure(oldSchema, newSchema, 'SummaryCard');
      });
    });
  });
}

void _compareSchemaStructure(
  Schema oldSchema,
  Schema newSchema,
  String componentName,
) {
  _compareJsonStructure(oldSchema.value, newSchema.value, componentName);
}

void _compareJsonStructure(
  Map<String, Object?> oldJson,
  Map<String, Object?> newJson,
  String path,
) {
  expect(
    newJson['type'],
    equals(oldJson['type']),
    reason: '$path: type should match',
  );

  final oldRequired = (oldJson['required'] as List?)?.cast<String>().toSet();
  final newRequired = (newJson['required'] as List?)?.cast<String>().toSet()
    ?..removeAll(_v09ComponentFields);
  expect(
    newRequired,
    equals(oldRequired),
    reason: '$path: required fields should match',
  );

  if (oldJson.containsKey('enum')) {
    expect(
      newJson.containsKey('enum'),
      isTrue,
      reason: '$path: should have enum values',
    );
    final oldEnum = (oldJson['enum'] as List).toSet();
    final newEnum = (newJson['enum'] as List).toSet();
    expect(newEnum, equals(oldEnum), reason: '$path: enum values should match');
  }

  final oldProps = oldJson['properties'] as Map<String, Object?>?;
  final newProps = newJson['properties'] as Map<String, Object?>?;

  if (oldProps != null) {
    expect(newProps, isNotNull, reason: '$path: should have properties');

    final oldKeys = oldProps.keys.toSet();
    final newKeys = newProps!.keys.toSet().difference(_v09ComponentFields);

    final missingInNew = oldKeys.difference(newKeys);
    final extraInNew = newKeys.difference(oldKeys);

    expect(
      missingInNew,
      isEmpty,
      reason: '$path: missing properties in new schema: $missingInNew',
    );
    expect(
      extraInNew,
      isEmpty,
      reason: '$path: extra properties in new schema: $extraInNew',
    );

    for (final propName in oldProps.keys) {
      final oldProp = oldProps[propName] as Map<String, Object?>;
      final newProp = newProps[propName] as Map<String, Object?>;

      _compareJsonStructure(oldProp, newProp, '$path.$propName');
    }
  }

  if (oldJson.containsKey('items')) {
    expect(
      newJson.containsKey('items'),
      isTrue,
      reason: '$path: should have items',
    );

    final oldItems = oldJson['items'] as Map<String, Object?>;
    final newItems = newJson['items'] as Map<String, Object?>;

    _compareJsonStructure(oldItems, newItems, '$path.items');
  }
}

const _v09ComponentFields = {'id', 'component'};
