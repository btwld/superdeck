import 'package:flutter_test/flutter_test.dart';
import 'package:genui/test/validation.dart';

import 'package:playground/features/ai/core/ai/catalog/catalog.dart';

void main() {
  group('AskUserStyle Schema', () {
    test('parses valid style data', () {
      final data = {
        'question': 'Choose a visual style',
        'description':
            'Pick the palette and fonts that best fit your audience.',
        'styleOptions': [
          {
            'id': 'professional_clean',
            'title': 'Professional & Clean',
            'description': 'Muted palette with crisp typography.',
            'colors': ['#F8FAFC', '#1E3A8A', '#475569'],
            'headlineFont': 'montserrat',
            'bodyFont': 'openSans',
          },
          {
            'id': 'playful_bright',
            'title': 'Playful & Bright',
            'description': 'Cheerful colors with friendly fonts.',
            'colors': ['#F5F3FF', '#5B21B6', '#6B7280'],
            'headlineFont': 'lobster',
            'bodyFont': 'inter',
          },
        ],
        'action': {'name': 'submit_answer', 'context': []},
      };

      final parsed = AskUserStyleType.parse(data);
      expect(parsed.question, 'Choose a visual style');
      expect(parsed.styleOptions, hasLength(2));
      expect(parsed.styleOptions[0].id, 'professional_clean');
      expect(parsed.styleOptions[0].title, 'Professional & Clean');
      expect(parsed.styleOptions[0].colors, hasLength(3));
      expect(parsed.styleOptions[0].headlineFont.name, 'montserrat');
      expect(parsed.styleOptions[0].bodyFont.name, 'openSans');
    });

    test('StyleOptionType parses all fields', () {
      final option = StyleOptionType.parse({
        'id': 'test_style',
        'title': 'Test Style',
        'description': 'A test style',
        'colors': ['#FFFFFF', '#000000'],
        'headlineFont': 'montserrat',
        'bodyFont': 'inter',
      });

      expect(option.id, 'test_style');
      expect(option.title, 'Test Style');
      expect(option.description, 'A test style');
      expect(option.colors, hasLength(2));
      expect(option.headlineFont.name, 'montserrat');
      expect(option.bodyFont.name, 'inter');
    });
  });

  group('AskUserStyle CatalogItem', () {
    test('has correct name', () {
      expect(askUserStyle.name, 'AskUserStyle');
    });

    test('has non-null schema', () {
      expect(askUserStyle.dataSchema, isNotNull);
      expect(askUserStyle.dataSchema.value, isA<Map<String, Object?>>());
    });

    test('has example data', () {
      expect(askUserStyle.exampleData, isNotEmpty);
    });

    test('examples are valid JSON', () async {
      final errors = await validateCatalogItemExamples(
        askUserStyle,
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
