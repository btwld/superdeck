import 'package:superdeck_core/src/models/block_model.dart';
import 'package:superdeck_core/src/models/slide_model.dart';
import 'package:test/test.dart';

void main() {
  group('Slide Model', () {
    group('Slide', () {
      test('creates with required key only', () {
        const slide = Slide(key: 'test-key');

        expect(slide.key, 'test-key');
        expect(slide.options, isNull);
        expect(slide.sections, isEmpty);
        expect(slide.comments, isEmpty);
      });

      test('creates with all parameters', () {
        final sections = [SectionBlock([ContentBlock('Content')])];
        final comments = ['Speaker note 1', 'Speaker note 2'];
        final options = const SlideOptions(title: 'Title', style: 'custom');

        final slide = Slide(
          key: 'full-key',
          options: options,
          sections: sections,
          comments: comments,
        );

        expect(slide.key, 'full-key');
        expect(slide.options?.title, 'Title');
        expect(slide.sections.length, 1);
        expect(slide.comments.length, 2);
      });

      group('copyWith', () {
        test('copies with new key', () {
          const original = Slide(key: 'original');
          final copy = original.copyWith(key: 'new-key');

          expect(copy.key, 'new-key');
        });

        test('copies with new options', () {
          const original = Slide(key: 'key');
          final copy = original.copyWith(
            options: const SlideOptions(title: 'New Title'),
          );

          expect(copy.options?.title, 'New Title');
        });

        test('copies with new sections', () {
          const original = Slide(key: 'key');
          final newSections = [SectionBlock([ContentBlock('New')])];
          final copy = original.copyWith(sections: newSections);

          expect(copy.sections.length, 1);
        });

        test('copies with new comments', () {
          const original = Slide(key: 'key');
          final copy = original.copyWith(comments: ['Note 1', 'Note 2']);

          expect(copy.comments, ['Note 1', 'Note 2']);
        });

        test('preserves values when not specified', () {
          final original = Slide(
            key: 'key',
            options: const SlideOptions(title: 'Title'),
            sections: [SectionBlock([ContentBlock('Content')])],
            comments: ['Note'],
          );
          final copy = original.copyWith();

          expect(copy.key, original.key);
          expect(copy.options, original.options);
          expect(copy.sections.length, original.sections.length);
          expect(copy.comments, original.comments);
        });
      });

      group('toMap', () {
        test('serializes minimal slide', () {
          const slide = Slide(key: 'minimal');
          final map = slide.toMap();

          expect(map['key'], 'minimal');
          expect(map['sections'], isEmpty);
          expect(map['comments'], isEmpty);
          expect(map.containsKey('options'), isFalse);
        });

        test('serializes slide with options', () {
          final slide = Slide(
            key: 'with-opts',
            options: const SlideOptions(title: 'My Title', style: 'dark'),
          );
          final map = slide.toMap();

          expect(map['options'], isA<Map>());
          expect((map['options'] as Map)['title'], 'My Title');
          expect((map['options'] as Map)['style'], 'dark');
        });

        test('serializes slide with sections', () {
          final slide = Slide(
            key: 'with-sections',
            sections: [
              SectionBlock([ContentBlock('First')]),
              SectionBlock([ContentBlock('Second')]),
            ],
          );
          final map = slide.toMap();

          expect(map['sections'], isA<List>());
          expect((map['sections'] as List).length, 2);
        });

        test('serializes slide with comments', () {
          const slide = Slide(key: 'with-comments', comments: ['Note 1']);
          final map = slide.toMap();

          expect(map['comments'], ['Note 1']);
        });
      });

      group('fromMap', () {
        test('deserializes minimal map', () {
          final map = {'key': 'from-map'};
          final slide = Slide.fromMap(map);

          expect(slide.key, 'from-map');
          expect(slide.options, isNull);
          expect(slide.sections, isEmpty);
          expect(slide.comments, isEmpty);
        });

        test('deserializes map with options', () {
          final map = {
            'key': 'opts-key',
            'options': {'title': 'Parsed Title', 'style': 'light'},
          };
          final slide = Slide.fromMap(map);

          expect(slide.options?.title, 'Parsed Title');
          expect(slide.options?.style, 'light');
        });

        test('deserializes map with sections', () {
          final map = {
            'key': 'sections-key',
            'sections': [
              {
                'type': 'section',
                'blocks': [
                  {'type': 'column', 'content': 'Block content'},
                ],
              },
            ],
          };
          final slide = Slide.fromMap(map);

          expect(slide.sections.length, 1);
          expect(slide.sections[0].blocks.length, 1);
        });

        test('deserializes map with comments', () {
          final map = {
            'key': 'comments-key',
            'comments': ['Comment 1', 'Comment 2'],
          };
          final slide = Slide.fromMap(map);

          expect(slide.comments, ['Comment 1', 'Comment 2']);
        });
      });

      group('round-trip serialization', () {
        test('preserves data through toMap/fromMap', () {
          final original = Slide(
            key: 'roundtrip',
            options: const SlideOptions(title: 'RT Title', style: 'rt-style'),
            sections: [
              SectionBlock([
                ContentBlock('Section content', align: ContentAlignment.center),
              ]),
            ],
            comments: ['RT Comment'],
          );

          final restored = Slide.fromMap(original.toMap());

          expect(restored.key, original.key);
          expect(restored.options?.title, original.options?.title);
          expect(restored.sections.length, original.sections.length);
          expect(restored.comments, original.comments);
        });
      });

      group('parse', () {
        test('parses valid map', () {
          final map = {'key': 'parsed'};
          final slide = Slide.parse(map);

          expect(slide.key, 'parsed');
        });

        test('parses map with all fields', () {
          final map = {
            'key': 'full',
            'options': {'title': 'Title'},
            'sections': [
              {'type': 'section'},
            ],
            'comments': ['Note'],
          };
          final slide = Slide.parse(map);

          expect(slide.key, 'full');
          expect(slide.options?.title, 'Title');
        });
      });

      group('error factory', () {
        test('creates error slide with correct key', () {
          final slide = Slide.error(
            title: 'Error Title',
            message: 'Error message',
            error: Exception('Test error'),
          );

          expect(slide.key, 'error');
        });

        test('includes title and message in content', () {
          final slide = Slide.error(
            title: 'Parse Error',
            message: 'Could not parse slide',
            error: Exception('Details'),
          );

          final content =
              (slide.sections[0].blocks[0] as ContentBlock).content;
          expect(content.contains('Parse Error'), isTrue);
          expect(content.contains('Could not parse slide'), isTrue);
        });

        test('includes error details in code block', () {
          final slide = Slide.error(
            title: 'Error',
            message: 'Message',
            error: Exception('Detailed error info'),
          );

          final content =
              (slide.sections[0].blocks[0] as ContentBlock).content;
          expect(content.contains('Detailed error info'), isTrue);
          expect(content.contains('```dart'), isTrue);
        });

        test('creates section with two content blocks', () {
          final slide = Slide.error(
            title: 'E',
            message: 'M',
            error: Exception('X'),
          );

          expect(slide.sections.length, 1);
          expect(slide.sections[0].blocks.length, 2);
        });
      });

      group('equality', () {
        test('equal slides are equal', () {
          const slide1 = Slide(key: 'same', comments: ['note']);
          const slide2 = Slide(key: 'same', comments: ['note']);

          expect(slide1, slide2);
          expect(slide1.hashCode, slide2.hashCode);
        });

        test('different keys make slides unequal', () {
          const slide1 = Slide(key: 'key1');
          const slide2 = Slide(key: 'key2');

          expect(slide1, isNot(slide2));
        });

        test('different options make slides unequal', () {
          final slide1 = Slide(
            key: 'key',
            options: const SlideOptions(title: 'A'),
          );
          final slide2 = Slide(
            key: 'key',
            options: const SlideOptions(title: 'B'),
          );

          expect(slide1, isNot(slide2));
        });

        test('different sections make slides unequal', () {
          final slide1 = Slide(
            key: 'key',
            sections: [SectionBlock([ContentBlock('A')])],
          );
          final slide2 = Slide(
            key: 'key',
            sections: [SectionBlock([ContentBlock('B')])],
          );

          expect(slide1, isNot(slide2));
        });

        test('different comments make slides unequal', () {
          const slide1 = Slide(key: 'key', comments: ['A']);
          const slide2 = Slide(key: 'key', comments: ['B']);

          expect(slide1, isNot(slide2));
        });
      });

      group('schema', () {
        test('validates minimal slide', () {
          final result = Slide.schema.safeParse({'key': 'valid'});
          expect(result.isOk, isTrue);
        });

        test('validates slide with all fields', () {
          final result = Slide.schema.safeParse({
            'key': 'full',
            'options': {'title': 'T'},
            'sections': [],
            'comments': ['c'],
          });
          expect(result.isOk, isTrue);
        });
      });
    });

    group('SlideOptions', () {
      test('creates with default values', () {
        const options = SlideOptions();

        expect(options.title, isNull);
        expect(options.style, isNull);
        expect(options.args, isEmpty);
      });

      test('creates with all parameters', () {
        const options = SlideOptions(
          title: 'Title',
          style: 'dark',
          args: {'custom': 'value'},
        );

        expect(options.title, 'Title');
        expect(options.style, 'dark');
        expect(options.args['custom'], 'value');
      });

      group('copyWith', () {
        test('copies with new title', () {
          const original = SlideOptions(title: 'Original');
          final copy = original.copyWith(title: 'New');

          expect(copy.title, 'New');
        });

        test('copies with new style', () {
          const original = SlideOptions(style: 'light');
          final copy = original.copyWith(style: 'dark');

          expect(copy.style, 'dark');
        });

        test('copies with new args', () {
          const original = SlideOptions(args: {'a': 1});
          final copy = original.copyWith(args: {'b': 2});

          expect(copy.args, {'b': 2});
        });

        test('preserves values when not specified', () {
          const original = SlideOptions(
            title: 'T',
            style: 'S',
            args: {'k': 'v'},
          );
          final copy = original.copyWith();

          expect(copy.title, original.title);
          expect(copy.style, original.style);
          expect(copy.args, original.args);
        });
      });

      group('toMap', () {
        test('serializes empty options', () {
          const options = SlideOptions();
          final map = options.toMap();

          expect(map.containsKey('title'), isFalse);
          expect(map.containsKey('style'), isFalse);
        });

        test('serializes title and style', () {
          const options = SlideOptions(title: 'T', style: 'S');
          final map = options.toMap();

          expect(map['title'], 'T');
          expect(map['style'], 'S');
        });

        test('spreads args into map', () {
          const options = SlideOptions(
            title: 'T',
            args: {'custom1': 'val1', 'custom2': 42},
          );
          final map = options.toMap();

          expect(map['title'], 'T');
          expect(map['custom1'], 'val1');
          expect(map['custom2'], 42);
        });
      });

      group('fromMap', () {
        test('deserializes empty map', () {
          final options = SlideOptions.fromMap({});

          expect(options.title, isNull);
          expect(options.style, isNull);
          expect(options.args, isEmpty);
        });

        test('deserializes title and style', () {
          final map = {'title': 'Parsed', 'style': 'parsed-style'};
          final options = SlideOptions.fromMap(map);

          expect(options.title, 'Parsed');
          expect(options.style, 'parsed-style');
        });

        test('puts unknown keys into args', () {
          final map = {
            'title': 'T',
            'customKey': 'customValue',
            'anotherKey': 123,
          };
          final options = SlideOptions.fromMap(map);

          expect(options.title, 'T');
          expect(options.args['customKey'], 'customValue');
          expect(options.args['anotherKey'], 123);
          expect(options.args.containsKey('title'), isFalse);
        });
      });

      group('round-trip serialization', () {
        test('preserves data through toMap/fromMap', () {
          const original = SlideOptions(
            title: 'RT',
            style: 'rt-style',
            args: {'k': 'v'},
          );

          final restored = SlideOptions.fromMap(original.toMap());

          expect(restored.title, original.title);
          expect(restored.style, original.style);
          expect(restored.args['k'], original.args['k']);
        });
      });

      group('parse', () {
        test('parses valid map', () {
          final options = SlideOptions.parse({'title': 'T'});

          expect(options.title, 'T');
        });

        test('parses map with additional properties', () {
          final options = SlideOptions.parse({
            'title': 'T',
            'extra': 'value',
          });

          expect(options.title, 'T');
          expect(options.args['extra'], 'value');
        });
      });

      group('equality', () {
        test('equal options are equal', () {
          const opt1 = SlideOptions(title: 'T', args: {'a': 1});
          const opt2 = SlideOptions(title: 'T', args: {'a': 1});

          expect(opt1, opt2);
          expect(opt1.hashCode, opt2.hashCode);
        });

        test('different title makes options unequal', () {
          const opt1 = SlideOptions(title: 'A');
          const opt2 = SlideOptions(title: 'B');

          expect(opt1, isNot(opt2));
        });

        test('different style makes options unequal', () {
          const opt1 = SlideOptions(style: 'light');
          const opt2 = SlideOptions(style: 'dark');

          expect(opt1, isNot(opt2));
        });

        test('different args make options unequal', () {
          const opt1 = SlideOptions(args: {'a': 1});
          const opt2 = SlideOptions(args: {'a': 2});

          expect(opt1, isNot(opt2));
        });
      });

      group('schema', () {
        test('validates empty map', () {
          final result = SlideOptions.schema.safeParse({});
          expect(result.isOk, isTrue);
        });

        test('validates map with title and style', () {
          final result = SlideOptions.schema.safeParse({
            'title': 'T',
            'style': 'S',
          });
          expect(result.isOk, isTrue);
        });

        test('allows additional properties', () {
          final result = SlideOptions.schema.safeParse({
            'title': 'T',
            'custom': 'value',
          });
          expect(result.isOk, isTrue);
        });
      });
    });
  });
}
