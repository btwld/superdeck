import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/tools/deck_mutation_helpers.dart';
import 'package:playground/features/ai/core/tools/errors.dart';

void main() {
  group('validateReadIndex', () {
    test('throws when index is out of range', () {
      expect(
        () => validateReadIndex(2, 2),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.slideIndexOutOfRange,
          ),
        ),
      );
    });

    test('accepts valid index', () {
      expect(() => validateReadIndex(1, 2), returnsNormally);
    });
  });

  group('validateInsertIndex', () {
    test('throws when insert index is invalid', () {
      expect(
        () => validateInsertIndex(3, 2),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.slideInsertIndexInvalid,
          ),
        ),
      );
    });

    test('accepts insert at end', () {
      expect(() => validateInsertIndex(2, 2), returnsNormally);
    });
  });

  group('list mutations', () {
    test('insertSlideAt inserts in middle', () {
      final slides = [_slide('a'), _slide('c')];

      final updated = insertSlideAt(slides, _slide('b'), 1);

      expect(updated.map((slide) => slide.key), ['a', 'b', 'c']);
    });

    test('replaceSlideAt replaces specific index', () {
      final slides = [_slide('a', title: 'Old')];

      final updated = replaceSlideAt(slides, 0, _slide('a', title: 'New'));

      expect(updated.single.options?.title, 'New');
    });

    test('removeSlideAt removes item and shifts order', () {
      final slides = [_slide('a'), _slide('b'), _slide('c')];

      final updated = removeSlideAt(slides, 1);

      expect(updated.map((slide) => slide.key), ['a', 'c']);
    });

    test('moveSlide handles first to last', () {
      final slides = [_slide('a'), _slide('b'), _slide('c')];

      final updated = moveSlide(slides, 0, 2);

      expect(updated.map((slide) => slide.key), ['b', 'c', 'a']);
    });

    test('moveSlide no-op still returns copied list', () {
      final slides = [_slide('a'), _slide('b')];

      final updated = moveSlide(slides, 1, 1);

      expect(updated.map((slide) => slide.key), ['a', 'b']);
      expect(identical(updated, slides), isFalse);
    });
  });

  group('key checks', () {
    test('ensureUniqueSlideKeyForCreate throws for duplicate key', () {
      final slides = [_slide('a')];

      expect(
        () => ensureUniqueSlideKeyForCreate(slides, 'a'),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.slideKeyConflict,
          ),
        ),
      );
    });

    test('ensureUniqueSlideKeyForUpdate ignores same index', () {
      final slides = [_slide('a')];
      expect(
        () => ensureUniqueSlideKeyForUpdate(slides, 0, 'a'),
        returnsNormally,
      );
    });

    test('ensureUniqueSlideKeyForUpdate throws for another index', () {
      final slides = [_slide('a'), _slide('b')];

      expect(
        () => ensureUniqueSlideKeyForUpdate(slides, 0, 'b'),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.slideKeyConflict,
          ),
        ),
      );
    });
  });

  group('buildDeckSnapshot', () {
    test('builds snapshot with style and title metadata', () {
      final slides = [
        _slide('a', title: 'Intro'),
        _slide('b', title: 'Agenda'),
      ];
      final style = DeckStyleType.parse(_styleMap());

      final snapshot = buildDeckSnapshot(slides, style: style);

      expect(snapshot.totalSlides, 2);
      expect(snapshot.style, isNotNull);
      expect(snapshot.slides[0].index, 0);
      expect(snapshot.slides[0].key, 'a');
      expect(snapshot.slides[0].title, 'Intro');
      expect(snapshot.slides[1].title, 'Agenda');
    });
  });
}

Slide _slide(String key, {String title = 'Title'}) {
  return Slide.parse({
    'key': key,
    'options': {'title': title},
    'sections': [
      {
        'type': 'section',
        'blocks': [
          {'type': 'block', 'content': 'Body'},
        ],
      },
    ],
  });
}

Map<String, Object?> _styleMap() {
  return {
    'name': 'Default',
    'colors': {
      'background': '#FFFFFF',
      'heading': '#112233',
      'body': '#445566',
    },
    'fonts': {'headline': 'montserrat', 'body': 'openSans'},
  };
}
