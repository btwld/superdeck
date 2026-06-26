import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/services/deck_generator_service.dart';

void main() {
  group('minimumUsableSlideCount', () {
    test('allows unknown or single-slide decks as-is', () {
      expect(minimumUsableSlideCount(0), 0);
      expect(minimumUsableSlideCount(1), 1);
    });

    test('requires at least 75 percent for multi-slide decks', () {
      expect(minimumUsableSlideCount(2), 2);
      expect(minimumUsableSlideCount(3), 3);
      expect(minimumUsableSlideCount(4), 3);
      expect(minimumUsableSlideCount(10), 8);
    });
  });

  group('validateGeneratedSlideCount', () {
    test('allows unknown expected count', () {
      expect(
        validateGeneratedSlideCount(expectedSlideCount: 0, actualSlideCount: 1),
        isNull,
      );
    });

    test('allows sufficiently complete usable slides', () {
      expect(
        validateGeneratedSlideCount(expectedSlideCount: 4, actualSlideCount: 3),
        isNull,
      );
      expect(
        validateGeneratedSlideCount(expectedSlideCount: 4, actualSlideCount: 5),
        isNull,
      );
    });

    test('fails when sanitization drops too many requested slides', () {
      expect(
        validateGeneratedSlideCount(expectedSlideCount: 4, actualSlideCount: 1),
        'Generated only 1 usable slide; expected at least 3 of 4 requested '
        'slides. Please try again.',
      );
    });
  });

  group('referencedGeneratedAssetFilenames', () {
    test('finds generated assets referenced in slide content', () {
      final filenames = referencedGeneratedAssetFilenames([
        {
          'key': 'intro',
          'sections': [
            {
              'blocks': [
                {
                  'type': 'block',
                  'content':
                      '![chart](.superdeck/assets/slide-old-illustration.png)',
                },
                {
                  'type': 'block',
                  'content': '![bg](assets/slide-intro-bg.png)',
                },
              ],
            },
          ],
        },
      ]);

      expect(
        filenames,
        containsAll({'slide-old-illustration.png', 'slide-intro-bg.png'}),
      );
    });

    test('ignores non-generated image filenames', () {
      final filenames = referencedGeneratedAssetFilenames([
        {
          'sections': [
            {
              'blocks': [
                {
                  'type': 'block',
                  'content': '![logo](.superdeck/assets/logo.png)',
                },
              ],
            },
          ],
        },
      ]);

      expect(filenames, isEmpty);
    });
  });
}
