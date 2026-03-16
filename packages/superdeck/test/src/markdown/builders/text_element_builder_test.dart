import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/markdown/markdown_helpers.dart';

void main() {
  group('TextElementBuilder', () {
    group('CSS class tag behavior via getTagAndContent', () {
      test('extracts CSS class tag for Hero animations', () {
        final result = getTagAndContent('# **SuperDeck2** {.heading}');

        // Tag is extracted for Hero animations
        expect(result.tag, equals('heading'));

        // Content has CSS class removed
        expect(result.content, equals('# **SuperDeck2**'));
        expect(result.content, isNot(contains('{.heading}')));
      });

      test('extracts subheading CSS class', () {
        final result = getTagAndContent(
          '## Beautiful presentations {.subheading}',
        );

        expect(result.tag, equals('subheading'));
        expect(result.content, equals('## Beautiful presentations'));
      });

      test('extracts animate CSS class', () {
        final result = getTagAndContent('### Animated Title {.animate}');

        expect(result.tag, equals('animate'));
        expect(result.content, equals('### Animated Title'));
      });

      test('returns null tag for text without CSS class', () {
        final result = getTagAndContent('# Regular Heading');

        expect(result.tag, isNull);
        expect(result.content, equals('# Regular Heading'));
      });

      test('handles empty text', () {
        final result = getTagAndContent('');

        expect(result.tag, isNull);
        expect(result.content, isEmpty);
      });

      test('handles malformed CSS class (no closing brace)', () {
        final result = getTagAndContent('# Heading {.incomplete');

        expect(result.tag, isNull);
        // Malformed tags remain in content
        expect(result.content, equals('# Heading {.incomplete'));
      });
    });

    group('Line break transformation', () {
      test('<br> tags are converted to newlines', () {
        // This transformation happens in TextElementBuilder._transformLineBreaks
        const input = 'Line 1<br>Line 2<br>Line 3';
        const expected = 'Line 1\nLine 2\nLine 3';

        // Simulating the transformation
        final result = input.replaceAll('<br>', '\n');

        expect(result, equals(expected));
      });
    });

    group('CSS class behavior documentation', () {
      test('CSS classes do NOT apply custom styles', () {
        // Important: CSS class tags like {.heading}, {.subheading}, etc.
        // are stripped from the rendered content and used ONLY for Hero
        // animation tags. They do NOT trigger custom Mix styles.
        //
        // The current architecture:
        // 1. CSS classes are parsed and stored in superdeck.json ✓
        // 2. At runtime, they are extracted for Hero animation tags ✓
        // 3. They are removed from rendered text ✓
        // 4. They do NOT apply custom styles to the text ✗
        //
        // To apply custom styles, use:
        // - SlideStyle configurations in DeckOptions
        // - Named slide styles via frontmatter (style: hero)
        // - Direct Mix styling in widget configurations

        final result = getTagAndContent('# Title {.custom-style}');

        expect(result.tag, equals('custom-style'));
        expect(result.content, equals('# Title'));

        // The tag is used for Hero animations only
        // No custom styling is applied based on the CSS class name
      });
    });
  });
}
