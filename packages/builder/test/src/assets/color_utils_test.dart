import 'package:superdeck_builder/src/assets/color_utils.dart';
import 'package:test/test.dart';

void main() {
  group('ColorUtils', () {
    group('parseHex', () {
      test('parses standard hex format #RRGGBB', () {
        expect(ColorUtils.parseHex('#ff0000'), equals((255, 0, 0)));
        expect(ColorUtils.parseHex('#00ff00'), equals((0, 255, 0)));
        expect(ColorUtils.parseHex('#0000ff'), equals((0, 0, 255)));
      });

      test('parses shorthand hex format #RGB', () {
        expect(ColorUtils.parseHex('#f00'), equals((255, 0, 0)));
        expect(ColorUtils.parseHex('#0f0'), equals((0, 255, 0)));
        expect(ColorUtils.parseHex('#00f'), equals((0, 0, 255)));
      });

      test('parses hex without # prefix', () {
        expect(ColorUtils.parseHex('ff0000'), equals((255, 0, 0)));
        expect(ColorUtils.parseHex('f00'), equals((255, 0, 0)));
      });

      test('parses gray colors', () {
        expect(ColorUtils.parseHex('#808080'), equals((128, 128, 128)));
        expect(ColorUtils.parseHex('#888'), equals((136, 136, 136)));
      });

      test('throws on invalid hex', () {
        expect(() => ColorUtils.parseHex('invalid'), throwsArgumentError);
        expect(() => ColorUtils.parseHex('#12'), throwsArgumentError);
        expect(() => ColorUtils.parseHex('#12345'), throwsArgumentError);
      });
    });

    group('toHex', () {
      test('converts RGB to hex string', () {
        expect(ColorUtils.toHex(255, 0, 0), equals('#ff0000'));
        expect(ColorUtils.toHex(0, 255, 0), equals('#00ff00'));
        expect(ColorUtils.toHex(0, 0, 255), equals('#0000ff'));
      });

      test('pads single-digit values with zero', () {
        expect(ColorUtils.toHex(15, 15, 15), equals('#0f0f0f'));
        expect(ColorUtils.toHex(0, 0, 0), equals('#000000'));
      });

      test('converts gray colors', () {
        expect(ColorUtils.toHex(128, 128, 128), equals('#808080'));
        expect(ColorUtils.toHex(255, 255, 255), equals('#ffffff'));
      });
    });

    group('lighten', () {
      test('lightens gray by interpolating toward white', () {
        final result = ColorUtils.lighten('#808080', 0.5);
        final lum = ColorUtils.luminance(result);
        expect(lum, greaterThan(ColorUtils.luminance('#808080')));
      });

      test('amount of 0.0 returns original color', () {
        expect(ColorUtils.lighten('#808080', 0.0), equals('#808080'));
      });

      test('amount of 1.0 returns white', () {
        expect(ColorUtils.lighten('#000000', 1.0), equals('#ffffff'));
        expect(ColorUtils.lighten('#808080', 1.0), equals('#ffffff'));
      });

      test('lightens blue color', () {
        final darker = '#0066ff';
        final lighter = ColorUtils.lighten(darker, 0.3);
        expect(ColorUtils.luminance(lighter), greaterThan(ColorUtils.luminance(darker)));
      });
    });

    group('darken', () {
      test('darkens gray by interpolating toward black', () {
        final result = ColorUtils.darken('#808080', 0.5);
        final lum = ColorUtils.luminance(result);
        expect(lum, lessThan(ColorUtils.luminance('#808080')));
      });

      test('amount of 0.0 returns original color', () {
        expect(ColorUtils.darken('#808080', 0.0), equals('#808080'));
      });

      test('amount of 1.0 returns black', () {
        expect(ColorUtils.darken('#ffffff', 1.0), equals('#000000'));
        expect(ColorUtils.darken('#808080', 1.0), equals('#000000'));
      });

      test('darkens blue color', () {
        final lighter = '#0066ff';
        final darker = ColorUtils.darken(lighter, 0.3);
        expect(ColorUtils.luminance(darker), lessThan(ColorUtils.luminance(lighter)));
      });
    });

    group('luminance', () {
      test('black has luminance of 0', () {
        expect(ColorUtils.luminance('#000000'), closeTo(0.0, 0.001));
      });

      test('white has luminance of 1', () {
        expect(ColorUtils.luminance('#ffffff'), closeTo(1.0, 0.001));
      });

      test('gray has intermediate luminance', () {
        final lum = ColorUtils.luminance('#808080');
        expect(lum, greaterThan(0.0));
        expect(lum, lessThan(1.0));
      });

      test('calculates correct relative luminance for colors', () {
        // Green should have higher luminance than red or blue
        // due to WCAG weighting (0.7152 for green)
        final redLum = ColorUtils.luminance('#ff0000');
        final greenLum = ColorUtils.luminance('#00ff00');
        final blueLum = ColorUtils.luminance('#0000ff');

        expect(greenLum, greaterThan(redLum));
        expect(greenLum, greaterThan(blueLum));
      });
    });

    group('contrastColor', () {
      test('returns dark color for light backgrounds', () {
        expect(ColorUtils.contrastColor('#ffffff'), equals('#000000'));
        expect(ColorUtils.contrastColor('#f0f0f0'), equals('#000000'));
      });

      test('returns light color for dark backgrounds', () {
        expect(ColorUtils.contrastColor('#000000'), equals('#ffffff'));
        expect(ColorUtils.contrastColor('#1a1a1a'), equals('#ffffff'));
      });

      test('handles mid-tone backgrounds appropriately', () {
        final result = ColorUtils.contrastColor('#808080');
        // Gray should return one or the other based on threshold
        expect(result, anyOf(equals('#ffffff'), equals('#000000')));
      });

      test('accepts custom light and dark colors', () {
        final result = ColorUtils.contrastColor(
          '#ffffff',
          light: '#e0e0e0',
          dark: '#2a2a2a',
        );
        expect(result, equals('#2a2a2a'));
      });
    });

    group('round-trip conversions', () {
      test('parseHex and toHex are inverse operations', () {
        const testColors = ['#ff0000', '#00ff00', '#0000ff', '#808080', '#123456'];

        for (final color in testColors) {
          final (r, g, b) = ColorUtils.parseHex(color);
          final reconstructed = ColorUtils.toHex(r, g, b);
          expect(reconstructed, equals(color));
        }
      });
    });
  });
}
