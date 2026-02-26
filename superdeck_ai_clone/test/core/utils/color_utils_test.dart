import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_ai/core/utils/color_utils.dart';

void main() {
  group('parseHexColor', () {
    group('valid 6-digit hex colors', () {
      test('parses 6-digit hex with # prefix', () {
        final result = parseHexColor('#FF5733');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFFFF5733));
      });

      test('parses 6-digit hex without # prefix', () {
        final result = parseHexColor('FF5733');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFFFF5733));
      });

      test('handles lowercase hex', () {
        final result = parseHexColor('#ff5733');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFFFF5733));
      });

      test('handles uppercase hex', () {
        final result = parseHexColor('#FF5733');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFFFF5733));
      });

      test('handles mixed case hex', () {
        final result = parseHexColor('#Ff5733');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFFFF5733));
      });
    });

    group('valid 8-digit hex colors (with alpha)', () {
      test('parses 8-digit hex with full opacity', () {
        final result = parseHexColor('FFFF5733');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFFFF5733));
      });

      test('parses 8-digit hex with partial opacity', () {
        final result = parseHexColor('80FF5733');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0x80FF5733));
      });

      test('parses 8-digit hex with # prefix', () {
        final result = parseHexColor('#80FF5733');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0x80FF5733));
      });

      test('parses 8-digit hex with zero alpha (transparent)', () {
        final result = parseHexColor('00FF5733');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0x00FF5733));
      });
    });

    group('edge case colors', () {
      test('handles black (#000000)', () {
        final result = parseHexColor('#000000');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFF000000));
      });

      test('handles white (#FFFFFF)', () {
        final result = parseHexColor('#FFFFFF');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFFFFFFFF));
      });

      test('handles fully transparent (#00000000)', () {
        final result = parseHexColor('#00000000');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0x00000000));
      });

      test('handles red (#FF0000)', () {
        final result = parseHexColor('#FF0000');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFFFF0000));
      });

      test('handles green (#00FF00)', () {
        final result = parseHexColor('#00FF00');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFF00FF00));
      });

      test('handles blue (#0000FF)', () {
        final result = parseHexColor('#0000FF');

        expect(result.isValid, isTrue);
        expect(result.color, const Color(0xFF0000FF));
      });
    });

    group('invalid hex colors', () {
      const fallbackGray = Color(0xFF808080);

      test('returns fallback for empty string', () {
        final result = parseHexColor('');

        expect(result.isValid, isFalse);
        expect(result.color, fallbackGray);
      });

      test('returns fallback for invalid characters', () {
        final result = parseHexColor('#GGGGGG');

        expect(result.isValid, isFalse);
        expect(result.color, fallbackGray);
      });

      test('returns fallback for too short string (5 chars)', () {
        final result = parseHexColor('#12345');

        expect(result.isValid, isFalse);
        expect(result.color, fallbackGray);
      });

      test('returns fallback for too short string (3 chars)', () {
        final result = parseHexColor('#FFF');

        expect(result.isValid, isFalse);
        expect(result.color, fallbackGray);
      });

      test('returns fallback for too long string (9 chars)', () {
        final result = parseHexColor('#123456789');

        expect(result.isValid, isFalse);
        expect(result.color, fallbackGray);
      });

      test('returns fallback for non-hex string', () {
        final result = parseHexColor('invalid');

        expect(result.isValid, isFalse);
        expect(result.color, fallbackGray);
      });

      test('returns fallback for special characters', () {
        final result = parseHexColor('#FF!@#%');

        expect(result.isValid, isFalse);
        expect(result.color, fallbackGray);
      });

      test('returns fallback for whitespace', () {
        final result = parseHexColor('   ');

        expect(result.isValid, isFalse);
        expect(result.color, fallbackGray);
      });

      test('returns fallback for only # symbol', () {
        final result = parseHexColor('#');

        expect(result.isValid, isFalse);
        expect(result.color, fallbackGray);
      });
    });
  });

  group('hexToColor', () {
    test('returns color from valid hex', () {
      final color = hexToColor('#FF5733');

      expect(color, const Color(0xFFFF5733));
    });

    test('returns fallback color from invalid hex', () {
      final color = hexToColor('invalid');

      expect(color, const Color(0xFF808080));
    });

    test('ignores validity status', () {
      // hexToColor is a convenience wrapper that only returns the color
      final validColor = hexToColor('#FF5733');
      final invalidColor = hexToColor('');

      expect(validColor, isA<Color>());
      expect(invalidColor, isA<Color>());
    });
  });
}
