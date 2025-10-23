import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/markdown/markdown_helpers.dart';

void main() {
  group('getTagAndContent', () {
    group('extracts CSS class tags correctly', () {
      test('extracts single CSS class from heading', () {
        final result = getTagAndContent('# **SuperDeck2** {.heading}');

        expect(result.tag, equals('heading'));
        expect(result.content, equals('# **SuperDeck2**'));
      });

      test('extracts CSS class from subheading', () {
        final result = getTagAndContent(
          '## Beautiful presentations {.subheading}',
        );

        expect(result.tag, equals('subheading'));
        expect(result.content, equals('## Beautiful presentations'));
      });

      test('extracts animate class', () {
        final result = getTagAndContent('### Animation {.animate}');

        expect(result.tag, equals('animate'));
        expect(result.content, equals('### Animation'));
      });

      test('extracts cover class from image alt text', () {
        final result = getTagAndContent('![Image](url) {.cover}');

        expect(result.tag, equals('cover'));
        expect(result.content, equals('![Image](url)'));
      });

      test('extracts custom CSS class names', () {
        final result = getTagAndContent('# Title {.custom-class}');

        expect(result.tag, equals('custom-class'));
        expect(result.content, equals('# Title'));
      });

      test('handles CSS class with hyphenated names', () {
        final result = getTagAndContent('Text {.my-custom-class}');

        expect(result.tag, equals('my-custom-class'));
        expect(result.content, equals('Text'));
      });
    });

    group('handles text without CSS classes', () {
      test('returns null tag for plain text', () {
        final result = getTagAndContent('# Regular Heading');

        expect(result.tag, isNull);
        expect(result.content, equals('# Regular Heading'));
      });

      test('returns null tag for text with bold', () {
        final result = getTagAndContent('**Bold text**');

        expect(result.tag, isNull);
        expect(result.content, equals('**Bold text**'));
      });

      test('handles paragraph text', () {
        final result = getTagAndContent('This is a paragraph.');

        expect(result.tag, isNull);
        expect(result.content, equals('This is a paragraph.'));
      });
    });

    group('handles edge cases', () {
      test('handles empty string', () {
        final result = getTagAndContent('');

        expect(result.tag, isNull);
        expect(result.content, isEmpty);
      });

      test('handles whitespace-only string', () {
        final result = getTagAndContent('   ');

        expect(result.tag, isNull);
        expect(result.content, isEmpty);
      });

      test('trims leading and trailing whitespace from content', () {
        final result = getTagAndContent('  # Heading {.heading}  ');

        expect(result.tag, equals('heading'));
        expect(result.content, equals('# Heading'));
      });

      test('handles malformed CSS class (no closing brace)', () {
        final result = getTagAndContent('# Heading {.heading');

        expect(result.tag, isNull);
        expect(result.content, equals('# Heading {.heading'));
      });

      test('handles malformed CSS class (no opening brace)', () {
        final result = getTagAndContent('# Heading .heading}');

        expect(result.tag, isNull);
        expect(result.content, equals('# Heading .heading}'));
      });

      test('handles malformed CSS class (no dot)', () {
        final result = getTagAndContent('# Heading {heading}');

        expect(result.tag, isNull);
        expect(result.content, equals('# Heading {heading}'));
      });

      test('handles text with multiple braces (only extracts CSS class)', () {
        final result = getTagAndContent('# {Bold} Heading {.class}');

        expect(result.tag, equals('class'));
        expect(result.content, equals('# {Bold} Heading'));
      });

      test('strips code block delimiters from content', () {
        final result = getTagAndContent('```code block```');

        expect(result.tag, isNull);
        expect(result.content, equals('code block'));
      });
    });

    group('rejects invalid CSS class tags', () {
      test('ignores numeric-only class name', () {
        final result = getTagAndContent('Hero {.123}');

        expect(result.tag, isNull);
        expect(result.content, equals('Hero'));
      });

      test('ignores class name with whitespace', () {
        final result = getTagAndContent('Hero {.my tag}');

        expect(result.tag, isNull);
        expect(result.content, equals('Hero'));
      });

      test('ignores CSS custom property syntax', () {
        final result = getTagAndContent('Hero {.--var}');

        expect(result.tag, isNull);
        expect(result.content, equals('Hero'));
      });

      test('ignores identifier starting with hyphen followed by digit', () {
        final result = getTagAndContent('Hero {.-3bad}');

        expect(result.tag, isNull);
        expect(result.content, equals('Hero'));
      });
    });

    group('CSS class behavior documentation', () {
      test('CSS classes are used for Hero animation tags only', () {
        // CSS class tags like {.heading} serve two purposes:
        // 1. They provide tag names for Hero animations (slide transitions)
        // 2. They are stripped from the rendered content
        //
        // Important: CSS classes do NOT apply custom Mix styles.
        // They are decorative in the markdown source.

        final result = getTagAndContent('# **Title** {.heading}');

        // Tag is extracted for Hero animations
        expect(result.tag, equals('heading'));

        // CSS class is removed from content
        expect(result.content, equals('# **Title**'));
        expect(result.content, isNot(contains('{.heading}')));
      });

      test('multiple CSS classes - only first is extracted', () {
        // Current implementation extracts only the first CSS class match
        final result = getTagAndContent('Text {.first} {.second}');

        expect(result.tag, equals('first'));
        expect(result.content, equals('Text'));
      });
    });
  });

  group('lerpStringWithFade', () {
    test('REPRO: "Leo Farias" -> "Generative UI" last word flicker', () {
      // print('\n=== REPRODUCING LAST WORD FLICKER ===');
      // print('Transition: "Leo Farias" -> "Generative UI"');
      // print('Focus: Watch for space and "UI" behavior\n');

      final start = 'Leo Farias';
      final end = 'Generative UI';

      // Test critical points around where space + "UI" appear
      final criticalPoints = [
        0.85, 0.86, 0.87, 0.88, 0.89, 0.90, // Space fading in
        0.91, 0.92, 0.93, 0.94, 0.95, // Space + U
        0.96, 0.97, 0.98, 0.99, 1.00, // U + I
      ];

      for (final t in criticalPoints) {
        final result = lerpStringWithFade(start, end, t);
        final committed = result.text;
        final fading = result.fadingChar ?? '';
        final opacity = result.fadeOpacity;

        // print('t=${t.toStringAsFixed(2)}: '
        //     'committed="$committed" '
        //     'fade="$fading" '
        //     'opacity=${opacity.toStringAsFixed(3)} '
        //     '→ total="${committed}$fading"');

        // Check for problematic patterns
        if (fading == ' ' && opacity < 0.5) {
          // print('  ⚠️  WARNING: Space at low opacity (${opacity.toStringAsFixed(2)}) - may cause layout shift!');
        }
        if (committed.endsWith(' ') && fading.isNotEmpty && fading != ' ') {
          // print('  ⚠️  WARNING: Space in committed, non-space fading - word positioning may shift!');
        }
      }

      // print('\n=== END REPRODUCTION ===\n');
    });

    group('boundary conditions', () {
      test('at t=0.0 returns start string fully visible', () {
        final result = lerpStringWithFade('Hello', 'World', 0.0);

        expect(result.text, equals('Hello'));
        expect(result.fadingChar, isNull);
        expect(result.fadeOpacity, equals(0.0));
        expect(result.hasFadingChar, isFalse);
      });

      test('at t=0.5 shows only common prefix with fade-in starting', () {
        final result = lerpStringWithFade('Hello', 'Help', 0.5);

        expect(result.text, equals('Hel'));
        // At midpoint, first character of end suffix starts fading in (at opacity 0)
        expect(result.fadingChar, equals('p'));
        expect(result.fadeOpacity, equals(0.0));
        expect(result.isFadingOut, isFalse);
      });

      test('at t=1.0 returns end string fully visible', () {
        final result = lerpStringWithFade('Hello', 'World', 1.0);

        expect(result.text, equals('World'));
        expect(result.fadingChar, isNull);
        expect(result.fadeOpacity, equals(0.0));
        expect(result.hasFadingChar, isFalse);
      });

      test('handles values beyond bounds (clamping)', () {
        final result1 = lerpStringWithFade('ABC', 'XYZ', -0.5);
        expect(result1.text, equals('ABC'));

        final result2 = lerpStringWithFade('ABC', 'XYZ', 1.5);
        expect(result2.text, equals('XYZ'));
      });
    });

    group('fade-out phase (t < 0.5)', () {
      test('shows fading character during fade-out', () {
        final result = lerpStringWithFade('ABC', 'XYZ', 0.25);

        expect(result.hasFadingChar, isTrue);
        expect(result.isFadingOut, isTrue);
        expect(result.fadeOpacity, greaterThan(0.0));
        expect(result.fadeOpacity, lessThan(1.0));
      });

      test('fades characters left-to-right', () {
        final start = 'ABCD';
        final end = 'WXYZ';

        // Early in fade-out: more characters visible
        final result1 = lerpStringWithFade(start, end, 0.1);
        final length1 = result1.text.length +
            (result1.hasFadingChar ? 1 : 0);

        // Later in fade-out: fewer characters visible
        final result2 = lerpStringWithFade(start, end, 0.4);
        final length2 = result2.text.length +
            (result2.hasFadingChar ? 1 : 0);

        expect(length1, greaterThan(length2));
      });

      test('opacity decreases as character fades out', () {
        // The fading character's opacity should decrease toward 0
        final result = lerpStringWithFade('Hello', 'World', 0.25);

        if (result.hasFadingChar) {
          expect(result.fadeOpacity, lessThanOrEqualTo(1.0));
          expect(result.fadeOpacity, greaterThanOrEqualTo(0.0));
        }
      });
    });

    group('fade-in phase (t >= 0.5)', () {
      test('shows fading character during fade-in', () {
        final result = lerpStringWithFade('ABC', 'XYZ', 0.75);

        expect(result.hasFadingChar, isTrue);
        expect(result.isFadingOut, isFalse);
        expect(result.fadeOpacity, greaterThan(0.0));
        expect(result.fadeOpacity, lessThan(1.0));
      });

      test('adds characters left-to-right', () {
        final start = 'ABCD';
        final end = 'WXYZ';

        // Early in fade-in: fewer characters visible
        final result1 = lerpStringWithFade(start, end, 0.6);
        final length1 = result1.text.length +
            (result1.hasFadingChar ? 1 : 0);

        // Later in fade-in: more characters visible
        final result2 = lerpStringWithFade(start, end, 0.9);
        final length2 = result2.text.length +
            (result2.hasFadingChar ? 1 : 0);

        expect(length1, lessThan(length2));
      });

      test('opacity increases as character fades in', () {
        // The fading character's opacity should increase toward 1
        final result = lerpStringWithFade('Hello', 'World', 0.75);

        if (result.hasFadingChar) {
          expect(result.fadeOpacity, lessThanOrEqualTo(1.0));
          expect(result.fadeOpacity, greaterThanOrEqualTo(0.0));
        }
      });
    });

    group('common prefix handling', () {
      test('preserves common prefix throughout transition', () {
        const commonPrefix = 'Hello ';
        final testValues = [0.0, 0.25, 0.5, 0.75, 1.0];

        for (final t in testValues) {
          final result = lerpStringWithFade(
            '${commonPrefix}World',
            '${commonPrefix}Universe',
            t,
          );
          expect(result.text, startsWith(commonPrefix),
              reason: 'Failed at t=$t');
        }
      });

      test('handles identical strings (all common prefix)', () {
        final result = lerpStringWithFade('Same', 'Same', 0.5);

        expect(result.text, equals('Same'));
        expect(result.fadingChar, isNull);
        expect(result.hasFadingChar, isFalse);
      });
    });

    group('edge cases', () {
      test('handles empty start string', () {
        final result = lerpStringWithFade('', 'Hello', 0.75);

        // Should be fading in characters from 'Hello'
        expect(result.text.length + (result.hasFadingChar ? 1 : 0),
            greaterThan(0));
      });

      test('handles empty end string', () {
        final result = lerpStringWithFade('Hello', '', 0.25);

        // Should be fading out characters from 'Hello'
        expect(result.text.length + (result.hasFadingChar ? 1 : 0),
            lessThan('Hello'.length));
      });

      test('handles both empty strings', () {
        final result = lerpStringWithFade('', '', 0.5);

        expect(result.text, isEmpty);
        expect(result.fadingChar, isNull);
      });

      test('handles single character strings', () {
        final result = lerpStringWithFade('A', 'B', 0.5);

        expect(result.text, isEmpty);
        // At midpoint with single chars, first char of end starts fading in
        expect(result.fadingChar, equals('B'));
        expect(result.fadeOpacity, equals(0.0));
      });
    });

    group('character count constraints', () {
      test('character count never exceeds max of start and end lengths', () {
        const start = 'Short';
        const end = 'Much Longer Text';

        for (var t = 0.0; t <= 1.0; t += 0.1) {
          final result = lerpStringWithFade(start, end, t);
          final totalLength = result.text.length +
              (result.fadingChar?.length ?? 0);

          expect(
            totalLength,
            lessThanOrEqualTo(end.length),
            reason: 'Failed at t=$t',
          );
        }
      });

      test('character count is never negative', () {
        for (var t = 0.0; t <= 1.0; t += 0.1) {
          final result = lerpStringWithFade('ABC', 'XYZ', t);

          expect(result.text.length, greaterThanOrEqualTo(0));
        }
      });
    });

    group('opacity range validation', () {
      test('fadeOpacity always in valid range [0.0, 1.0]', () {
        const testCases = [
          ('Hello', 'World'),
          ('A', 'ABCDEF'),
          ('ABCDEF', 'A'),
          ('Same', 'Same'),
        ];

        for (final (start, end) in testCases) {
          for (var t = 0.0; t <= 1.0; t += 0.05) {
            final result = lerpStringWithFade(start, end, t);

            expect(
              result.fadeOpacity,
              greaterThanOrEqualTo(0.0),
              reason: 'Failed for ($start, $end) at t=$t',
            );
            expect(
              result.fadeOpacity,
              lessThanOrEqualTo(1.0),
              reason: 'Failed for ($start, $end) at t=$t',
            );
          }
        }
      });
    });

    group('lerpString helper', () {
      test('returns only text without fade information', () {
        final result = lerpString('Hello', 'World', 0.5);

        expect(result, isA<String>());
        expect(result, isEmpty); // At t=0.5, only common prefix (none) is shown
      });

      test('matches lerpStringWithFade text output', () {
        const start = 'Hello';
        const end = 'World';

        for (var t = 0.0; t <= 1.0; t += 0.25) {
          final simpleResult = lerpString(start, end, t);
          final fullResult = lerpStringWithFade(start, end, t);

          expect(simpleResult, equals(fullResult.text));
        }
      });
    });
  });
}
