import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_ai/core/ai/services/slide_key_utils.dart';

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
  });
}
