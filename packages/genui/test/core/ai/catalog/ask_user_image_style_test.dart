import 'package:flutter_test/flutter_test.dart';
import 'package:genui/test/validation.dart';

import 'package:superdeck_genui/src/ai/catalog/catalog.dart';

void main() {
  group('AskUserImageStyle Schema', () {
    test('parses valid image style data', () {
      final data = {
        'question': 'Choose an image style',
        'description': 'Select the visual direction for imagery.',
        'subject': 'solar system with planets',
        'imageStyles': ['watercolor', 'minimalist', 'gradient'],
        'action': {'name': 'submit_answer', 'context': []},
      };

      final parsed = AskUserImageStyleType.parse(data);
      expect(parsed.question, 'Choose an image style');
      expect(parsed.description, 'Select the visual direction for imagery.');
      expect(parsed.subject, 'solar system with planets');
      expect(parsed.imageStyles, hasLength(3));
      final imageStyleIds = parsed.imageStyles.map((style) => style.name);
      expect(imageStyleIds, contains('watercolor'));
      expect(imageStyleIds, contains('minimalist'));
      expect(imageStyleIds, contains('gradient'));
    });

    test('description is optional', () {
      final data = {
        'question': 'Pick a style',
        'subject': 'mountain landscape',
        'imageStyles': ['watercolor', 'minimalist'],
        'action': {'name': 'submit', 'context': []},
      };

      final parsed = AskUserImageStyleType.parse(data);
      expect(parsed.description, isNull);
    });
  });

  group('AskUserImageStyle CatalogItem', () {
    test('has correct name', () {
      expect(askUserImageStyle.name, 'AskUserImageStyle');
    });

    test('has non-null schema', () {
      expect(askUserImageStyle.dataSchema, isNotNull);
      expect(askUserImageStyle.dataSchema.value, isA<Map<String, Object?>>());
    });

    test('has example data', () {
      expect(askUserImageStyle.exampleData, isNotEmpty);
    });

    test('examples are valid JSON', () async {
      final errors = await validateCatalogItemExamples(
        askUserImageStyle,
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
