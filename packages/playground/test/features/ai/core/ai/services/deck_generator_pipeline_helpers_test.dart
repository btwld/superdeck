import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/services/deck_generator_service.dart';

void main() {
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
