import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/deck_editor/ai/deck_tool_schemas.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('keyless slide boundary', () {
    test('rejects an incoming slide key', () {
      expect(
        () => parseKeylessSlide({
          'key': 'model-supplied',
          'sections': <Object?>[],
        }),
        throwsA(isA<AckException>()),
      );
    });

    test('preserves core options and arbitrary widget args', () {
      final slide = parseKeylessSlide({
        'options': {
          'title': 'Rich slide',
          'layout': 'fullscreen',
          'template': 'cover',
          'customOption': {'nested': true},
        },
        'comments': ['Speaker note'],
        'sections': [
          {
            'type': 'section',
            'flex': 2,
            'blocks': [
              {
                'type': 'widget',
                'name': 'chart',
                'series': [1, 2, 3],
                'palette': {'primary': '#ff0000'},
              },
            ],
          },
        ],
      });

      final encoded = slideToKeylessMap(slide);

      expect(encoded, isNot(contains('key')));
      expect(slide.options?.layout, SlideLayout.fullscreen);
      expect(slide.options?.args['customOption'], {'nested': true});
      final widget = slide.sections.single.blocks.single as WidgetBlock;
      expect(widget.args['series'], [1, 2, 3]);
      expect(widget.args['palette'], {'primary': '#ff0000'});
    });

    test('deck snapshots expose only slide indices and optional titles', () {
      final snapshot = deckSnapshot([
        _slide('one', title: 'One'),
        _slide('two'),
      ]);

      expect(snapshot, {
        'totalSlides': 2,
        'slides': [
          {'index': 0, 'title': 'One'},
          {'index': 1},
        ],
      });
      expect(snapshot.toString(), isNot(contains('one')));
      expect(snapshot.toString(), isNot(contains('two')));
    });
  });
}

Slide _slide(String key, {String? title}) {
  return Slide(
    key: key,
    options: title == null ? null : SlideOptions(title: title),
    sections: [SectionBlock.text('# ${title ?? key}')],
  );
}
