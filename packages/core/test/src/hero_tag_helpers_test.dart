import 'package:superdeck_core/src/hero_tag_helpers.dart';
import 'package:test/test.dart';

void main() {
  group('Hero Tag Helpers', () {
    group('isValidHeroTag', () {
      test('accepts simple identifiers', () {
        expect(isValidHeroTag('hero'), isTrue);
        expect(isValidHeroTag('myTag'), isTrue);
        expect(isValidHeroTag('tag123'), isTrue);
      });

      test('accepts underscores', () {
        expect(isValidHeroTag('_private'), isTrue);
        expect(isValidHeroTag('my_tag'), isTrue);
        expect(isValidHeroTag('tag_123'), isTrue);
      });

      test('accepts single leading hyphen', () {
        expect(isValidHeroTag('-custom'), isTrue);
        expect(isValidHeroTag('-my-tag'), isTrue);
      });

      test('accepts hyphens in middle', () {
        expect(isValidHeroTag('my-hero'), isTrue);
        expect(isValidHeroTag('my-hero-tag'), isTrue);
        expect(isValidHeroTag('a-b-c'), isTrue);
      });

      test('rejects empty string', () {
        expect(isValidHeroTag(''), isFalse);
      });

      test('rejects CSS custom properties (double hyphen)', () {
        expect(isValidHeroTag('--custom'), isFalse);
        expect(isValidHeroTag('--var-name'), isFalse);
      });

      test('rejects strings starting with digit', () {
        expect(isValidHeroTag('123tag'), isFalse);
        expect(isValidHeroTag('1st'), isFalse);
      });

      test('rejects special characters', () {
        expect(isValidHeroTag('tag@name'), isFalse);
        expect(isValidHeroTag('tag.name'), isFalse);
        expect(isValidHeroTag('tag#name'), isFalse);
        expect(isValidHeroTag('tag name'), isFalse);
      });
    });

    group('firstHeroTagInClassList', () {
      test('extracts first valid tag from single class', () {
        expect(firstHeroTagInClassList('hero'), 'hero');
        expect(firstHeroTagInClassList('.hero'), 'hero');
      });

      test('extracts first valid tag from multiple classes', () {
        expect(firstHeroTagInClassList('hero second'), 'hero');
        expect(firstHeroTagInClassList('.hero .second'), 'hero');
      });

      test('returns null for empty input', () {
        expect(firstHeroTagInClassList(''), isNull);
        expect(firstHeroTagInClassList('   '), isNull);
      });

      test('skips ignored classes (no-select)', () {
        expect(firstHeroTagInClassList('no-select hero'), 'hero');
        expect(firstHeroTagInClassList('.no-select .hero'), 'hero');
      });

      test('returns null if only ignored classes', () {
        expect(firstHeroTagInClassList('no-select'), isNull);
        expect(firstHeroTagInClassList('.no-select'), isNull);
      });

      test('skips invalid tags', () {
        expect(firstHeroTagInClassList('--invalid hero'), 'hero');
        expect(firstHeroTagInClassList('123 hero'), 'hero');
      });

      test('returns null if no valid tags', () {
        expect(firstHeroTagInClassList('--invalid'), isNull);
        expect(firstHeroTagInClassList('123'), isNull);
      });
    });

    group('extractHeroAndContent', () {
      test('extracts hero tag from simple text', () {
        final result = extractHeroAndContent('Hello {.hero}');

        expect(result.tag, 'hero');
        expect(result.content, 'Hello');
      });

      test('extracts hero tag from text with leading marker', () {
        final result = extractHeroAndContent('{.myTag} Some text');

        expect(result.tag, 'myTag');
        expect(result.content, 'Some text');
      });

      test('returns null tag when no marker present', () {
        final result = extractHeroAndContent('Plain text');

        expect(result.tag, isNull);
        expect(result.content, 'Plain text');
      });

      test('handles empty input', () {
        final result = extractHeroAndContent('');

        expect(result.tag, isNull);
        expect(result.content, '');
      });

      test('trims whitespace', () {
        final result = extractHeroAndContent('  Text with spaces  ');

        expect(result.content, 'Text with spaces');
      });

      test('removes backticks', () {
        final result = extractHeroAndContent('```code```');

        expect(result.content, 'code');
      });

      test('removes multiple brace markers', () {
        final result = extractHeroAndContent('{.hero} Text {.other}');

        expect(result.tag, 'hero');
        expect(result.content, 'Text');
      });

      test('rejects invalid tags inside braces', () {
        final result = extractHeroAndContent('Text {.--invalid}');

        expect(result.tag, isNull);
      });

      test('handles underscored tags', () {
        final result = extractHeroAndContent('Content {._private_tag}');

        expect(result.tag, '_private_tag');
      });

      test('handles hyphenated tags', () {
        final result = extractHeroAndContent('Content {.my-hero-tag}');

        expect(result.tag, 'my-hero-tag');
      });
    });

    group('stripTrailingHeroMarker', () {
      test('strips marker from end of line', () {
        final result = stripTrailingHeroMarker('Some text {.hero}');

        expect(result.text, 'Some text');
        expect(result.hero, 'hero');
      });

      test('handles multiple classes, returns first valid', () {
        final result = stripTrailingHeroMarker('Text {.first .second}');

        expect(result.text, 'Text');
        expect(result.hero, 'first');
      });

      test('returns original text when no marker', () {
        final result = stripTrailingHeroMarker('Plain text');

        expect(result.text, 'Plain text');
        expect(result.hero, isNull);
      });

      test('handles empty braces', () {
        final result = stripTrailingHeroMarker('Text {}');

        expect(result.text, 'Text');
        expect(result.hero, isNull);
      });

      test('handles marker with spaces inside', () {
        final result = stripTrailingHeroMarker('Text { .hero }');

        expect(result.text, 'Text');
        expect(result.hero, 'hero');
      });

      test('handles trailing whitespace after marker', () {
        final result = stripTrailingHeroMarker('Text {.hero}  ');

        expect(result.text, 'Text');
        expect(result.hero, 'hero');
      });

      test('trims trailing whitespace from text', () {
        final result = stripTrailingHeroMarker('Text   {.hero}');

        expect(result.text, 'Text');
      });

      test('preserves internal whitespace', () {
        final result = stripTrailingHeroMarker('Text  with  spaces {.hero}');

        expect(result.text, 'Text  with  spaces');
      });

      test('handles underscored tags', () {
        final result = stripTrailingHeroMarker('Content {._tag}');

        expect(result.hero, '_tag');
      });

      test('skips ignored classes', () {
        final result = stripTrailingHeroMarker('Text {.no-select .hero}');

        expect(result.hero, 'hero');
      });
    });

    group('scanLeadingHeroMarker', () {
      test('detects marker at start', () {
        final result = scanLeadingHeroMarker('{.hero} text', 0);

        expect(result.hero, 'hero');
        expect(result.length, greaterThan(0));
      });

      test('detects marker with leading whitespace', () {
        final result = scanLeadingHeroMarker('  {.hero} text', 0);

        expect(result.hero, 'hero');
      });

      test('handles tabs as whitespace', () {
        final result = scanLeadingHeroMarker('\t{.hero} text', 0);

        expect(result.hero, 'hero');
      });

      test('returns null hero when no marker', () {
        final result = scanLeadingHeroMarker('plain text', 0);

        expect(result.hero, isNull);
        expect(result.length, 0);
      });

      test('returns null for unclosed brace', () {
        final result = scanLeadingHeroMarker('{.hero text', 0);

        expect(result.hero, isNull);
        expect(result.length, 0);
      });

      test('returns null for empty braces', () {
        final result = scanLeadingHeroMarker('{} text', 0);

        expect(result.hero, isNull);
        expect(result.length, 0);
      });

      test('respects start position', () {
        final result = scanLeadingHeroMarker('prefix {.hero} text', 7);

        expect(result.hero, 'hero');
      });

      test('consumes trailing whitespace after marker', () {
        final result = scanLeadingHeroMarker('{.hero}   rest', 0);

        expect(result.hero, 'hero');
        // Length should include trailing spaces
        expect(result.length, 10);
      });

      test('handles marker at end of string', () {
        final result = scanLeadingHeroMarker('{.hero}', 0);

        expect(result.hero, 'hero');
        expect(result.length, 7);
      });

      test('returns null when position at end', () {
        final result = scanLeadingHeroMarker('text', 4);

        expect(result.hero, isNull);
        expect(result.length, 0);
      });

      test('rejects invalid tags', () {
        final result = scanLeadingHeroMarker('{.--invalid} text', 0);

        expect(result.hero, isNull);
        expect(result.length, 0);
      });
    });

    group('extractHeroFromFenceInfo', () {
      test('extracts hero from backtick fence', () {
        expect(extractHeroFromFenceInfo('```dart {.hero}'), 'hero');
      });

      test('extracts hero from tilde fence', () {
        expect(extractHeroFromFenceInfo('~~~dart {.hero}'), 'hero');
      });

      test('handles multiple backticks', () {
        expect(extractHeroFromFenceInfo('````dart {.hero}'), 'hero');
      });

      test('handles fence without language', () {
        expect(extractHeroFromFenceInfo('``` {.hero}'), 'hero');
      });

      test('returns null for fence without hero', () {
        expect(extractHeroFromFenceInfo('```dart'), isNull);
        expect(extractHeroFromFenceInfo('```'), isNull);
      });

      test('returns null for invalid fence', () {
        expect(extractHeroFromFenceInfo('dart {.hero}'), isNull);
        expect(extractHeroFromFenceInfo('``dart {.hero}'), isNull);
      });

      test('handles leading spaces (up to 3)', () {
        expect(extractHeroFromFenceInfo('   ```dart {.hero}'), 'hero');
      });

      test('handles trailing whitespace', () {
        expect(extractHeroFromFenceInfo('```dart {.hero}   '), 'hero');
      });

      test('extracts first valid class', () {
        expect(extractHeroFromFenceInfo('```dart {.first .second}'), 'first');
      });

      test('returns null for empty braces', () {
        expect(extractHeroFromFenceInfo('```dart {}'), isNull);
      });

      test('handles underscored tags', () {
        expect(extractHeroFromFenceInfo('```dart {._my_tag}'), '_my_tag');
      });

      test('handles hyphenated tags', () {
        expect(extractHeroFromFenceInfo('```dart {.my-tag}'), 'my-tag');
      });
    });

    group('Pattern matching (RegExp)', () {
      group('heroTrailingPattern', () {
        test('matches marker at end', () {
          expect(heroTrailingPattern.hasMatch('text {.hero}'), isTrue);
        });

        test('matches with trailing whitespace', () {
          expect(heroTrailingPattern.hasMatch('text {.hero}  '), isTrue);
        });

        test('does not match marker in middle', () {
          expect(heroTrailingPattern.hasMatch('{.hero} text'), isFalse);
        });
      });

      group('heroLeadingPattern', () {
        test('matches marker at start', () {
          expect(heroLeadingPattern.hasMatch('{.hero} text'), isTrue);
        });

        test('matches with leading whitespace', () {
          expect(heroLeadingPattern.hasMatch('  {.hero} text'), isTrue);
        });

        test('does not match marker at end', () {
          expect(heroLeadingPattern.hasMatch('text {.hero}'), isFalse);
        });
      });

      group('heroFenceInfoPattern', () {
        test('matches backtick fence', () {
          expect(heroFenceInfoPattern.hasMatch('```dart'), isTrue);
        });

        test('matches tilde fence', () {
          expect(heroFenceInfoPattern.hasMatch('~~~dart'), isTrue);
        });

        test('captures info string', () {
          final match = heroFenceInfoPattern.firstMatch('```dart {.hero}');
          expect(match?.group(2)?.trim(), 'dart {.hero}');
        });
      });

      group('heroBracesPattern', () {
        test('matches braces with content', () {
          expect(heroBracesPattern.hasMatch('{.hero}'), isTrue);
        });

        test('captures content inside braces', () {
          final match = heroBracesPattern.firstMatch('text {.hero} more');
          expect(match?.group(1), '.hero');
        });
      });

      group('heroAnywherePattern', () {
        test('matches valid hero tag', () {
          expect(heroAnywherePattern.hasMatch('{.hero}'), isTrue);
          expect(heroAnywherePattern.hasMatch('{._tag}'), isTrue);
          expect(heroAnywherePattern.hasMatch('{.my-tag}'), isTrue);
        });

        test('does not match invalid tags', () {
          expect(heroAnywherePattern.hasMatch('{.123}'), isFalse);
          expect(heroAnywherePattern.hasMatch('{.-tag}'), isFalse);
        });
      });

      group('heroValidIdentifierPattern', () {
        test('matches valid identifiers', () {
          expect(heroValidIdentifierPattern.hasMatch('hero'), isTrue);
          expect(heroValidIdentifierPattern.hasMatch('_tag'), isTrue);
          expect(heroValidIdentifierPattern.hasMatch('-tag'), isTrue);
          expect(heroValidIdentifierPattern.hasMatch('my-tag'), isTrue);
          expect(heroValidIdentifierPattern.hasMatch('tag123'), isTrue);
        });

        test('does not match invalid identifiers', () {
          expect(heroValidIdentifierPattern.hasMatch('--var'), isFalse);
          expect(heroValidIdentifierPattern.hasMatch('123tag'), isFalse);
          expect(heroValidIdentifierPattern.hasMatch(''), isFalse);
        });
      });
    });
  });
}
