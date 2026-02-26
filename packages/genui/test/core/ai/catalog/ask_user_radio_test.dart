import 'package:flutter_test/flutter_test.dart';
import 'package:genui/test/validation.dart';

import 'package:superdeck_genui/src/ai/catalog/catalog.dart';

void main() {
  group('AskUserRadio Schema', () {
    test('parses valid radio data', () {
      final data = {
        'question': 'Who is your audience?',
        'description': 'Select one',
        'options': [
          {'title': 'Students', 'description': 'Academic learners'},
          {'title': 'Professionals', 'description': 'Business context'},
        ],
        'action': {'name': 'submit_answer', 'context': []},
      };

      final parsed = AskUserRadioType.parse(data);
      expect(parsed.question, 'Who is your audience?');
      expect(parsed.description, 'Select one');
      expect(parsed.options, hasLength(2));
      expect(parsed.options[0].title, 'Students');
      expect(parsed.options[0].description, 'Academic learners');
    });

    test('description is optional', () {
      final data = {
        'question': 'Simple question',
        'options': [
          {'title': 'Option A'},
        ],
        'action': {'name': 'submit', 'context': []},
      };

      final parsed = AskUserRadioType.parse(data);
      expect(parsed.description, isNull);
    });

    test('option description is optional', () {
      final option = InputOptionType({'title': 'Title Only'});

      expect(option.title, 'Title Only');
      expect(option.description, isNull);
    });
  });

  group('AskUserRadio CatalogItem', () {
    test('has correct name', () {
      expect(askUserRadio.name, 'AskUserRadio');
    });

    test('has non-null schema', () {
      expect(askUserRadio.dataSchema, isNotNull);
      expect(askUserRadio.dataSchema.value, isA<Map<String, Object?>>());
    });

    test('has example data', () {
      expect(askUserRadio.exampleData, isNotEmpty);
    });

    test('examples are valid JSON', () async {
      final errors = await validateCatalogItemExamples(
        askUserRadio,
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
