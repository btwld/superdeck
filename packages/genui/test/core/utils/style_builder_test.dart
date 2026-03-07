import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_genui/src/ai/prompts/font_styles.dart';
import 'package:superdeck_genui/src/ai/schemas/deck_schemas.dart';
import 'package:superdeck_genui/src/utils/style_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Disable Google Fonts network fetching for tests
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Builds a DeckStyleType for testing.
  ///
  /// Uses DeckStyleType constructor directly (bypasses parse).
  DeckStyleType buildStyle({
    required String heading,
    String body = '#00FF00',
    String background = '#FFFFFF',
    Map<String, Object?>? fonts,
    String name = 'Test Style',
  }) {
    return DeckStyleType({
      'name': name,
      'colors': {'background': background, 'heading': heading, 'body': body},
      'fonts':
          fonts ??
          {'headline': HeadlineFont.montserrat, 'body': BodyFont.openSans},
    });
  }

  TextStyle? propTextStyle(Prop<TextStyle>? prop) {
    if (prop == null || prop.sources.isEmpty) return null;
    final source = prop.sources.last;
    return source is ValueSource<TextStyle> ? source.value : null;
  }

  Color? headingColorFrom(DeckTheme presentation) =>
      propTextStyle(presentation.baseStyle?.$strong)?.color;

  Color? bodyColorFrom(DeckTheme presentation) =>
      propTextStyle(presentation.baseStyle?.$a)?.color;

  group('buildDeckThemeFromStyle', () {
    group('null and empty inputs', () {
      test('returns empty DeckTheme for null style', () {
        final result = buildDeckThemeFromStyle(null);

        expect(result.baseStyle, isNull);
      });

      test('returns empty DeckTheme when style fails schema parsing', () {
        final style = DeckStyleType.safeParse({
          'name': 'Invalid Style',
          'colors': {'heading': '#FF0000'},
        }).getOrNull();
        final result = buildDeckThemeFromStyle(style);

        expect(style, isNull);
        expect(result.baseStyle, isNull);
      });
    });

    group('valid color configurations', () {
      test(
        'returns DeckTheme with baseStyle when heading color provided',
        () {
          final result = buildDeckThemeFromStyle(
            buildStyle(heading: '#FF0000'),
          );

          expect(headingColorFrom(result), equals(const Color(0xFFFF0000)));
          expect(bodyColorFrom(result), equals(const Color(0xFF00FF00)));
        },
      );

      test('returns DeckTheme with baseStyle for heading and body', () {
        final result = buildDeckThemeFromStyle(
          buildStyle(heading: '#FF0000', body: '#00FF00'),
        );

        expect(headingColorFrom(result), equals(const Color(0xFFFF0000)));
        expect(bodyColorFrom(result), equals(const Color(0xFF00FF00)));
      });

      test('returns DeckTheme with baseStyle for all colors', () {
        final result = buildDeckThemeFromStyle(
          buildStyle(
            heading: '#FF0000',
            body: '#00FF00',
            background: '#FFFFFF',
          ),
        );

        expect(headingColorFrom(result), equals(const Color(0xFFFF0000)));
        expect(bodyColorFrom(result), equals(const Color(0xFF00FF00)));
      });

      test('handles invalid hex color gracefully (uses fallback)', () {
        // Invalid hex should still produce a result with fallback gray
        final result = buildDeckThemeFromStyle(
          buildStyle(heading: 'invalid'),
        );

        expect(headingColorFrom(result), equals(const Color(0xFF808080)));
        expect(bodyColorFrom(result), equals(const Color(0xFF00FF00)));
      });

      test('handles hex color without # prefix', () {
        final result = buildDeckThemeFromStyle(
          buildStyle(heading: 'FF0000'),
        );

        expect(headingColorFrom(result), equals(const Color(0xFFFF0000)));
      });

      test('handles hex color with # prefix', () {
        final result = buildDeckThemeFromStyle(
          buildStyle(heading: '#FF0000'),
        );

        expect(headingColorFrom(result), equals(const Color(0xFFFF0000)));
      });

      test('handles lowercase hex colors', () {
        final result = buildDeckThemeFromStyle(
          buildStyle(heading: '#ff5733'),
        );

        expect(headingColorFrom(result), equals(const Color(0xFFFF5733)));
      });
    });

    group('font configurations', () {
      test('handles null fonts gracefully', () {
        final result = buildDeckThemeFromStyle(
          buildStyle(heading: '#FF0000'),
        );

        expect(headingColorFrom(result), equals(const Color(0xFFFF0000)));
        expect(bodyColorFrom(result), equals(const Color(0xFF00FF00)));
      });

      test('rejects unknown font IDs at schema level', () {
        // Font names are validated against HeadlineFont/BodyFont enums,
        // so unknown IDs fail schema parsing before reaching style builder.
        final style = DeckStyleType.safeParse({
          'name': 'Test Style',
          'colors': {
            'background': '#FFFFFF',
            'heading': '#FF0000',
            'body': '#00FF00',
          },
          'fonts': {
            'headline': 'CompletelyUnknownFont',
            'body': 'AnotherUnknownFont',
          },
        }).getOrNull();

        expect(style, isNull);
      });
    });

    group('complete style configurations (colors only)', () {
      test('handles complete valid style configuration without fonts', () {
        final result = buildDeckThemeFromStyle(
          buildStyle(
            heading: '#FF5733',
            body: '#33FF57',
            background: '#FFFFFF',
          ),
        );

        expect(headingColorFrom(result), equals(const Color(0xFFFF5733)));
        expect(bodyColorFrom(result), equals(const Color(0xFF33FF57)));
      });

      test('handles realistic AI-generated style without fonts', () {
        final result = buildDeckThemeFromStyle(
          buildStyle(
            heading: '#2C3E50',
            body: '#34495E',
            background: '#ECF0F1',
          ),
        );

        expect(headingColorFrom(result), equals(const Color(0xFF2C3E50)));
        expect(bodyColorFrom(result), equals(const Color(0xFF34495E)));
      });
    });

    group('edge cases', () {
      test('returns empty DeckTheme when colors have unknown keys', () {
        final style = DeckStyleType.safeParse({
          'name': 'Invalid Style',
          'colors': {
            'background': '#FFFFFF',
            'heading': '#FF0000',
            'body': '#000000',
            'accent': '#FFFF00',
            'highlight': '#00FFFF',
          },
        }).getOrNull();
        final result = buildDeckThemeFromStyle(style);

        expect(style, isNull);
        expect(result.baseStyle, isNull);
      });

      test(
        'returns empty DeckTheme when style has unknown top-level keys',
        () {
          final style = DeckStyleType.safeParse({
            'name': 'Invalid Style',
            'colors': {
              'background': '#FFFFFF',
              'heading': '#FF0000',
              'body': '#000000',
            },
            'theme': 'dark',
            'animations': true,
          }).getOrNull();
          final result = buildDeckThemeFromStyle(style);

          expect(style, isNull);
          expect(result.baseStyle, isNull);
        },
      );
    });
  });
}
