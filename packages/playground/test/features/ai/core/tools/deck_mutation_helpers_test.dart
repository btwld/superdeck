import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/tools/deck_mutation_helpers.dart';
import 'package:playground/features/ai/core/tools/errors.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('index validation', () {
    test('read index maps negative and too-large values to range error', () {
      expect(() => validateReadIndex(-1, 2), throwsA(_rangeErrorMatcher));
      expect(() => validateReadIndex(2, 2), throwsA(_rangeErrorMatcher));
      expect(() => validateReadIndex(1, 2), returnsNormally);
    });

    test(
      'insert index accepts append and maps invalid values to range error',
      () {
        expect(() => validateInsertIndex(2, 2), returnsNormally);
        expect(() => validateInsertIndex(-1, 2), throwsA(_rangeErrorMatcher));
        expect(() => validateInsertIndex(3, 2), throwsA(_rangeErrorMatcher));
      },
    );
  });

  group('list mutations', () {
    test('insert, replace, remove, and move preserve index semantics', () {
      final inserted = insertSlideAt(
        [_slide('a'), _slide('c')],
        _slide('b'),
        1,
      );
      expect(inserted.map((slide) => slide.key), ['a', 'b', 'c']);

      final replaced = replaceSlideAt(inserted, 1, _slide('b2'));
      expect(replaced.map((slide) => slide.key), ['a', 'b2', 'c']);

      final removed = removeSlideAt(replaced, 0);
      expect(removed.map((slide) => slide.key), ['b2', 'c']);

      final moved = moveSlide(removed, 0, 1);
      expect(moved.map((slide) => slide.key), ['c', 'b2']);
    });
  });

  group('buildDeckSnapshot', () {
    test('emits index/title only with no key or style', () {
      final snapshot = buildDeckSnapshot([
        _slide('a', title: 'Intro'),
        _slide('b', title: 'Agenda'),
      ]);

      expect(snapshot.totalSlides, 2);
      expect(snapshot.slides[0].index, 0);
      expect(snapshot.slides[0].title, 'Intro');
      expect(snapshot.slides[0].containsKey('key'), isFalse);
      expect(snapshot.containsKey('style'), isFalse);
    });
  });
}

Matcher get _rangeErrorMatcher => isA<DeckToolException>().having(
  (error) => error.code,
  'code',
  DeckToolErrorCode.slideIndexOutOfRange,
);

Slide _slide(String key, {String title = 'Title'}) {
  return Slide(
    key: key,
    options: SlideOptions(title: title),
    sections: [
      SectionBlock([ContentBlock('Body')]),
    ],
  );
}
