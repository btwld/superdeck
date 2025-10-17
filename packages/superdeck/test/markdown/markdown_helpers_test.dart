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
        final result =
            getTagAndContent('## Beautiful presentations {.subheading}');

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
}
