import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

class _TestWidgetDefinition extends WidgetDefinition<Map<String, Object?>> {
  const _TestWidgetDefinition();

  @override
  Map<String, Object?> parse(Map<String, Object?> args) => args;

  @override
  Widget build(BuildContext context, Map<String, Object?> args) {
    return const SizedBox.shrink();
  }
}

void main() {
  group('SlideConfiguration', () {
    group('equality', () {
      test('equivalent widget map wrappers are equal', () {
        final slide = Slide(
          key: 'intro',
          sections: [
            SectionBlock([ContentBlock('Hello')]),
          ],
        );
        final widgetDefinition = const _TestWidgetDefinition();

        final first = SlideConfiguration(
          slideIndex: 0,
          style: SlideStyle(),
          slide: slide,
          parts: const SlideParts(),
          thumbnailFile: 'thumbnail_intro.png',
          widgets: {'custom': widgetDefinition},
        );

        final second = SlideConfiguration(
          slideIndex: 0,
          style: SlideStyle(),
          slide: slide,
          parts: const SlideParts(),
          thumbnailFile: 'thumbnail_intro.png',
          widgets: {'custom': widgetDefinition},
        );

        expect(first, equals(second));
        expect(first.hashCode, equals(second.hashCode));
      });
    });
  });
}
