import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('generateValueHash', () {
    test('generates unique hash for different input strings', () {
      const String input1 = 'hello world';
      const String input2 = 'hello world!';

      final String hash1 = generateValueHash(input1);
      final String hash2 = generateValueHash(input2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('generates same hash for same input string', () {
      const String input = 'test input';

      final String hash1 = generateValueHash(input);
      final String hash2 = generateValueHash(input);

      expect(hash1, equals(hash2));
    });

    test('generates 8-character hash', () {
      const String input = 'some long input string';

      final String hash = generateValueHash(input);

      expect(hash.length, equals(8));
    });

    test('generates hash with valid characters', () {
      const String input = 'another input';

      final String hash = generateValueHash(input);

      expect(hash, matches(RegExp(r'^[a-zA-Z0-9]{8}$')));
    });

    test('handles empty input string', () {
      const String input = '';

      final String hash = generateValueHash(input);

      expect(hash.length, equals(8));
    });

    test('handles input string with unsupported characters', () {
      const String input = 'input with spaces and !@#\$%^&*()';

      final String hash = generateValueHash(input);

      expect(hash.length, equals(8));
      expect(hash, matches(RegExp(r'^[a-zA-Z0-9]{8}$')));
    });
  });
}
