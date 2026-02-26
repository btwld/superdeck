import 'package:flutter_test/flutter_test.dart';
import 'package:genui/test/validation.dart';

import 'package:superdeck_ai/core/ai/catalog/catalog.dart';

void main() {
  group('AskUserText Schema', () {
    test('parses valid text data', () {
      final data = {
        'question': 'Any requirements?',
        'placeholder': 'Enter details...',
        'maxLength': 500,
        'multiline': true,
        'action': {'name': 'submit_answer', 'context': []},
      };

      final parsed = AskUserTextType.parse(data);
      expect(parsed.question, 'Any requirements?');
      expect(parsed.placeholder, 'Enter details...');
      expect(parsed.maxLength, 500);
      expect(parsed.multiline, true);
    });

    test('all fields except question and action are optional', () {
      final data = {
        'question': 'Simple question',
        'action': {'name': 'submit', 'context': []},
      };

      final parsed = AskUserTextType.parse(data);
      expect(parsed.question, 'Simple question');
      expect(parsed.description, isNull);
      expect(parsed.placeholder, isNull);
      expect(parsed.maxLength, isNull);
      expect(parsed.multiline, isNull);
    });
  });

  group('AskUserText CatalogItem', () {
    test('has correct name', () {
      expect(askUserText.name, 'AskUserText');
    });

    test('has non-null schema', () {
      expect(askUserText.dataSchema, isNotNull);
      expect(askUserText.dataSchema.value, isA<Map<String, Object?>>());
    });

    test('has example data', () {
      expect(askUserText.exampleData, isNotEmpty);
    });

    test('examples are valid JSON', () async {
      final errors = await validateCatalogItemExamples(
        askUserText,
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
