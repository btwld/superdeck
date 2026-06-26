import 'package:flutter_test/flutter_test.dart';
import 'package:genui/test/validation.dart';

import 'package:playground/features/ai/core/ai/catalog/catalog.dart';

void main() {
  group('AskUserCheckbox Schema', () {
    test('parses valid checkbox data', () {
      final data = {
        'question': 'What topics?',
        'items': ['History', 'Current State', 'Future'],
        'minSelections': 1,
        'maxSelections': 2,
        'action': {'name': 'submit_answer', 'context': []},
      };

      final parsed = AskUserCheckboxType.parse(data);
      expect(parsed.question, 'What topics?');
      expect(parsed.items, hasLength(3));
      expect(parsed.minSelections, 1);
      expect(parsed.maxSelections, 2);
    });

    test('optional fields default to null', () {
      final data = {
        'question': 'Pick topics',
        'items': ['A', 'B'],
        'action': {'name': 'submit', 'context': []},
      };

      final parsed = AskUserCheckboxType.parse(data);
      expect(parsed.description, isNull);
      expect(parsed.selectedItems, isNull);
      expect(parsed.minSelections, isNull);
      expect(parsed.maxSelections, isNull);
    });

    test('parses selectedItems', () {
      final data = {
        'question': 'Pick topics',
        'items': ['A', 'B', 'C'],
        'selectedItems': ['A', 'C'],
        'action': {'name': 'submit', 'context': []},
      };

      final parsed = AskUserCheckboxType.parse(data);
      expect(parsed.selectedItems, ['A', 'C']);
    });
  });

  group('AskUserCheckbox CatalogItem', () {
    test('has correct name', () {
      expect(askUserCheckbox.name, 'AskUserCheckbox');
    });

    test('has non-null schema', () {
      expect(askUserCheckbox.dataSchema, isNotNull);
      expect(askUserCheckbox.dataSchema.value, isA<Map<String, Object?>>());
    });

    test('has example data', () {
      expect(askUserCheckbox.exampleData, isNotEmpty);
    });

    test('examples are valid JSON', () async {
      final errors = await validateCatalogItemExamples(
        askUserCheckbox,
        chatCatalog,
      );

      final criticalErrors = errors.where((e) {
        final message = e.toString();
        return !message.contains('optional') &&
            !message.contains('not required');
      }).toList();

      expect(
        criticalErrors,
        isEmpty,
        reason:
            'Examples should be valid. Errors:\n${criticalErrors.join('\n')}',
      );
    });
  });
}
