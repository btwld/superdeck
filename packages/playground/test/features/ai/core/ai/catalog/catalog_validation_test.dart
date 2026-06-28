import 'package:flutter_test/flutter_test.dart';
import 'package:genui/test/validation.dart';
import 'package:playground/features/ai/core/ai/catalog/catalog.dart';
import 'package:playground/features/ai/core/ai/catalog/catalog_data_normalizer.dart';
import 'package:playground/features/ai/core/ai/catalog/remix_catalog.dart';

void main() {
  group('SuperDeck Catalog Validation', () {
    test('chatCatalog should have a valid catalogId', () {
      expect(chatCatalog.catalogId, isNotNull);
      expect(chatCatalog.catalogId, equals('com.superdeck.ai.chat'));
    });

    test('chatCatalog should contain all expected items', () {
      final itemNames = chatCatalog.items.map((item) => item.name).toList();

      // Individual question components (steps 1-6)
      expect(itemNames, contains('AskUserRadio'));
      expect(itemNames, contains('AskUserCheckbox'));
      expect(itemNames, contains('AskUserSlider'));
      expect(itemNames, contains('AskUserText'));
      expect(itemNames, contains('AskUserStyle'));
      expect(itemNames, contains('AskUserImageStyle'));

      // Summary component (step 7)
      expect(itemNames, contains('SummaryCard'));

      // Remix component preview (standalone demo)
      expect(itemNames, contains('RemixComponentPreview'));

      expect(itemNames.length, equals(8));
    });

    for (final item in chatCatalog.items) {
      group('CatalogItem: ${item.name}', () {
        test('should have a valid dataSchema', () {
          expect(item.dataSchema, isNotNull);
          expect(item.dataSchema.value, isA<Map<String, Object?>>());
        });

        test('should have a valid widgetBuilder', () {
          expect(item.widgetBuilder, isNotNull);
        });

        test('should have exampleData for AI few-shot learning', () {
          expect(
            item.exampleData,
            isNotEmpty,
            reason:
                '${item.name} should have at least one example for AI learning',
          );
        });

        test('examples should be valid JSON', () async {
          final errors = await validateCatalogItemExamples(item, chatCatalog);

          final criticalErrors = errors.where((e) {
            final message = e.toString();
            return !message.contains('optional') &&
                !message.contains('not required');
          }).toList();

          expect(
            criticalErrors,
            isEmpty,
            reason:
                '${item.name} examples should be valid. Errors:\n${criticalErrors.join('\n')}',
          );
        });
      });
    }
  });

  group('Catalog Schema Generation', () {
    test('chatCatalog should generate a valid schema definition', () {
      final definition = chatCatalog.definition;
      expect(definition, isNotNull);
      expect(definition.value, isA<Map<String, Object?>>());
    });

    test('catalog schema should include all component names', () {
      final definition = chatCatalog.definition;
      final schemaJson = definition.value;

      expect(schemaJson, isNotNull);
    });

    test('chatCatalog and remixCatalog require component exactly once', () {
      final catalogs = [chatCatalog, remixCatalog];

      for (final catalog in catalogs) {
        for (final item in catalog.items) {
          final schema = item.dataSchema.value;
          final properties = schema['properties'] as Map;
          final required = schema['required'] as List;
          final componentRequirements = required.where(
            (field) => field == 'component',
          );

          expect(
            properties,
            contains('component'),
            reason: '${item.name} should expose the GenUI component field',
          );
          expect(
            componentRequirements,
            hasLength(1),
            reason: '${item.name} should require component exactly once',
          );
        }
      }
    });

    test('catalog data normalizer handles nested action literal numbers', () {
      final normalized =
          normalizeCatalogData({
                'action': {
                  'name': 'submit_answer',
                  'context': [
                    {
                      'key': 'score',
                      'value': {'literalNumber': 1},
                    },
                  ],
                },
              })
              as Map<String, Object?>;
      final action = normalized['action'] as Map<String, Object?>;
      final context = action['context'] as List;
      final entry = context.single as Map<String, Object?>;
      final value = entry['value'] as Map<String, Object?>;

      expect(value['literalNumber'], 1.0);
    });
  });
}
