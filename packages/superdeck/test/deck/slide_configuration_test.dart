import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/styling/styling.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('SlideConfiguration.copyWith thumbnailFile', () {
    late SlideConfiguration configuration;

    setUp(() {
      configuration = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyle(),
        slide: Slide(
          key: 'slide-key',
          sections: [
            SectionBlock([ContentBlock('content')]),
          ],
        ),
        thumbnailFile: 'thumbnail.png',
      );
    });

    test('keeps current thumbnail when not explicitly setting', () {
      final updated = configuration.copyWith();

      expect(updated.thumbnailFile, 'thumbnail.png');
    });

    test('updates thumbnail when setThumbnailFile is true', () {
      final updated = configuration.copyWith(
        thumbnailFile: 'updated-thumbnail.png',
        setThumbnailFile: true,
      );

      expect(updated.thumbnailFile, 'updated-thumbnail.png');
    });

    test('can clear thumbnail when setThumbnailFile is true', () {
      final updated = configuration.copyWith(setThumbnailFile: true);

      expect(updated.thumbnailFile, isNull);
    });
  });
}
