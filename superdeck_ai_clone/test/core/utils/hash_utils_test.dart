import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_ai/core/utils/hash_utils.dart';

void main() {
  group('generateValueHash', () {
    test('returns 8-character string', () {
      final hash = generateValueHash('test input');

      expect(hash.length, 8);
    });

    test('returns alphanumeric characters only', () {
      final hash = generateValueHash('test input');
      final alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');

      expect(alphanumeric.hasMatch(hash), isTrue);
    });

    test('is deterministic - same input produces same output', () {
      const input = 'slide-intro-illustration';

      final hash1 = generateValueHash(input);
      final hash2 = generateValueHash(input);
      final hash3 = generateValueHash(input);

      expect(hash1, hash2);
      expect(hash2, hash3);
    });

    test('different inputs produce different outputs', () {
      final hash1 = generateValueHash('input-a');
      final hash2 = generateValueHash('input-b');
      final hash3 = generateValueHash('input-c');

      expect(hash1, isNot(hash2));
      expect(hash2, isNot(hash3));
      expect(hash1, isNot(hash3));
    });

    test('handles empty string', () {
      final hash = generateValueHash('');

      expect(hash.length, 8);
      expect(hash, isNotEmpty);
    });

    test('handles long strings', () {
      final longInput = 'a' * 10000;
      final hash = generateValueHash(longInput);

      expect(hash.length, 8);
    });

    test('handles special characters in input', () {
      final hash = generateValueHash('slide-key-#123!@\$%^&*()');

      expect(hash.length, 8);
      expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(hash), isTrue);
    });

    test('handles unicode characters', () {
      final hash = generateValueHash('スライド-介绍-🎨');

      expect(hash.length, 8);
      expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(hash), isTrue);
    });
  });
}
