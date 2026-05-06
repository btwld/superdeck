import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('generateValueHash', () {
    test('generates unique hash for different input strings', () {
      String input1 = 'hello world';
      String input2 = 'hello world!';

      String hash1 = generateValueHash(input1);
      String hash2 = generateValueHash(input2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('generates same hash for same input string', () {
      String input = 'test input';

      String hash1 = generateValueHash(input);
      String hash2 = generateValueHash(input);

      expect(hash1, equals(hash2));
    });

    test('generates 8-character hash', () {
      String input = 'some long input string';

      String hash = generateValueHash(input);

      expect(hash.length, equals(8));
    });

    test('generates hash with valid characters', () {
      String input = 'another input';

      String hash = generateValueHash(input);

      expect(hash, matches(RegExp(r'^[a-zA-Z0-9]{8}$')));
    });

    test('handles empty input string', () {
      String input = '';

      String hash = generateValueHash(input);

      expect(hash.length, equals(8));
    });

    test('handles input string with unsupported characters', () {
      String input = 'input with spaces and !@#\$%^&*()';

      String hash = generateValueHash(input);

      expect(hash.length, equals(8));
      expect(hash, matches(RegExp(r'^[a-zA-Z0-9]{8}$')));
    });
  });
}
