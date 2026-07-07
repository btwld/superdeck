import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/slide_key_utils.dart';

void main() {
  Map<String, dynamic> slideWithTitle(String title) => {
        'options': {'title': title},
      };

  Map<String, dynamic> slideWithContent(String content) => {
        'sections': [
          {
            'blocks': [
              {'content': content},
            ],
          },
        ],
      };

  group('generateSlideKey', () {
    test('is deterministic for the same index and content', () {
      final a = generateSlideKey(slideWithTitle('Intro'), 0);
      final b = generateSlideKey(slideWithTitle('Intro'), 0);
      expect(a, b);
    });

    test('differs when the index differs', () {
      expect(
        generateSlideKey(slideWithTitle('Intro'), 0),
        isNot(generateSlideKey(slideWithTitle('Intro'), 1)),
      );
    });

    test('differs when the title differs', () {
      expect(
        generateSlideKey(slideWithTitle('Intro'), 0),
        isNot(generateSlideKey(slideWithTitle('Outro'), 0)),
      );
    });

    test('falls back to first block content when there is no title', () {
      final fromContent = generateSlideKey(slideWithContent('Hello world'), 0);
      final placeholder = generateSlideKey({'sections': const []}, 0);
      expect(fromContent, isNot(placeholder));
    });

    test('produces a safe key', () {
      expect(isSafeSlideKey(generateSlideKey(slideWithTitle('Intro'), 0)),
          isTrue);
    });
  });

  group('isSafeSlideKey', () {
    test('accepts alphanumeric keys with dashes and underscores', () {
      expect(isSafeSlideKey('slide-1_intro'), isTrue);
      expect(isSafeSlideKey('A'), isTrue);
    });

    test('rejects keys starting with a separator', () {
      expect(isSafeSlideKey('-slide'), isFalse);
      expect(isSafeSlideKey('_slide'), isFalse);
    });

    test('rejects keys with unsafe characters', () {
      expect(isSafeSlideKey('slide 1'), isFalse);
      expect(isSafeSlideKey('slide/1'), isFalse);
      expect(isSafeSlideKey('slide.1'), isFalse);
    });

    test('rejects empty keys', () {
      expect(isSafeSlideKey(''), isFalse);
    });

    test('rejects keys longer than 80 characters', () {
      expect(isSafeSlideKey('a' * 80), isTrue);
      expect(isSafeSlideKey('a' * 81), isFalse);
    });
  });

  group('normalizeSlideKey', () {
    test('keeps an already-safe provided key', () {
      final key = normalizeSlideKey({'key': 'my-slide_1'}, 0);
      expect(key, 'my-slide_1');
    });

    test('sanitizes unsafe characters into dashes', () {
      final key = normalizeSlideKey({'key': 'My Slide! 1'}, 0);
      expect(key, 'My-Slide-1');
    });

    test('collapses repeated separators and trims edges', () {
      final key = normalizeSlideKey({'key': '--a///b--'}, 0);
      expect(key, 'a-b');
    });

    test('falls back to a content hash when the key normalizes to empty', () {
      final slide = {'key': '???', ...slideWithTitle('Intro')};
      final key = normalizeSlideKey(slide, 0);
      expect(key, generateSlideKey(slide, 0));
      expect(isSafeSlideKey(key), isTrue);
    });

    test('falls back when no key is provided', () {
      final slide = slideWithTitle('Intro');
      expect(normalizeSlideKey(slide, 2), generateSlideKey(slide, 2));
    });
  });

  group('generateUniqueSlideKey', () {
    test('returns the base key when unused', () {
      final slide = slideWithTitle('Intro');
      final key = generateUniqueSlideKey(slide, 0, <String>{});
      expect(key, generateSlideKey(slide, 0));
    });

    test('avoids collisions with used keys', () {
      final slide = slideWithTitle('Intro');
      final base = generateSlideKey(slide, 0);
      final key = generateUniqueSlideKey(slide, 0, {base});
      expect(key, isNot(base));
    });

    test('uses the guaranteed-distinct fallback when attempts are exhausted',
        () {
      final slide = slideWithTitle('Intro');
      final base = generateSlideKey(slide, 0);
      final key = generateUniqueSlideKey(slide, 0, {base}, maxAttempts: 1);
      expect(key, '$base-0');
    });
  });
}
