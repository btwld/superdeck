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
              'Summary card showing recap of all user selections before finalizing',
          properties: {
            'title': Schema.string(
              description: 'The main heading of the summary card',
            ),
            'items': Schema.list(
              description: 'List of summary items representing user selections',
              items: Schema.object(
                description: 'Summary item representing a user selection',
                properties: {
                  'label': Schema.string(
                    description: 'The category label for this selection',
                  ),
                  'kind': Schema.string(
                    description: 'Discriminator for summary payload shape',
                    enumValues: ['text', 'style', 'imageStyle'],
                  ),
                  'title': Schema.string(
                    description:
                        'The primary text representing the user\'s choice',
                  ),
                  'description': Schema.string(
                    description: 'Additional details about the selection',
                  ),
                  'text': Schema.string(
                    description: 'Plain text content for simple display items',
                  ),
                  'colors': Schema.list(
                    description:
                        'List of hex color strings for the style palette',
                    items: Schema.string(description: 'Hex color value'),
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
  expect(
    _normalizeSchemaJson(newSchema.value),
    equals(_normalizeSchemaJson(oldSchema.value, addAckObjectDefaults: true)),
    reason: '$componentName schema should match the migration baseline',
  );
}

Object? _normalizeSchemaJson(
  Object? value, {
  String? parentKey,
  bool addAckObjectDefaults = false,
}) {
  if (value is Map) {
    final normalized = {
      for (final entry in value.entries)
        if (!(parentKey == 'properties' &&
            _v09ComponentFields.contains(entry.key)))
          entry.key: _normalizeSchemaJson(
            entry.value,
            parentKey: entry.key,
            addAckObjectDefaults: addAckObjectDefaults,
          ),
    };
    if (addAckObjectDefaults &&
        normalized['type'] == 'object' &&
        !normalized.containsKey('additionalProperties')) {
      normalized['additionalProperties'] = false;
    }
    return normalized;
  }

  if (value is List) {
    final normalized = value
        .where((entry) {
          return parentKey != 'required' ||
              !_v09ComponentFields.contains(entry);
        })
        .map((entry) => _normalizeSchemaJson(entry, parentKey: parentKey))
        .toList();

    if (parentKey == 'required' || parentKey == 'enum') {
      normalized.sort((a, b) => a.toString().compareTo(b.toString()));
    }
    return normalized;
  }

  return value;
}

const _v09ComponentFields = {'id', 'component'};
