import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/services/slide_key_utils.dart';

void main() {
  group('generateSlideKey', () {
    test('uses slide title when present', () {
      final slide = <String, dynamic>{
        'options': <String, dynamic>{'title': 'Hello World'},
        'sections': <dynamic>[],
      };

      final key = generateSlideKey(slide, 0);

      expect(key, 'nRtIcohM');
    });

    test('falls back to first block content when title is missing', () {
      final slide = <String, dynamic>{
        'sections': [
          {
            'blocks': [
              {'content': 'First content'},
            ],
          },
        ],
      };

      final key = generateSlideKey(slide, 3);

      expect(key, 'UJmN1boX');
    });

    test(
      'uses default fallback token when no title or content is available',
      () {
        final slide = <String, dynamic>{
          'sections': [
            {
              'blocks': [
                {'content': ''},
              ],
            },
          ],
        };

        final key = generateSlideKey(slide, 8);

        expect(key, 'qWXuhygc');
      },
    );

    test('ignores malformed section and block shapes', () {
      final slide = <String, dynamic>{
        'sections': [
          'not-a-section',
          {
            'blocks': ['not-a-block'],
          },
          {
            'blocks': [
              {'content': 'First content'},
            ],
          },
        ],
      };

      final key = generateSlideKey(slide, 3);

      expect(key, 'UJmN1boX');
    });
  });

  group('isSafeSlideKey', () {
    test('accepts simple path-safe keys', () {
      expect(isSafeSlideKey('slide-1'), isTrue);
      expect(isSafeSlideKey('Slide_2'), isTrue);
      expect(isSafeSlideKey('a1B2'), isTrue);
    });

    test('rejects path-like, blank, and whitespace keys', () {
      expect(isSafeSlideKey('../slide'), isFalse);
      expect(isSafeSlideKey('slide one'), isFalse);
      expect(isSafeSlideKey(''), isFalse);
    });
  });

  group('normalizeSlideKey', () {
    test('normalizes unsafe AI keys', () {
      final slide = <String, dynamic>{
        'key': '../Launch Plan',
        'options': <String, dynamic>{'title': 'Launch'},
      };

      expect(normalizeSlideKey(slide, 0), 'Launch-Plan');
    });

    test('falls back to generated key when normalization is empty', () {
      final slide = <String, dynamic>{
        'key': '///',
        'options': <String, dynamic>{'title': 'Hello World'},
      };

      expect(normalizeSlideKey(slide, 0), generateSlideKey(slide, 0));
    });
  });
}
