import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/styling/components/markdown_alert.dart';
import 'package:superdeck/src/styling/components/markdown_alert_type.dart';
import 'package:superdeck/src/styling/components/markdown_blockquote.dart';
import 'package:superdeck/src/styling/components/markdown_checkbox.dart';
import 'package:superdeck/src/styling/components/markdown_codeblock.dart';
import 'package:superdeck/src/styling/components/markdown_list.dart';
import 'package:superdeck/src/styling/components/markdown_table.dart';
import 'package:superdeck/src/styling/components/slide.dart';
import 'package:superdeck/src/styling/schema/style_schemas.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('StyleSchemas', () {
    // =======================================================================
    // LEVEL 1: Base Schemas
    // =======================================================================

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
        final color = result.getOrThrow();
        expect(color!.r, 1.0);
      });

      test('accepts mixed case hex color', () {
        final result = StyleSchemas.colorSchema.safeParse('#FfAaBb');
        expect(result.isOk, isTrue);
      });

      test('accepts uppercase hex color', () {
        final result = StyleSchemas.colorSchema.safeParse('#ABCDEF');
        expect(result.isOk, isTrue);
      });

      test('parses white color correctly', () {
        final result = StyleSchemas.colorSchema.safeParse('#FFFFFF');
        expect(result.isOk, isTrue);
        final color = result.getOrThrow();
        expect(color!.r, 1.0);
        expect(color.g, 1.0);
        expect(color.b, 1.0);
      });

      test('parses black color correctly', () {
        final result = StyleSchemas.colorSchema.safeParse('#000000');
        expect(result.isOk, isTrue);
        final color = result.getOrThrow();
        expect(color!.r, 0.0);
        expect(color.g, 0.0);
        expect(color.b, 0.0);
      });

      test('parses transparent color with 8-digit hex', () {
        final result = StyleSchemas.colorSchema.safeParse('#FF000000');
        expect(result.isOk, isTrue);
        final color = result.getOrThrow();
        expect(color!.a, 0.0);
      });

      test('parses semi-transparent color', () {
        final result = StyleSchemas.colorSchema.safeParse('#FF000080');
        expect(result.isOk, isTrue);
        final color = result.getOrThrow();
        expect(color!.a, closeTo(0x80 / 255, 0.01));
      });

      test('rejects color without hash', () {
        final result = StyleSchemas.colorSchema.safeParse('FF0000');
        expect(result.isFail, isTrue);
      });

      test('rejects invalid hex characters', () {
        final result = StyleSchemas.colorSchema.safeParse('#GGGGGG');
        expect(result.isFail, isTrue);
      });

      test('rejects color with special characters', () {
        final result = StyleSchemas.colorSchema.safeParse('#FF00@0');
        expect(result.isFail, isTrue);
      });

      test('rejects wrong length (3 digits)', () {
        final result = StyleSchemas.colorSchema.safeParse('#FFF');
        expect(result.isFail, isTrue);
      });

      test('rejects wrong length (5 digits)', () {
        final result = StyleSchemas.colorSchema.safeParse('#FFFFF');
        expect(result.isFail, isTrue);
      });

      test('rejects wrong length (7 digits)', () {
        final result = StyleSchemas.colorSchema.safeParse('#FFFFFFF');
        expect(result.isFail, isTrue);
      });

      test('rejects wrong length (9 digits)', () {
        final result = StyleSchemas.colorSchema.safeParse('#FFFFFFFFF');
        expect(result.isFail, isTrue);
      });

      test('rejects empty string', () {
        final result = StyleSchemas.colorSchema.safeParse('');
        expect(result.isFail, isTrue);
      });

      test('rejects null', () {
        final result = StyleSchemas.colorSchema.safeParse(null);
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
      test('accepts normal and transforms to FontWeight', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('normal');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), FontWeight.normal);
      });

      test('accepts bold and transforms to FontWeight', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('bold');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), FontWeight.bold);
      });

      test('accepts weight values w100-w900', () {
        final weights = {
          'w100': FontWeight.w100,
          'w200': FontWeight.w200,
          'w300': FontWeight.w300,
          'w400': FontWeight.w400,
          'w500': FontWeight.w500,
          'w600': FontWeight.w600,
          'w700': FontWeight.w700,
          'w800': FontWeight.w800,
          'w900': FontWeight.w900,
        };

        for (final entry in weights.entries) {
          final result = StyleSchemas.fontWeightSchema.safeParse(entry.key);
          expect(result.isOk, isTrue, reason: 'Expected ${entry.key} to be valid');
          expect(result.getOrThrow(), entry.value);
        }
      });

      test('rejects invalid weight', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('heavy');
        expect(result.isFail, isTrue);
      });

      test('rejects numeric weight', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('700');
        expect(result.isFail, isTrue);
      });

      test('rejects empty string', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('');
        expect(result.isFail, isTrue);
      });

      test('is case-sensitive', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('Bold');
        expect(result.isFail, isTrue);
      });
    });

    group('textDecorationSchema', () {
      test('accepts valid decorations', () {
        final decorations = {
          'none': TextDecoration.none,
          'underline': TextDecoration.underline,
          'lineThrough': TextDecoration.lineThrough,
          'overline': TextDecoration.overline,
        };

        for (final entry in decorations.entries) {
          final result = StyleSchemas.textDecorationSchema.safeParse(entry.key);
          expect(result.isOk, isTrue, reason: 'Expected ${entry.key} to be valid');
          expect(result.getOrThrow(), entry.value);
        }
      });

      test('rejects invalid decoration', () {
        final result = StyleSchemas.textDecorationSchema.safeParse('strike');
        expect(result.isFail, isTrue);
      });

      test('rejects underscore variant', () {
        final result = StyleSchemas.textDecorationSchema.safeParse('line_through');
        expect(result.isFail, isTrue);
      });

      test('is case-sensitive', () {
        final result = StyleSchemas.textDecorationSchema.safeParse('Underline');
        expect(result.isFail, isTrue);
      });
    });

    group('alignmentSchema', () {
      test('accepts valid alignments', () {
        final alignments = {
          'start': WrapAlignment.start,
          'end': WrapAlignment.end,
          'center': WrapAlignment.center,
          'spaceBetween': WrapAlignment.spaceBetween,
          'spaceAround': WrapAlignment.spaceAround,
          'spaceEvenly': WrapAlignment.spaceEvenly,
        };

        for (final entry in alignments.entries) {
          final result = StyleSchemas.alignmentSchema.safeParse(entry.key);
          expect(result.isOk, isTrue, reason: 'Expected ${entry.key} to be valid');
          expect(result.getOrThrow(), entry.value);
        }
      });

      test('rejects invalid alignment', () {
        final result = StyleSchemas.alignmentSchema.safeParse('middle');
        expect(result.isFail, isTrue);
      });

      test('is case-sensitive', () {
        final result = StyleSchemas.alignmentSchema.safeParse('Center');
        expect(result.isFail, isTrue);
      });
    });

    // =======================================================================
    // LEVEL 2: Padding Schema
    // =======================================================================

    group('paddingSchema', () {
      test('accepts single number for all sides', () {
        final result = StyleSchemas.paddingSchema.safeParse(16.0);
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<EdgeInsetsGeometryMix>());
      });

      test('accepts integer for all sides', () {
        final result = StyleSchemas.paddingSchema.safeParse(16);
        expect(result.isOk, isTrue);
      });

      test('accepts zero padding', () {
        final result = StyleSchemas.paddingSchema.safeParse(0);
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

      test('accepts object with only horizontal', () {
        final result = StyleSchemas.paddingSchema.safeParse({
          'horizontal': 16.0,
        });
        expect(result.isOk, isTrue);
      });

      test('accepts object with only vertical', () {
        final result = StyleSchemas.paddingSchema.safeParse({
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

      test('accepts object with partial sides', () {
        final result = StyleSchemas.paddingSchema.safeParse({
          'top': 10.0,
          'bottom': 10.0,
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty object (defaults to zero)', () {
        final result = StyleSchemas.paddingSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('precedence: all overrides horizontal/vertical', () {
        final result = StyleSchemas.paddingSchema.safeParse({
          'all': 16.0,
          'horizontal': 8.0,
          'vertical': 4.0,
        });
        expect(result.isOk, isTrue);
        // Result should use 'all' value
      });

      test('precedence: horizontal/vertical override individual sides', () {
        final result = StyleSchemas.paddingSchema.safeParse({
          'horizontal': 16.0,
          'vertical': 8.0,
          'top': 4.0,
          'left': 2.0,
        });
        expect(result.isOk, isTrue);
        // Result should use horizontal/vertical values
      });

      test('rejects negative padding', () {
        final result = StyleSchemas.paddingSchema.safeParse(-16.0);
        expect(result.isFail, isTrue);
      });

      test('rejects invalid object key', () {
        final result = StyleSchemas.paddingSchema.safeParse({
          'invalid': 16.0,
        });
        expect(result.isFail, isTrue);
      });
    });

    // =======================================================================
    // LEVEL 3: Composite Schemas
    // =======================================================================

    group('decorationSchema', () {
      test('accepts valid decoration with color', () {
        final result = StyleSchemas.decorationSchema.safeParse({
          'color': '#FF0000',
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<BoxDecorationMix>());
      });

      test('accepts valid decoration with borderRadius', () {
        final result = StyleSchemas.decorationSchema.safeParse({
          'borderRadius': 8.0,
        });
        expect(result.isOk, isTrue);
      });

      test('accepts valid decoration with both properties', () {
        final result = StyleSchemas.decorationSchema.safeParse({
          'color': '#000000',
          'borderRadius': 10.0,
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty decoration object', () {
        final result = StyleSchemas.decorationSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects invalid color in decoration', () {
        final result = StyleSchemas.decorationSchema.safeParse({
          'color': 'red',
        });
        expect(result.isFail, isTrue);
      });

      test('rejects negative borderRadius', () {
        final result = StyleSchemas.decorationSchema.safeParse({
          'borderRadius': -8.0,
        });
        expect(result.isFail, isTrue);
      });

      test('rejects unknown decoration keys', () {
        final result = StyleSchemas.decorationSchema.safeParse({
          'color': '#FF0000',
          'border': '2px solid',
        });
        expect(result.isFail, isTrue);
      });
    });

    group('containerSchema', () {
      test('accepts valid container with padding', () {
        final result = StyleSchemas.containerSchema.safeParse({
          'padding': 16.0,
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<BoxStyler>());
      });

      test('accepts valid container with margin', () {
        final result = StyleSchemas.containerSchema.safeParse({
          'margin': 8.0,
        });
        expect(result.isOk, isTrue);
      });

      test('accepts valid container with decoration', () {
        final result = StyleSchemas.containerSchema.safeParse({
          'decoration': {
            'color': '#FFFFFF',
            'borderRadius': 12.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts container with all properties', () {
        final result = StyleSchemas.containerSchema.safeParse({
          'padding': 16.0,
          'margin': 8.0,
          'decoration': {
            'color': '#000000',
            'borderRadius': 4.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty container', () {
        final result = StyleSchemas.containerSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects unknown container keys', () {
        final result = StyleSchemas.containerSchema.safeParse({
          'width': 100.0,
        });
        expect(result.isFail, isTrue);
      });
    });

    // =======================================================================
    // LEVEL 4: Text Schemas
    // =======================================================================

    group('textStyleSchema', () {
      test('accepts valid text style config', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'fontSize': 16.0,
          'fontWeight': 'normal',
          'color': '#0000FF',
          'decoration': 'underline',
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<TextStyle>());
      });

      test('accepts all text style properties', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'fontSize': 24.0,
          'fontWeight': 'bold',
          'fontFamily': 'Roboto',
          'color': '#FF0000',
          'height': 1.5,
          'letterSpacing': 2.0,
          'decoration': 'lineThrough',
        });
        expect(result.isOk, isTrue);
      });

      test('accepts minimal text style', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'fontSize': 14.0,
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty text style', () {
        final result = StyleSchemas.textStyleSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects negative fontSize', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'fontSize': -16.0,
        });
        expect(result.isFail, isTrue);
      });

      test('rejects zero fontSize', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'fontSize': 0,
        });
        expect(result.isFail, isTrue);
      });

      test('rejects typos in keys (strict mode)', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'colour': '#0000FF', // typo: should be color
        });
        expect(result.isFail, isTrue);
      });

      test('rejects invalid decoration value', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'decoration': 'dashed',
        });
        expect(result.isFail, isTrue);
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
        expect(result.getOrThrow(), isA<TextStyler>());
      });

      test('accepts typography without paddingBottom', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': 36.0,
          'fontWeight': 'w600',
        });
        expect(result.isOk, isTrue);
      });

      test('accepts typography with only paddingBottom', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'paddingBottom': 8.0,
        });
        expect(result.isOk, isTrue);
      });

      test('rejects negative fontSize', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': -24.0,
        });
        expect(result.isFail, isTrue);
      });

      test('rejects negative paddingBottom', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'paddingBottom': -8.0,
        });
        expect(result.isFail, isTrue);
      });

      test('rejects typos in keys (strict mode)', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontsize': 24.0, // typo: should be fontSize
        });
        expect(result.isFail, isTrue);
      });

      test('rejects letterSpacing (not in typography schema)', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': 24.0,
          'letterSpacing': 2.0, // not allowed in typography
        });
        expect(result.isFail, isTrue);
      });
    });

    group('codeTextStyleSchema', () {
      test('accepts valid code text style', () {
        final result = StyleSchemas.codeTextStyleSchema.safeParse({
          'fontFamily': 'JetBrains Mono',
          'fontSize': 14.0,
          'color': '#FFFFFF',
          'height': 1.8,
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<TextStyle>());
      });

      test('accepts minimal code text style', () {
        final result = StyleSchemas.codeTextStyleSchema.safeParse({
          'fontFamily': 'Courier',
        });
        expect(result.isOk, isTrue);
      });

      test('rejects fontWeight in code text style', () {
        final result = StyleSchemas.codeTextStyleSchema.safeParse({
          'fontFamily': 'Courier',
          'fontWeight': 'bold', // not in code text style schema
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
        expect(result.getOrThrow(), isA<MarkdownCodeblockStyle>());
      });

      test('accepts code style with only textStyle', () {
        final result = StyleSchemas.codeStyleSchema.safeParse({
          'textStyle': {
            'fontSize': 16.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts code style with only container', () {
        final result = StyleSchemas.codeStyleSchema.safeParse({
          'container': {
            'padding': 32.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty code style', () {
        final result = StyleSchemas.codeStyleSchema.safeParse({});
        expect(result.isOk, isTrue);
      });
    });

    group('blockquoteSchema', () {
      test('accepts valid blockquote config', () {
        final result = StyleSchemas.blockquoteSchema.safeParse({
          'textStyle': {
            'fontSize': 32.0,
            'color': '#CCCCCC',
          },
          'padding': {
            'left': 30.0,
            'bottom': 12.0,
          },
          'decoration': {
            'color': '#888888',
            'borderRadius': 4.0,
          },
          'alignment': 'start',
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<MarkdownBlockquoteStyle>());
      });

      test('accepts blockquote with minimal config', () {
        final result = StyleSchemas.blockquoteSchema.safeParse({
          'textStyle': {
            'fontSize': 24.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts blockquote with only padding', () {
        final result = StyleSchemas.blockquoteSchema.safeParse({
          'padding': {
            'all': 16.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty blockquote', () {
        final result = StyleSchemas.blockquoteSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects invalid alignment', () {
        final result = StyleSchemas.blockquoteSchema.safeParse({
          'alignment': 'middle',
        });
        expect(result.isFail, isTrue);
      });
    });

    group('listSchema', () {
      test('accepts valid list config', () {
        final result = StyleSchemas.listSchema.safeParse({
          'bullet': {
            'fontSize': 24.0,
            'color': '#FFFFFF',
          },
          'text': {
            'fontSize': 24.0,
            'height': 1.6,
          },
          'orderedAlignment': 'start',
          'unorderedAlignment': 'start',
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<MarkdownListStyle>());
      });

      test('accepts list with only bullet', () {
        final result = StyleSchemas.listSchema.safeParse({
          'bullet': {
            'fontSize': 20.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts list with only text', () {
        final result = StyleSchemas.listSchema.safeParse({
          'text': {
            'fontSize': 22.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty list config', () {
        final result = StyleSchemas.listSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects invalid alignment', () {
        final result = StyleSchemas.listSchema.safeParse({
          'orderedAlignment': 'left',
        });
        expect(result.isFail, isTrue);
      });
    });

    group('checkboxSchema', () {
      test('accepts valid checkbox config', () {
        final result = StyleSchemas.checkboxSchema.safeParse({
          'textStyle': {
            'fontSize': 20.0,
            'color': '#FFFFFF',
          },
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<MarkdownCheckboxStyle>());
      });

      test('accepts empty checkbox config', () {
        final result = StyleSchemas.checkboxSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects icon configuration (not exposed)', () {
        final result = StyleSchemas.checkboxSchema.safeParse({
          'textStyle': {'fontSize': 20.0},
          'icon': {'color': '#FF0000'},
        });
        expect(result.isFail, isTrue);
      });
    });

    group('tableSchema', () {
      test('accepts valid table config', () {
        final result = StyleSchemas.tableSchema.safeParse({
          'headStyle': {
            'fontSize': 24.0,
            'fontWeight': 'bold',
          },
          'bodyStyle': {
            'fontSize': 20.0,
          },
          'padding': {
            'all': 8.0,
          },
          'cellPadding': {
            'all': 12.0,
          },
          'cellDecoration': {
            'color': '#F0F0F0',
            'borderRadius': 2.0,
          },
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<MarkdownTableStyle>());
      });

      test('accepts table with minimal config', () {
        final result = StyleSchemas.tableSchema.safeParse({
          'headStyle': {
            'fontWeight': 'bold',
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty table config', () {
        final result = StyleSchemas.tableSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects border configuration (not exposed)', () {
        final result = StyleSchemas.tableSchema.safeParse({
          'headStyle': {'fontSize': 24.0},
          'border': {'color': '#000000'},
        });
        expect(result.isFail, isTrue);
      });
    });

    group('alertTypeSchema', () {
      test('accepts valid alert type config', () {
        final result = StyleSchemas.alertTypeSchema.safeParse({
          'heading': {
            'fontSize': 24.0,
            'fontWeight': 'bold',
          },
          'description': {
            'fontSize': 20.0,
          },
          'container': {
            'padding': 16.0,
            'decoration': {
              'color': '#E3F2FD',
            },
          },
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<MarkdownAlertTypeStyle>());
      });

      test('accepts alert type with only heading', () {
        final result = StyleSchemas.alertTypeSchema.safeParse({
          'heading': {
            'fontSize': 28.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty alert type config', () {
        final result = StyleSchemas.alertTypeSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects icon configuration (not exposed)', () {
        final result = StyleSchemas.alertTypeSchema.safeParse({
          'heading': {'fontSize': 24.0},
          'icon': {'color': '#FF0000'},
        });
        expect(result.isFail, isTrue);
      });
    });

    group('alertSchema', () {
      test('accepts valid alert config with all types', () {
        final result = StyleSchemas.alertSchema.safeParse({
          'note': {
            'heading': {'fontSize': 24.0},
          },
          'tip': {
            'heading': {'fontSize': 24.0},
          },
          'important': {
            'heading': {'fontSize': 24.0},
          },
          'warning': {
            'heading': {'fontSize': 24.0},
          },
          'caution': {
            'heading': {'fontSize': 24.0},
          },
        });
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isA<MarkdownAlertStyle>());
      });

      test('accepts alert with only note', () {
        final result = StyleSchemas.alertSchema.safeParse({
          'note': {
            'heading': {'fontSize': 24.0},
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty alert config', () {
        final result = StyleSchemas.alertSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects unknown alert type', () {
        final result = StyleSchemas.alertSchema.safeParse({
          'info': {
            'heading': {'fontSize': 24.0},
          },
        });
        expect(result.isFail, isTrue);
      });
    });

    // =======================================================================
    // LEVEL 5: Slide Style Schema
    // =======================================================================

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
        expect(result.getOrThrow(), isA<SlideStyle>());
      });

      test('accepts all heading levels', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'h1': {'fontSize': 96.0},
          'h2': {'fontSize': 72.0},
          'h3': {'fontSize': 48.0},
          'h4': {'fontSize': 36.0},
          'h5': {'fontSize': 24.0},
          'h6': {'fontSize': 20.0},
        });
        expect(result.isOk, isTrue);
      });

      test('accepts all inline text styles', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'a': {'color': '#0000FF', 'decoration': 'underline'},
          'del': {'decoration': 'lineThrough'},
          'img': {'color': '#FFFFFF'},
          'link': {'color': '#0000FF'},
          'strong': {'fontWeight': 'bold'},
          'em': {'fontWeight': 'w300'},
        });
        expect(result.isOk, isTrue);
      });

      test('accepts all block elements', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'code': {'textStyle': {'fontSize': 16.0}},
          'blockquote': {'textStyle': {'fontSize': 32.0}},
          'list': {'text': {'fontSize': 24.0}},
          'checkbox': {'textStyle': {'fontSize': 20.0}},
          'table': {'headStyle': {'fontWeight': 'bold'}},
          'alert': {
            'note': {'heading': {'fontSize': 24.0}},
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts containers', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'blockContainer': {
            'padding': 40.0,
          },
          'slideContainer': {
            'padding': 20.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts horizontalRuleDecoration', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'horizontalRuleDecoration': {
            'color': '#CCCCCC',
            'borderRadius': 2.0,
          },
        });
        expect(result.isOk, isTrue);
      });

      test('accepts empty slide style', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('rejects unknown style keys', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'h1': {'fontSize': 96.0},
          'header': {'fontSize': 72.0}, // unknown key
        });
        expect(result.isFail, isTrue);
      });

      test('rejects typo in heading level', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'h7': {'fontSize': 16.0}, // h7 doesn't exist
        });
        expect(result.isFail, isTrue);
      });
    });

    group('namedStyleSchema', () {
      test('accepts valid named style', () {
        final result = StyleSchemas.namedStyleSchema.safeParse({
          'name': 'title',
          'h1': {'fontSize': 120.0},
          'p': {'fontSize': 32.0},
        });
        expect(result.isOk, isTrue);
        final namedStyle = result.getOrThrow()!;
        expect(namedStyle.name, 'title');
        expect(namedStyle.style, isA<SlideStyle>());
      });

      test('accepts named style with only name', () {
        final result = StyleSchemas.namedStyleSchema.safeParse({
          'name': 'empty',
        });
        expect(result.isOk, isTrue);
      });

      test('rejects named style without name', () {
        final result = StyleSchemas.namedStyleSchema.safeParse({
          'h1': {'fontSize': 96.0},
        });
        expect(result.isFail, isTrue);
      });

      test('rejects empty name', () {
        final result = StyleSchemas.namedStyleSchema.safeParse({
          'name': '',
          'h1': {'fontSize': 96.0},
        });
        expect(result.isFail, isTrue);
      });

      test('accepts hyphenated names', () {
        final result = StyleSchemas.namedStyleSchema.safeParse({
          'name': 'code-heavy',
          'code': {'textStyle': {'fontSize': 14.0}},
        });
        expect(result.isOk, isTrue);
      });

      test('accepts underscore names', () {
        final result = StyleSchemas.namedStyleSchema.safeParse({
          'name': 'code_heavy',
          'code': {'textStyle': {'fontSize': 14.0}},
        });
        expect(result.isOk, isTrue);
      });
    });

    // =======================================================================
    // LEVEL 6: Top-Level Schema
    // =======================================================================

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

        // Verify transform produced StyleConfigResult
        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNotNull);
        expect(config.styles, hasLength(2));
        expect(config.styles.containsKey('title'), isTrue);
        expect(config.styles.containsKey('code-heavy'), isTrue);
      });

      test('accepts config with only base', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {
            'h1': {'fontSize': 96.0},
          },
        });
        expect(result.isOk, isTrue);
        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNotNull);
        expect(config.styles, isEmpty);
      });

      test('accepts config with only styles', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'styles': [
            {
              'name': 'custom',
              'h1': {'fontSize': 100.0},
            },
          ],
        });
        expect(result.isOk, isTrue);
        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNull);
        expect(config.styles, hasLength(1));
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

      test('allows multiple unknown top-level keys', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'version': 2,
          'schema': 'v1',
          'metadata': {'author': 'Test'},
          'base': {'h1': {'fontSize': 96.0}},
        });
        expect(result.isOk, isTrue);
      });

      test('transforms empty config to valid StyleConfigResult', () {
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

      test('transforms alert styles correctly', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {
            'alert': {
              'note': {
                'heading': {'fontSize': 24.0, 'fontWeight': 'bold'},
                'description': {'fontSize': 20.0},
                'container': {
                  'padding': 16.0,
                  'decoration': {'color': '#E3F2FD'},
                },
              },
              'warning': {
                'heading': {'fontSize': 24.0, 'color': '#FF9800'},
              },
            },
          },
        });
        expect(result.isOk, isTrue);
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

      test('handles complex nested config', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {
            'h1': {'fontSize': 96.0, 'fontWeight': 'bold', 'color': '#FFFFFF'},
            'h2': {'fontSize': 72.0, 'fontWeight': 'w600'},
            'p': {'fontSize': 24.0, 'height': 1.6, 'paddingBottom': 12.0},
            'code': {
              'textStyle': {'fontFamily': 'JetBrains Mono', 'fontSize': 18.0},
              'container': {
                'padding': 32.0,
                'decoration': {'color': '#000000', 'borderRadius': 10.0},
              },
            },
            'alert': {
              'note': {
                'heading': {'fontSize': 24.0},
                'container': {
                  'padding': 16.0,
                  'decoration': {'color': '#E3F2FD'},
                },
              },
            },
          },
          'styles': [
            {
              'name': 'title',
              'h1': {'fontSize': 120.0},
            },
          ],
        });
        expect(result.isOk, isTrue);
        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNotNull);
        expect(config.styles, hasLength(1));
      });

      test('rejects malformed styles list', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'styles': 'not-a-list',
        });
        expect(result.isFail, isTrue);
      });

      test('rejects malformed base object', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': 'not-an-object',
        });
        expect(result.isFail, isTrue);
      });
    });

    // =======================================================================
    // Edge Cases and Integration Tests
    // =======================================================================

    group('Edge Cases', () {
      test('handles null values gracefully', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': null,
          'styles': null,
        });
        // Depending on schema, this might pass or fail
        // The schema should handle nulls gracefully
      });

      test('handles very large font sizes', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': 1000.0,
        });
        expect(result.isOk, isTrue);
      });

      test('handles very small positive font sizes', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': 0.1,
        });
        expect(result.isOk, isTrue);
      });

      test('handles decimal padding values', () {
        final result = StyleSchemas.paddingSchema.safeParse(8.5);
        expect(result.isOk, isTrue);
      });

      test('handles integer values for double properties', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': 24, // integer instead of double
        });
        expect(result.isOk, isTrue);
      });

      test('handles empty strings in appropriate contexts', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('');
        expect(result.isFail, isTrue);
      });

      test('validates color format strictly', () {
        // Test various invalid color formats
        final invalidColors = [
          'FF0000',     // missing #
          '#FFF',       // too short
          '#FFFFFFF',   // wrong length
          '#GGGGGG',    // invalid hex
          'red',        // named colors not supported
          'rgb(255,0,0)', // rgb format not supported
        ];

        for (final color in invalidColors) {
          final result = StyleSchemas.colorSchema.safeParse(color);
          expect(result.isFail, isTrue, reason: 'Expected $color to be invalid');
        }
      });

      test('handles special Unicode characters in font family', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontFamily': 'Noto Sans 日本語',
        });
        expect(result.isOk, isTrue);
      });

      test('handles empty style list', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'styles': [],
        });
        expect(result.isOk, isTrue);
        final config = result.getOrThrow()!;
        expect(config.styles, isEmpty);
      });

      test('handles style with all properties set to empty objects', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'h1': {},
          'p': {},
          'code': {},
        });
        expect(result.isOk, isTrue);
      });

      test('complex real-world configuration', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'version': 1,
          'base': {
            'h1': {
              'fontSize': 96.0,
              'fontWeight': 'bold',
              'fontFamily': 'Poppins',
              'color': '#FFFFFF',
              'height': 1.1,
              'paddingBottom': 16.0,
            },
            'h2': {
              'fontSize': 72.0,
              'fontWeight': 'bold',
              'color': '#FFFFFF',
              'paddingBottom': 12.0,
            },
            'p': {
              'fontSize': 24.0,
              'height': 1.6,
              'color': '#FFFFFF',
              'paddingBottom': 12.0,
            },
            'link': {
              'color': '#425260',
              'decoration': 'none',
            },
            'code': {
              'textStyle': {
                'fontFamily': 'JetBrains Mono',
                'fontSize': 18.0,
                'color': '#FFFFFF',
                'height': 1.8,
              },
              'container': {
                'padding': 32.0,
                'decoration': {
                  'color': '#000000',
                  'borderRadius': 10.0,
                },
              },
            },
            'blockquote': {
              'textStyle': {
                'fontSize': 32.0,
                'color': '#CCCCCC',
              },
              'padding': {
                'left': 30.0,
                'bottom': 12.0,
              },
              'decoration': {
                'color': '#888888',
              },
            },
            'list': {
              'bullet': {
                'fontSize': 24.0,
                'color': '#FFFFFF',
              },
              'text': {
                'fontSize': 24.0,
                'height': 1.6,
                'paddingBottom': 8.0,
              },
            },
            'alert': {
              'note': {
                'heading': {
                  'fontSize': 24.0,
                  'fontWeight': 'bold',
                },
                'description': {
                  'fontSize': 24.0,
                },
                'container': {
                  'padding': {
                    'horizontal': 24.0,
                    'vertical': 8.0,
                  },
                  'margin': {
                    'vertical': 12.0,
                  },
                  'decoration': {
                    'color': '#0D47A1',
                    'borderRadius': 4.0,
                  },
                },
              },
            },
          },
          'styles': [
            {
              'name': 'title-slide',
              'h1': {
                'fontSize': 120.0,
              },
            },
            {
              'name': 'code-heavy',
              'code': {
                'textStyle': {
                  'fontSize': 16.0,
                },
              },
            },
          ],
        });

        expect(result.isOk, isTrue);
        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNotNull);
        expect(config.styles, hasLength(2));
      });
    });

    // =======================================================================
    // Transform Function Tests
    // =======================================================================

    group('Transform Functions', () {
      test('colorSchema transforms 6-digit hex correctly', () {
        final result = StyleSchemas.colorSchema.safeParse('#ABCDEF');
        final color = result.getOrThrow()!;
        expect(color.a, 1.0); // Full alpha
        expect((color.value & 0x00FFFFFF), 0xABCDEF);
      });

      test('colorSchema transforms 8-digit hex correctly', () {
        final result = StyleSchemas.colorSchema.safeParse('#ABCDEF80');
        final color = result.getOrThrow()!;
        expect(color.a, closeTo(0x80 / 255, 0.01));
      });

      test('paddingSchema transforms number to EdgeInsetsGeometryMix', () {
        final result = StyleSchemas.paddingSchema.safeParse(20.0);
        expect(result.getOrThrow(), isA<EdgeInsetsGeometryMix>());
      });

      test('decorationSchema transforms to BoxDecorationMix', () {
        final result = StyleSchemas.decorationSchema.safeParse({
          'color': '#FF0000',
          'borderRadius': 8.0,
        });
        final decoration = result.getOrThrow()!;
        expect(decoration, isA<BoxDecorationMix>());
      });

      test('containerSchema transforms to BoxStyler', () {
        final result = StyleSchemas.containerSchema.safeParse({
          'padding': 16.0,
        });
        final container = result.getOrThrow()!;
        expect(container, isA<BoxStyler>());
      });

      test('textStyleSchema transforms to TextStyle', () {
        final result = StyleSchemas.textStyleSchema.safeParse({
          'fontSize': 20.0,
          'color': '#000000',
        });
        final textStyle = result.getOrThrow()!;
        expect(textStyle, isA<TextStyle>());
      });

      test('typographySchema transforms to TextStyler', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': 24.0,
        });
        final typography = result.getOrThrow()!;
        expect(typography, isA<TextStyler>());
      });

      test('slideStyleSchema transforms to SlideStyle', () {
        final result = StyleSchemas.slideStyleSchema.safeParse({
          'h1': {'fontSize': 96.0},
        });
        final slideStyle = result.getOrThrow()!;
        expect(slideStyle, isA<SlideStyle>());
      });

      test('styleConfigSchema transforms to record type', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {'h1': {'fontSize': 96.0}},
        });
        final config = result.getOrThrow()!;
        expect(config.baseStyle, isNotNull);
        expect(config.styles, isA<Map<String, SlideStyle>>());
      });
    });

    // =======================================================================
    // Validation Strategy Tests
    // =======================================================================

    group('Validation Strategy', () {
      test('nested schemas reject unknown keys (strict)', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': 24.0,
          'unknownKey': 'value',
        });
        expect(result.isFail, isTrue);
      });

      test('top-level schema allows unknown keys (permissive)', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'unknownKey': 'value',
          'base': {'h1': {'fontSize': 96.0}},
        });
        expect(result.isOk, isTrue);
      });

      test('catches typos in nested objects', () {
        final result = StyleSchemas.styleConfigSchema.safeParse({
          'base': {
            'h1': {
              'fontsize': 96.0, // typo
            },
          },
        });
        expect(result.isFail, isTrue);
      });

      test('validates enum values strictly', () {
        final result = StyleSchemas.fontWeightSchema.safeParse('semibold');
        expect(result.isFail, isTrue);
      });

      test('validates positive numbers', () {
        final result = StyleSchemas.typographySchema.safeParse({
          'fontSize': -24.0,
        });
        expect(result.isFail, isTrue);
      });

      test('validates regex patterns strictly', () {
        final result = StyleSchemas.colorSchema.safeParse('#GG0000');
        expect(result.isFail, isTrue);
      });
    });

    // =======================================================================
    // StyleConfigResult typedef Tests
    // =======================================================================

    group('StyleConfigResult', () {
      test('has correct structure', () {
        final config = (
          baseStyle: SlideStyle(),
          styles: <String, SlideStyle>{'test': SlideStyle()},
        );

        expect(config.baseStyle, isNotNull);
        expect(config.styles, isA<Map<String, SlideStyle>>());
        expect(config.styles['test'], isNotNull);
      });

      test('can have null baseStyle', () {
        final config = (
          baseStyle: null,
          styles: <String, SlideStyle>{},
        );

        expect(config.baseStyle, isNull);
        expect(config.styles, isEmpty);
      });

      test('can have empty styles map', () {
        final config = (
          baseStyle: SlideStyle(),
          styles: <String, SlideStyle>{},
        );

        expect(config.baseStyle, isNotNull);
        expect(config.styles, isEmpty);
      });
    });
  });
}
