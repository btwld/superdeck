import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

class _TestBlockDefinition extends BlockDefinition<Map<String, Object?>> {
  const _TestBlockDefinition();

  @override
  Map<String, Object?> parse(Map<String, Object?> args) => args;

  @override
  Widget build(BuildContext context, Map<String, Object?> args) {
    return const SizedBox.shrink();
  }
}

void main() {
  group('SlideData', () {
    group('equality', () {
      test('equivalent widget map wrappers are equal', () {
        final slide = Slide(
          key: 'intro',
          sections: [
            SectionBlock([ContentBlock('Hello')]),
          ],
        );
        final widgetDefinition = const _TestBlockDefinition();

        final first = SlideData(
          slideIndex: 0,
          style: SlideStyle(),
          slide: slide,
          frame: const SlideFrame(),
          thumbnailFile: 'thumbnail_intro.png',
          widgets: {'custom': widgetDefinition},
        );

        final second = SlideData(
          slideIndex: 0,
          style: SlideStyle(),
          slide: slide,
          frame: const SlideFrame(),
          thumbnailFile: 'thumbnail_intro.png',
          widgets: {'custom': widgetDefinition},
        );

        expect(first, equals(second));
        expect(first.hashCode, equals(second.hashCode));
      });
    });
  });
}
