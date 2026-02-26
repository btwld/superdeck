import 'package:flutter_test/flutter_test.dart';
import 'package:genui/test/validation.dart';

import 'package:superdeck_ai/core/ai/catalog/catalog.dart';

void main() {
  group('AskUserSlider Schema', () {
    test('parses valid slider data', () {
      final data = {
        'question': 'How many slides?',
        'minValue': 5,
        'maxValue': 20,
        'defaultValue': 10,
        'unit': 'slides',
        'action': {'name': 'submit_answer', 'context': []},
      };

      final parsed = AskUserSliderType.parse(data);
      expect(parsed.question, 'How many slides?');
      expect(parsed.minValue, 5);
      expect(parsed.maxValue, 20);
      expect(parsed.defaultValue, 10);
      expect(parsed.unit, 'slides');
    });

    test('unit is optional', () {
      final data = {
        'question': 'Pick a number',
        'minValue': 1,
        'maxValue': 100,
        'defaultValue': 50,
        'action': {'name': 'submit', 'context': []},
      };

      final parsed = AskUserSliderType.parse(data);
      expect(parsed.unit, isNull);
      expect(parsed.description, isNull);
    });
  });

  group('AskUserSlider CatalogItem', () {
    test('has correct name', () {
      expect(askUserSlider.name, 'AskUserSlider');
    });

    test('has non-null schema', () {
      expect(askUserSlider.dataSchema, isNotNull);
      expect(askUserSlider.dataSchema.value, isA<Map<String, Object?>>());
    });

    test('has example data', () {
      expect(askUserSlider.exampleData, isNotEmpty);
    });

    test('examples are valid JSON', () async {
      final errors = await validateCatalogItemExamples(
        askUserSlider,
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
