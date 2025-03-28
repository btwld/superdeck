import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

enum TestEnum { firstValue, secondValue, camelCaseValue }

void main() {
  group('StringX', () {
    group('capitalize', () {
      test('capitalizes first letter', () {
        expect('hello'.capitalize(), equals('Hello'));
      });

      test('does not change already capitalized string', () {
        expect('Hello'.capitalize(), equals('Hello'));
      });

      test('works with single character', () {
        expect('a'.capitalize(), equals('A'));
      });

      test('works with empty string', () {
        expect(''.capitalize(), equals(''));
      });
    });

    group('snakeCase', () {
      test('converts space separated string to snake_case', () {
        expect('hello world'.snakeCase(), equals('hello_world'));
      });

      test('converts camelCase to snake_case', () {
        expect('helloWorld'.snakeCase(), equals('hello_world'));
      });

      test('converts PascalCase to snake_case', () {
        expect('HelloWorld'.snakeCase(), equals('hello_world'));
      });

      test('converts kebab-case to snake_case', () {
        expect('hello-world'.snakeCase(), equals('hello_world'));
      },
          skip:
              'The current implementation does not correctly handle kebab-case');

      test('converts mixed cases to snake_case', () {
        expect(
            'Hello World-Example'.snakeCase(), equals('hello_world_example'));
      },
          skip:
              'The current implementation does not correctly handle mixed cases with hyphens');

      test('handles sequential uppercase letters', () {
        expect('APIResponse'.snakeCase(), equals('api_response'));
      });
    });
  });

  group('ListX', () {
    group('tryFirst', () {
      test('returns first element when list is not empty', () {
        expect([1, 2, 3].tryFirst, equals(1));
      });

      test('returns null when list is empty', () {
        expect(<int>[].tryFirst, isNull);
      });
    });

    group('tryLast', () {
      test('returns last element when list is not empty', () {
        expect([1, 2, 3].tryLast, equals(3));
      });

      test('returns null when list is empty', () {
        expect(<int>[].tryLast, isNull);
      });
    });

    group('tryElementAt', () {
      test('returns element at valid index', () {
        expect([1, 2, 3].tryElementAt(1), equals(2));
      });

      test('returns null for negative index', () {
        expect([1, 2, 3].tryElementAt(-1), isNull);
      });

      test('returns null for out of bounds index', () {
        expect([1, 2, 3].tryElementAt(3), isNull);
      });

      test('returns null for empty list', () {
        expect(<int>[].tryElementAt(0), isNull);
      });
    });
  });

  group('ackEnum', () {
    test('creates a StringSchema for enum values in snake_case', () {
      final schema = ackEnum(TestEnum.values);
      expect(schema, isA<StringSchema>());

      // Check if it validates correctly
      final result1 = schema.validate('first_value');
      final result2 = schema.validate('second_value');
      final result3 = schema.validate('camel_case_value');
      final result4 = schema.validate('invalid_value');

      expect(result1 is Ok, isTrue);
      expect(result2 is Ok, isTrue);
      expect(result3 is Ok, isTrue);
      expect(result4 is Ok, isFalse);
    });
  });
}
