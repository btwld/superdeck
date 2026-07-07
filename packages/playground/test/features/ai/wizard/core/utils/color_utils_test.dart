import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/wizard/core/utils/color_utils.dart';

void main() {
  group('parseHexColor', () {
    test('parses a 6-digit hex and assumes full opacity', () {
      final result = parseHexColor('#FF5733');
      expect(result.isValid, isTrue);
      expect(result.color, const Color(0xFFFF5733));
    });

    test('parses an 8-digit ARGB hex preserving alpha', () {
      final result = parseHexColor('80FF5733');
      expect(result.isValid, isTrue);
      expect(result.color, const Color(0x80FF5733));
    });

    test('returns fallback gray and isValid=false for bad input', () {
      final result = parseHexColor('nope');
      expect(result.isValid, isFalse);
      expect(result.color, const Color(0xFF808080));
    });
  });

  group('colorToHex', () {
    test('formats an opaque color as #RRGGBB and drops alpha', () {
      expect(colorToHex(const Color(0x800485F7)), '#0485F7');
    });

    test('round-trips through parseHexColor', () {
      const color = Color(0xFF123456);
      expect(parseHexColor(colorToHex(color)).color, color);
    });
  });
}
