import 'package:ack/ack.dart';
import 'package:superdeck_core/src/models/block_model.dart';
import 'package:superdeck_core/src/models/slide_model.dart';
import 'package:test/test.dart';

void main() {
  group('Slide Model', () {
    group('Slide', () {
      test('creates with required key only', () {
        final slide = Slide(key: 'test-key');

        expect(slide.key, 'test-key');
        expect(slide.options, isNull);
        expect(slide.sections, isEmpty);
        expect(slide.comments, isEmpty);
      });

      test('creates with all parameters', () {
        final sections = [
          SectionBlock([ContentBlock('Content')]),
        ];
        final comments = ['Speaker note 1', 'Speaker note 2'];
        final options = SlideOptions(title: 'Title', style: 'custom');

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

      test('sections is unmodifiable', () {
        final slide = Slide(
          key: 'immutable-sections',
          sections: [
            SectionBlock([ContentBlock('A')]),
          ],
        );

        expect(
          () => (slide.sections as List).add(SectionBlock([])),
          throwsUnsupportedError,
        );
      });

      test('comments is unmodifiable', () {
        final slide = Slide(key: 'immutable-comments', comments: ['note']);

        expect(
          () => (slide.comments as List).add('another'),
          throwsUnsupportedError,
        );
      });

      group('copyWith', () {
        test('copies with new key', () {
          final original = Slide(key: 'original');
          final copy = original.copyWith(key: 'new-key');

          expect(copy.key, 'new-key');
        });

        test('copies with new options', () {
          final original = Slide(key: 'key');
          final copy = original.copyWith(
            options: SlideOptions(title: 'New Title'),
          );

          expect(copy.options?.title, 'New Title');
        });

        test('copies with new sections', () {
          final original = Slide(key: 'key');
          final newSections = [
            SectionBlock([ContentBlock('New')]),
          ];
          final copy = original.copyWith(sections: newSections);

          expect(copy.sections.length, 1);
        });

        test('copies with new comments', () {
          final original = Slide(key: 'key');
          final copy = original.copyWith(comments: ['Note 1', 'Note 2']);

          expect(copy.comments, ['Note 1', 'Note 2']);
        });

        test('preserves values when not specified', () {
          final original = Slide(
            key: 'key',
            options: SlideOptions(title: 'Title'),
            sections: [
              SectionBlock([ContentBlock('Content')]),
            ],
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
          final slide = Slide(key: 'minimal');
          final map = slide.toMap();

          expect(map['key'], 'minimal');
          expect(map['sections'], isEmpty);
          expect(map['comments'], isEmpty);
          expect(map.containsKey('options'), isFalse);
        });

        test('serializes slide with options', () {
          final slide = Slide(
            key: 'with-opts',
            options: SlideOptions(title: 'My Title', style: 'dark'),
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
          final slide = Slide(key: 'with-comments', comments: ['Note 1']);
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

        test(
          'throws AckException when options optional fields are explicitly null',
          () {
            for (final field in ['title', 'style', 'template']) {
              expect(
                () => Slide.parse({
                  'key': 'invalid-options',
                  'options': {field: null},
                }),
                throwsA(isA<AckException>()),
              );
            }
          },
        );
      });

      group('round-trip serialization', () {
        test('preserves data through toMap/fromMap', () {
          final original = Slide(
            key: 'roundtrip',
            options: SlideOptions(title: 'RT Title', style: 'rt-style'),
            sections: [
              SectionBlock([ContentBlock('Section content')]),
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
              // Note: 'blocks' is required to satisfy Google AI schema requirements
              {'type': 'section', 'blocks': []},
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

          final content = (slide.sections[0].blocks[0] as ContentBlock).content;
          expect(content.contains('Parse Error'), isTrue);
          expect(content.contains('Could not parse slide'), isTrue);
        });

        test('includes error details in code block', () {
          final slide = Slide.error(
            title: 'Error',
            message: 'Message',
            error: Exception('Detailed error info'),
          );

          final content = (slide.sections[0].blocks[0] as ContentBlock).content;
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
          final slide1 = Slide(key: 'same', comments: ['note']);
          final slide2 = Slide(key: 'same', comments: ['note']);

          expect(slide1, slide2);
          expect(slide1.hashCode, slide2.hashCode);
        });

        test('different keys make slides unequal', () {
          final slide1 = Slide(key: 'key1');
          final slide2 = Slide(key: 'key2');

          expect(slide1, isNot(slide2));
        });

        test('different options make slides unequal', () {
          final slide1 = Slide(
            key: 'key',
            options: SlideOptions(title: 'A'),
          );
          final slide2 = Slide(
            key: 'key',
            options: SlideOptions(title: 'B'),
          );

          expect(slide1, isNot(slide2));
        });

        test('different sections make slides unequal', () {
          final slide1 = Slide(
            key: 'key',
            sections: [
              SectionBlock([ContentBlock('A')]),
            ],
          );
          final slide2 = Slide(
            key: 'key',
            sections: [
              SectionBlock([ContentBlock('B')]),
            ],
          );

          expect(slide1, isNot(slide2));
        });

        test('different comments make slides unequal', () {
          final slide1 = Slide(key: 'key', comments: ['A']);
          final slide2 = Slide(key: 'key', comments: ['B']);

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

        test('fails validation when options is explicitly null', () {
          final result = Slide.schema.safeParse({
            'key': 'full',
            'options': null,
          });
          expect(result.isOk, isFalse);
        });

        test('fails validation when options fields are explicitly null', () {
          for (final field in ['title', 'style', 'template']) {
            final result = Slide.schema.safeParse({
              'key': 'full',
              'options': {field: null},
            });

            expect(result.isOk, isFalse);
          }
        });
      });
    });

    group('SlideOptions', () {
      test('creates with default values', () {
        final options = SlideOptions();

        expect(options.title, isNull);
        expect(options.style, isNull);
        expect(options.args, isEmpty);
      });

      test('creates with all parameters', () {
        final options = SlideOptions(
          title: 'Title',
          style: 'dark',
          args: {'custom': 'value'},
        );

        expect(options.title, 'Title');
        expect(options.style, 'dark');
        expect(options.args['custom'], 'value');
      });

      test('args is unmodifiable', () {
        final options = SlideOptions(args: {'custom': 'value'});

        expect(
          () => options.args['newKey'] = 'newValue',
          throwsUnsupportedError,
        );
      });

      test('creates with template parameter', () {
        final options = SlideOptions(template: 'my-template');

        expect(options.template, 'my-template');
        expect(options.title, isNull);
        expect(options.style, isNull);
      });

      test('template defaults to null', () {
        final options = SlideOptions();

        expect(options.template, isNull);
      });

      group('copyWith', () {
        test('copies with new title', () {
          final original = SlideOptions(title: 'Original');
          final copy = original.copyWith(title: 'New');

          expect(copy.title, 'New');
        });

        test('copies with new style', () {
          final original = SlideOptions(style: 'light');
          final copy = original.copyWith(style: 'dark');

          expect(copy.style, 'dark');
        });

        test('copies with new args', () {
          final original = SlideOptions(args: {'a': 1});
          final copy = original.copyWith(args: {'b': 2});

          expect(copy.args, {'b': 2});
        });

        test('copies with new template', () {
          final original = SlideOptions(template: 'original-template');
          final copy = original.copyWith(template: 'new-template');

          expect(copy.template, 'new-template');
        });

        test('preserves values when not specified', () {
          final original = SlideOptions(
            title: 'T',
            style: 'S',
            template: 'tmpl',
            args: {'k': 'v'},
          );
          final copy = original.copyWith();

          expect(copy.title, original.title);
          expect(copy.style, original.style);
          expect(copy.template, original.template);
          expect(copy.args, original.args);
        });
      });

      group('toMap', () {
        test('serializes empty options', () {
          final options = SlideOptions();
          final map = options.toMap();

          expect(map.containsKey('title'), isFalse);
          expect(map.containsKey('style'), isFalse);
        });

        test('serializes title and style', () {
          final options = SlideOptions(title: 'T', style: 'S');
          final map = options.toMap();

          expect(map['title'], 'T');
          expect(map['style'], 'S');
        });

        test('serializes template when present', () {
          final options = SlideOptions(template: 'my-template');
          final map = options.toMap();

          expect(map['template'], 'my-template');
        });

        test('omits template when null', () {
          final options = SlideOptions(title: 'T');
          final map = options.toMap();

          expect(map.containsKey('template'), isFalse);
        });

        test('spreads args into map', () {
          final options = SlideOptions(
            title: 'T',
            args: {'custom1': 'val1', 'custom2': 42},
          );
          final map = options.toMap();

          expect(map['title'], 'T');
          expect(map['custom1'], 'val1');
          expect(map['custom2'], 42);
        });

        test('reserved fields win when args contain colliding keys', () {
          final options = SlideOptions(
            title: 'Reserved title',
            style: 'reserved-style',
            template: 'reserved-template',
            args: {
              'title': 'arg-title',
              'style': 'arg-style',
              'template': 'arg-template',
              'custom': 'value',
            },
          );
          final map = options.toMap();

          expect(map['title'], 'Reserved title');
          expect(map['style'], 'reserved-style');
          expect(map['template'], 'reserved-template');
          expect(map['custom'], 'value');
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

        test('deserializes template field', () {
          final map = {'template': 'parsed-template'};
          final options = SlideOptions.fromMap(map);

          expect(options.template, 'parsed-template');
        });

        test('removes template from args', () {
          final map = {'template': 'tmpl', 'extra': 'val'};
          final options = SlideOptions.fromMap(map);

          expect(options.template, 'tmpl');
          expect(options.args.containsKey('template'), isFalse);
          expect(options.args['extra'], 'val');
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

        test('strips all reserved keys from args', () {
          final options = SlideOptions.fromMap({
            'title': 'T',
            'style': 'S',
            'template': 'tmpl',
            'extra': 'value',
          });

          expect(options.args.containsKey('title'), isFalse);
          expect(options.args.containsKey('style'), isFalse);
          expect(options.args.containsKey('template'), isFalse);
          expect(options.args['extra'], 'value');
        });
      });

      group('round-trip serialization', () {
        test('preserves data through toMap/fromMap', () {
          final original = SlideOptions(
            title: 'RT',
            style: 'rt-style',
            args: {'k': 'v'},
          );

          final restored = SlideOptions.fromMap(original.toMap());

          expect(restored.title, original.title);
          expect(restored.style, original.style);
          expect(restored.args['k'], original.args['k']);
        });

        test('preserves template through toMap/fromMap', () {
          final original = SlideOptions(title: 'RT', template: 'rt-template');

          final restored = SlideOptions.fromMap(original.toMap());

          expect(restored.template, original.template);
          expect(restored.args.containsKey('template'), isFalse);
        });
      });

      group('parse', () {
        test('parses valid map', () {
          final options = SlideOptions.parse({'title': 'T'});

          expect(options.title, 'T');
        });

        test('parses map with additional properties', () {
          final options = SlideOptions.parse({'title': 'T', 'extra': 'value'});

          expect(options.title, 'T');
          expect(options.args['extra'], 'value');
        });

        test('parses map with template field', () {
          final options = SlideOptions.parse({
            'title': 'T',
            'template': 'parsed-template',
          });

          expect(options.title, 'T');
          expect(options.template, 'parsed-template');
          expect(options.args.containsKey('template'), isFalse);
        });
      });

      group('equality', () {
        test('equal options are equal', () {
          final opt1 = SlideOptions(title: 'T', args: {'a': 1});
          final opt2 = SlideOptions(title: 'T', args: {'a': 1});

          expect(opt1, opt2);
          expect(opt1.hashCode, opt2.hashCode);
        });

        test('different title makes options unequal', () {
          final opt1 = SlideOptions(title: 'A');
          final opt2 = SlideOptions(title: 'B');

          expect(opt1, isNot(opt2));
        });

        test('different style makes options unequal', () {
          final opt1 = SlideOptions(style: 'light');
          final opt2 = SlideOptions(style: 'dark');

          expect(opt1, isNot(opt2));
        });

        test('different args make options unequal', () {
          final opt1 = SlideOptions(args: {'a': 1});
          final opt2 = SlideOptions(args: {'a': 2});

          expect(opt1, isNot(opt2));
        });

        test('different template makes options unequal', () {
          final opt1 = SlideOptions(template: 'template-a');
          final opt2 = SlideOptions(template: 'template-b');

          expect(opt1, isNot(opt2));
        });

        test('template present vs absent makes options unequal', () {
          final opt1 = SlideOptions(template: 'some-template');
          final opt2 = SlideOptions();

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

        test('validates map with template field', () {
          final result = SlideOptions.schema.safeParse({
            'title': 'T',
            'template': 'my-template',
          });
          expect(result.isOk, isTrue);
        });

        test('validates map with only template field', () {
          final result = SlideOptions.schema.safeParse({
            'template': 'standalone-template',
          });
          expect(result.isOk, isTrue);
        });

        test('fails validation when optional fields are explicitly null', () {
          for (final field in ['title', 'style', 'template']) {
            final result = SlideOptions.schema.safeParse({field: null});
            expect(result.isOk, isFalse);
          }
        });
      });
    });
  });
}
