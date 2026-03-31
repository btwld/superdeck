import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

Widget _sameWidget(Map<String, Object?> args) => const SizedBox.shrink();

void main() {
  group('SlideConfiguration', () {
    test('configs sharing the same widgets map instance are equal', () {
      final widgets = <String, WidgetFactory>{'same': _sameWidget};
      final slide = Slide(key: 'slide-1');
      final a = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyle(),
        slide: slide,
        thumbnailKey: 'thumbnail_slide-1.png',
        widgets: widgets,
      );
      final b = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyle(),
        slide: slide,
        thumbnailKey: 'thumbnail_slide-1.png',
        widgets: widgets,
      );

      expect(a, equals(b));
    });

    test('configs with same-content widget maps are not equal', () {
      final slide = Slide(key: 'slide-1');
      final a = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyle(),
        slide: slide,
        thumbnailKey: 'thumbnail_slide-1.png',
        widgets: {'same': _sameWidget},
      );
      final b = SlideConfiguration(
        slideIndex: 0,
        style: SlideStyle(),
        slide: slide,
        thumbnailKey: 'thumbnail_slide-1.png',
        widgets: {'same': _sameWidget},
      );

      expect(a, isNot(equals(b)));
    });
  });
}
