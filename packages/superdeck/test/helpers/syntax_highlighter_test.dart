import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/modules/common/helpers/syntax_highlighter.dart';

void main() {
  group('parseLineNumbers Tests', () {
    test('Single number', () {
      expect(parseLineNumbers('lang {1}'), equals([1]));
    });

    test('Multiple single numbers', () {
      expect(parseLineNumbers('lang {1, 2, 3, 4}'), equals([1, 2, 3, 4]));
    });

    test('Range of numbers', () {
      expect(parseLineNumbers('lang {3-6}'), equals([3, 4, 5, 6]));
    });

    test('Single number and range', () {
      expect(parseLineNumbers('lang {1, 3-6}'), equals([1, 3, 4, 5, 6]));
    });

    test('Multiple ranges', () {
      expect(parseLineNumbers('lang {1-2, 4-5}'), equals([1, 2, 4, 5]));
    });

    test('Combination of single numbers and ranges', () {
      expect(parseLineNumbers('lang {1, 3-6, 10, 21-23}'),
          equals([1, 3, 4, 5, 6, 10, 21, 22, 23]));
    });

    test('No braces returns empty list', () {
      expect(parseLineNumbers('lang 1, 3-6, 10, 21-23'), equals([]));
    });

    test('Empty braces', () {
      expect(parseLineNumbers('lang {}'), equals([]));
    });

    test('Spaces within braces', () {
      expect(
          parseLineNumbers('lang { 1 , 2 , 3 - 5 }'), equals([1, 2, 3, 4, 5]));
    });

    test('Invalid range (start > end)', () {
      // This test assumes the function does not correct for invalid ranges and simply does not include them.
      // Adjust based on your implementation behavior (e.g., throw an error, or include the start number only)
      expect(parseLineNumbers('lang {6-3}'), equals([]));
    });
  });
}
