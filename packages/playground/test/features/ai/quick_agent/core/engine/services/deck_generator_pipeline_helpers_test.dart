import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:superdeck_core/superdeck_core.dart' show Slide;

void main() {
  group('sanitizeGeneratedSlides', () {
    test('preserves spacing, padding, and margin for the canonical parser',
        () {
      final sanitized = sanitizeGeneratedSlides([
        {
          'key': 'slide-layout',
          'sections': [
            {
              'type': 'section',
              'spacing': 24,
              'blocks': [
                {
                  'type': 'block',
                  'content': '# Hello',
                  'padding': {'top': 12, 'right': 24, 'bottom': 12, 'left': 24},
                  'margin': {'top': 8, 'right': 8, 'bottom': 8, 'left': 8},
                },
              ],
            },
          ],
        },
      ]);

      expect(sanitized, hasLength(1));
      final parsed = Slide.parse(Map<String, Object?>.from(sanitized.single));
      final section = parsed.sections.single;
      expect(section.spacing, 24);
      expect(section.blocks.single.padding?.left, 24);
      expect(section.blocks.single.margin?.top, 8);
    });

    test('drops empty blocks and sections but keeps usable ones', () {
      final sanitized = sanitizeGeneratedSlides([
        {
          'key': 'slide-partial',
          'sections': [
            {
              'blocks': [
                {'type': 'block', 'content': ''},
              ],
            },
            {
              'blocks': [
                {'type': 'block', 'content': 'Kept'},
              ],
            },
          ],
        },
      ]);

      expect(sanitized, hasLength(1));
      expect(sanitized.single['sections'], hasLength(1));
    });
  });

  group('minimumUsableSlideCount', () {
    test('passes through counts of 0 and 1 unchanged', () {
      expect(minimumUsableSlideCount(0), 0);
      expect(minimumUsableSlideCount(1), 1);
    });

    test('requires ~75% (rounded up) of the expected count', () {
      expect(minimumUsableSlideCount(4), 3); // ceil(3.0)
      expect(minimumUsableSlideCount(8), 6); // ceil(6.0)
      expect(minimumUsableSlideCount(10), 8); // ceil(7.5)
    });

    test('never drops below 2 for multi-slide decks', () {
      expect(minimumUsableSlideCount(2), 2);
      expect(minimumUsableSlideCount(3), 3);
    });
  });

  group('validateGeneratedSlideCount', () {
    test('returns null when the minimum is met', () {
      expect(
        validateGeneratedSlideCount(
          expectedSlideCount: 10,
          actualSlideCount: 8,
        ),
        isNull,
      );
    });

    test('returns null when the minimum requirement is non-positive', () {
      expect(
        validateGeneratedSlideCount(
          expectedSlideCount: 0,
          actualSlideCount: 0,
        ),
        isNull,
      );
    });

    test('returns an error message when too few slides were produced', () {
      final message = validateGeneratedSlideCount(
        expectedSlideCount: 10,
        actualSlideCount: 3,
      );
      expect(message, isNotNull);
      expect(message, contains('3'));
      expect(message, contains('8'));
      expect(message, contains('10'));
      expect(message, contains('slides'));
    });

    test('uses the singular noun for exactly one slide', () {
      final message = validateGeneratedSlideCount(
        expectedSlideCount: 10,
        actualSlideCount: 1,
      );
      expect(message, contains('1 usable slide;'));
    });
  });
}
