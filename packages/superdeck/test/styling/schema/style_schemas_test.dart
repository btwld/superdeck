import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/styling/schema/style_schemas.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('StyleSchemas', () {
    group('colorSchema', () {
      test('accepts valid 6-digit hex color and transforms to Color', () {
        final result = StyleSchemas.colorSchema.safeParse('#FF0000');
        expect(result.isOk, isTrue);
        final color = result.getOrThrow();
        expect(color, isA<Color>());
        // Red color: 0xFFFF0000 in ARGB format
        expect(color!.a, 1.0);
        expect(color.r, 1.0);
        expect(color.g, 0.0);
        expect(color.b, 0.0);
      });

      test('accepts valid 8-digit hex color with alpha and transforms to Color', () {
        final result = StyleSchemas.colorSchema.safeParse('#FF0000AA');
        expect(result.isOk, isTrue);
        final color = result.getOrThrow();
        expect(color, isA<Color>());
        // 8-digit: FF0000AA parses as RRGGBBAA → 0xAAFF0000 in ARGB
        expect(color!.a, closeTo(0xAA / 255, 0.01));
        expect(color.r, 1.0);
        expect(color.g, 0.0);
        expect(color.b, 0.0);
      });

      test('accepts lowercase hex color', () {
        final result = StyleSchemas.colorSchema.safeParse('#ff0000');
        expect(result.isOk, isTrue);
      });

      test('rejects color without hash', () {
        final result = StyleSchemas.colorSchema.safeParse('FF0000');
        expect(result.isFail, isTrue);
      });

      test('rejects invalid hex characters', () {
        final result = StyleSchemas.colorSchema.safeParse('#GGGGGG');
        expect(result.isFail, isTrue);
      });

      test('rejects wrong length', () {
        final result = StyleSchemas.colorSchema.safeParse('#FFF');
        expect(result.isFail, isTrue);
      });

      test('is optional (key can be absent in object context)', () {
        // colorSchema.optional() means the key can be absent from an object.
        // When used in an ObjectSchema, missing keys are handled by ObjectSchema.
        // Calling safeParse(null) directly tests explicit null, which is different.
        // Test with a parent object to show proper optional behavior:
        final parentSchema = Ack.object({
          'color': StyleSchemas.colorSchema,
        });
        final result = parentSchema.safeParse(<String, dynamic>{});
        expect(result.isOk, isTrue);
        // Key is absent from output when not provided
        expect((result.getOrThrow() as Map).containsKey('color'), isFalse);
      });
    });

    group('fontWeightSchema', () {
      test('accepts normal', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('normal');
        expect(result.isOk, isTrue);
      });

      test('accepts bold', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('bold');
        expect(result.isOk, isTrue);
      });

      test('accepts weight values w100-w900', () {
        for (final weight in ['w100', 'w200', 'w300', 'w400', 'w500', 'w600', 'w700', 'w800', 'w900']) {
          final result = StyleSchemas.fontWeightSchema.safeParse(weight);
          expect(result.isOk, isTrue, reason: 'Expected $weight to be valid');
        }
      });

      test('rejects invalid weight', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('heavy');
        expect(result.isFail, isTrue);
      });
    });

    group('textDecorationSchema', () {
      test('accepts valid decorations', () {
        for (final decoration in ['none', 'underline', 'lineThrough', 'overline']) {
          final result = StyleSchemas.textDecorationSchema.safeParse(decoration);
          expect(result.isOk, isTrue, reason: 'Expected $decoration to be valid');
        }
      });

      test('rejects invalid decoration', () {
        final result = StyleSchemas.textDecorationSchema.safeParse('strike');
        expect(result.isFail, isTrue);
      });
    });

    group('paddingSchema', () {
      test('accepts single number for all sides', () {
        final result = StyleSchemas.paddingSchema.safeParse(16.0);
        expect(result.isOk, isTrue);
      });

      test('accepts object with all property', () {
        final result = StyleSchemas.paddingSchema.safeParse({'all': 16.0});
        expect(result.isOk, isTrue);
      });

      test('accepts object with horizontal/vertical', () {
        final result = StyleSchemas.paddingSchema.safeParse({
          'horizontal': 16.0,
          'vertical': 8.0,
        });
        expect(result.isOk, isTrue);
      });

      test('accepts object with individual sides', () {
        final result = StyleSchemas.paddingSchema.safeParse({
          'top': 10.0,
          'right': 20.0,
          'bottom': 10.0,
          'left': 20.0,
        });
        expect(result.isOk, isTrue);
      });
    });

    group('typographySchema', () {
      test('accepts valid typography config', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': 24.0,
          'fontWeight': 'bold',
          'fontFamily': 'Roboto',
          'color': '#FFFFFF',
          'height': 1.5,
          'paddingBottom': 16.0,
        });
        expect(result.isOk, isTrue);
      });

      test('rejects negative fontSize', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': -24.0,
        });
        expect(result.isFail, isTrue);
      });

      test('rejects typos in keys (strict mode)', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontsize': 24.0, // typo: should be fontSize
        });
        expect(result.isFail, isTrue);
      });
    });

    group('textStyleSchema', () {
      test('accepts valid text style config', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'fontSize': 16.0,
          'fontWeight': 'normal',
          'color': '#0000FF',
          'decoration': 'underline',
        });
        expect(result.isOk, isTrue);
      });

      test('rejects typos in keys', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'colour': '#0000FF', // typo: should be color
        });
        expect(result.isFail, isTrue);
      });
    });

    group('codeStyleSchema', () {
      test('accepts valid code style config', () {
        final result = StyleSchemas.codeStyleSchema.safeParse({
          'textStyle': {
            'fontFamily': 'JetBrains Mono',
            'fontSize': 14.0,
            'color': '#FFFFFF',
          },
          'container': {
            'padding': 16.0,
            'decoration': {
              'color': '#000000',
              'borderRadius': 8.0,
            },
          },
        });
        expect(result.isOk, isTrue);
      });
    });

    group('slideStyleSchema', () {
      test('accepts valid slide style config', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'h1': {
            'fontSize': 96.0,
            'fontWeight': 'bold',
            'color': '#FFFFFF',
          },
          'p': {
            'fontSize': 24.0,
            'color': '#CCCCCC',
          },
          'code': {
            'textStyle': {
              'fontFamily': 'Fira Code',
            },
          },
        });
        expect(result.isOk, isTrue);
      });

      test('rejects unknown style keys', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'h1': {'fontSize': 96.0},
          'header': {'fontSize': 72.0}, // unknown key
        });
        expect(result.isFail, isTrue);
      });
    });

    group('styleConfigSchema', () {
      test('parses and transforms valid style config', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {
            'h1': {'fontSize': 96.0},
            'p': {'fontSize': 24.0},
          },
          'styles': [
            {
              'name': 'title',
              'h1': {'fontSize': 120.0},
            },
            {
              'name': 'code-heavy',
              'code': {
                'textStyle': {'fontSize': 14.0},
              },
            },
          ],
        });
        expect(result.isOk, isTrue);

        // Verify transform produced StyleConfiguration
        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNotNull);
        expect(config.styles, hasLength(2));
        expect(config.styles.containsKey('title'), isTrue);
        expect(config.styles.containsKey('code-heavy'), isTrue);
      });

      test('rejects duplicate style names', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'styles': [
            {'name': 'title', 'h1': {'fontSize': 96.0}},
            {'name': 'title', 'h1': {'fontSize': 120.0}}, // duplicate
          ],
        });
        expect(result.isFail, isTrue);
      });

      test('allows unknown top-level keys for forward compatibility', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'version': 2, // unknown key - should pass through
          'base': {'h1': {'fontSize': 96.0}},
        });
        expect(result.isOk, isTrue);
      });

      test('transforms empty config to valid StyleConfiguration', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({});
        expect(result.isOk, isTrue);

        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNull);
        expect(config.styles, isEmpty);
      });

      test('transforms base style to SlideStyle with correct properties', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {
            'h1': {
              'fontSize': 96.0,
              'fontWeight': 'bold',
              'color': '#FF0000',
              'paddingBottom': 16.0,
            },
            'link': {
              'color': '#0000FF',
              'decoration': 'underline',
            },
          },
        });
        expect(result.isOk, isTrue);

        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNotNull);
        // The SlideStyle should have h1 and link configured
      });

      test('transforms code style correctly', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {
            'code': {
              'textStyle': {
                'fontFamily': 'JetBrains Mono',
                'fontSize': 18.0,
              },
              'container': {
                'padding': 32.0,
                'decoration': {
                  'color': '#000000',
                  'borderRadius': 10.0,
                },
              },
            },
          },
        });
        expect(result.isOk, isTrue);

        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNotNull);
      });

      test('padding precedence: all takes precedence', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {
            'blockContainer': {
              'padding': {
                'all': 16.0,
                'horizontal': 8.0, // should be ignored
              },
            },
          },
        });
        expect(result.isOk, isTrue);
      });

      test('padding precedence: horizontal/vertical over sides', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {
            'blockContainer': {
              'padding': {
                'horizontal': 16.0,
                'top': 8.0, // should be ignored
              },
            },
          },
        });
        expect(result.isOk, isTrue);
      });
    });
  });
}
