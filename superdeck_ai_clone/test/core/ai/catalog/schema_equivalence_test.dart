import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// ACK schemas (converted via toJsonSchemaBuilder)
import 'package:superdeck_ai/core/ai/catalog/summary_card.dart';
import 'package:superdeck_ai/core/ai/prompts/font_styles.dart';
import 'package:superdeck_ai/core/ai/prompts/image_style_prompts.dart';

/// Tests to verify ACK schemas produce equivalent output to the original
/// json_schema_builder schemas that were replaced during migration.
///
/// This ensures the AI receives the same schema structure and the migration
/// didn't change the contract between the app and the AI model.
///
/// Note: CheckboxCardGroup, RadioCardGroup, SlideCountCard, RadioStyleCardGroup,
/// and ImageStyleCardGroup tests were removed as those components have been
/// split into AskUserRadio, AskUserCheckbox, AskUserSlider, AskUserText,
/// AskUserStyle, and AskUserImageStyle.
void main() {
  group('Schema Equivalence Tests', () {
    group('summary_card', () {
      test('schema structure matches original', () {
        // OLD schema (from git history before ACK migration)
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
            'generateSlidesAction': A2uiSchemas.action(
              description:
                  'Generate the slides for the presentation. The context for this action should include references to the selected values so that the model can know what the user has selected.',
            ),
          },
          required: ['title', 'items', 'generateSlidesAction'],
        );

        // NEW schema (from ACK migration)
        final newSchema = summaryCard.dataSchema;

        // Compare structure
        _compareSchemaStructure(oldSchema, newSchema, 'SummaryCard');
      });
    });
  });
}

/// Compares two schemas and verifies their structure is equivalent.
///
/// Ignores 'description' and 'additionalProperties' fields as these are
/// cosmetic/strictness changes that don't affect the AI contract.
///
/// Checks recursively:
/// - Property names match exactly (no extra, no missing)
/// - Property types match
/// - Required fields match
/// - Enum values match (where applicable)
/// - Nested objects and array items match
void _compareSchemaStructure(
  Schema oldSchema,
  Schema newSchema,
  String componentName,
) {
  _compareJsonStructure(oldSchema.value, newSchema.value, componentName);
}

/// Recursively compares two JSON schema maps, ignoring descriptions.
void _compareJsonStructure(
  Map<String, Object?> oldJson,
  Map<String, Object?> newJson,
  String path,
) {
  // Compare type
  expect(
    newJson['type'],
    equals(oldJson['type']),
    reason: '$path: type should match',
  );

  // Compare required fields (as sets to ignore ordering)
  final oldRequired = (oldJson['required'] as List?)?.cast<String>().toSet();
  final newRequired = (newJson['required'] as List?)?.cast<String>().toSet();
  expect(
    newRequired,
    equals(oldRequired),
    reason: '$path: required fields should match',
  );

  // Compare enum values (as sets to ignore ordering)
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

  // Compare properties recursively
  final oldProps = oldJson['properties'] as Map<String, Object?>?;
  final newProps = newJson['properties'] as Map<String, Object?>?;

  if (oldProps != null) {
    expect(newProps, isNotNull, reason: '$path: should have properties');

    // Check property keys match exactly
    final oldKeys = oldProps.keys.toSet();
    final newKeys = newProps!.keys.toSet();

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

    // Recursively compare each property
    for (final propName in oldProps.keys) {
      final oldProp = oldProps[propName] as Map<String, Object?>;
      final newProp = newProps[propName] as Map<String, Object?>;

      _compareJsonStructure(oldProp, newProp, '$path.$propName');
    }
  }

  // Compare array items recursively
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
