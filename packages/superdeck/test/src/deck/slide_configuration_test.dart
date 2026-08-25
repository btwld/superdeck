import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

Widget _sameWidget(Map<String, Object?> args) => const SizedBox.shrink();

void main() {
  group('SlideConfiguration', () {
    test('copyWith updates values and retains nullable fields on null', () {
      final parts = SlideParts();
      final original = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyler(),
        slide: Slide(key: 'slide-1'),
        parts: parts,
        thumbnailKey: 'thumbnail_slide-1.png',
      );

      final copy = original.copyWith(slideIndex: 1, parts: null);

      expect(copy.slideIndex, 1);
      expect(copy.parts, same(parts));
      expect(copy.slide, same(original.slide));
    });

    test('configs sharing the same widgets map instance are equal', () {
      final widgets = <String, WidgetFactory>{'same': _sameWidget};
      final slide = Slide(key: 'slide-1');
      final a = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyler(),
        slide: slide,
        thumbnailKey: 'thumbnail_slide-1.png',
        widgets: widgets,
      );
      final b = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyler(),
        slide: slide,
        thumbnailKey: 'thumbnail_slide-1.png',
        widgets: widgets,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('configs with same-content widget maps are not equal', () {
      final slide = Slide(key: 'slide-1');
      final a = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyler(),
        slide: slide,
        thumbnailKey: 'thumbnail_slide-1.png',
        widgets: {'same': _sameWidget},
      );
      final b = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyler(),
        slide: slide,
        thumbnailKey: 'thumbnail_slide-1.png',
        widgets: {'same': _sameWidget},
      );

      expect(a, isNot(equals(b)));
    });
  });
}
