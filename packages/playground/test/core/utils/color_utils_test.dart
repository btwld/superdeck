import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/utils/color_utils.dart';

void main() {
  group('parseHexColor', () {
    test('parses a 6-digit hex and assumes full opacity', () {
      final result = parseHexColor('#FF5733');
      expect(result.isValid, isTrue);
      expect(result.color, const Color(0xFFFF5733));
    });

    test('parses without the leading #', () {
      final result = parseHexColor('FF5733');
      expect(result.isValid, isTrue);
      expect(result.color, const Color(0xFFFF5733));
    });

    test('parses an 8-digit ARGB hex preserving alpha', () {
      final result = parseHexColor('80FF5733');
      expect(result.isValid, isTrue);
      expect(result.color, const Color(0x80FF5733));
    });

    test('is case-insensitive', () {
      expect(parseHexColor('ff5733').color, const Color(0xFFFF5733));
    });

    test('returns fallback gray and isValid=false for bad input', () {
      final result = parseHexColor('not-a-color');
      expect(result.isValid, isFalse);
      expect(result.color, const Color(0xFF808080));
    });

    test('rejects hex strings of the wrong length', () {
      expect(parseHexColor('FFF').isValid, isFalse);
      expect(parseHexColor('FF57330000').isValid, isFalse);
    });

    test('rejects an empty string', () {
      expect(parseHexColor('').isValid, isFalse);
    });
  });

  group('hexToColor', () {
    test('returns the parsed color', () {
      expect(hexToColor('#0485F7'), const Color(0xFF0485F7));
    });

    test('returns fallback gray for invalid input', () {
      expect(hexToColor('invalid'), const Color(0xFF808080));
    });
  });

  group('colorToHex', () {
    test('formats an opaque color as #RRGGBB', () {
      expect(colorToHex(const Color(0xFF0485F7)), '#0485F7');
    });

    test('drops alpha', () {
      expect(colorToHex(const Color(0x800485F7)), '#0485F7');
    });

    test('uppercases the output', () {
      expect(colorToHex(const Color(0xFFabcdef)), '#ABCDEF');
    });

    test('round-trips through parseHexColor', () {
      const color = Color(0xFF123456);
      final roundTripped = parseHexColor(colorToHex(color)).color;
      expect(roundTripped, color);
    });
  });
}
