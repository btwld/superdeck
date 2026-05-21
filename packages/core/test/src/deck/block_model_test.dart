import 'package:superdeck_core/src/deck/block_model.dart';
import 'package:test/test.dart';

void main() {
  group('Block Model', () {
    group('DartPadTheme', () {
      group('toJson', () {
        test('dark returns "dark"', () {
          expect(DartPadTheme.dark.toJson(), 'dark');
        });

        test('light returns "light"', () {
          expect(DartPadTheme.light.toJson(), 'light');
        });
      });

      group('fromJson', () {
        test('parses "dark"', () {
          expect(DartPadTheme.fromJson('dark'), DartPadTheme.dark);
        });

        test('parses "light"', () {
          expect(DartPadTheme.fromJson('light'), DartPadTheme.light);
        });

        test('parses case-insensitively', () {
          expect(DartPadTheme.fromJson('DARK'), DartPadTheme.dark);
          expect(DartPadTheme.fromJson('Light'), DartPadTheme.light);
        });

        test('throws for invalid value', () {
          expect(
            () => DartPadTheme.fromJson('invalid'),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('schema', () {
        test('validates "dark"', () {
          expect(DartPadTheme.schema.safeParse('dark').isOk, isTrue);
        });

        test('validates "light"', () {
          expect(DartPadTheme.schema.safeParse('light').isOk, isTrue);
        });

        test('rejects invalid values', () {
          expect(DartPadTheme.schema.safeParse('invalid').isOk, isFalse);
          expect(DartPadTheme.schema.safeParse('').isOk, isFalse);
        });
      });
    });

    group('ImageFit', () {
      group('toJson', () {
        test('returns correct name for each value', () {
          expect(ImageFit.fill.toJson(), 'fill');
          expect(ImageFit.contain.toJson(), 'contain');
          expect(ImageFit.cover.toJson(), 'cover');
          expect(ImageFit.fitWidth.toJson(), 'fitWidth');
          expect(ImageFit.fitHeight.toJson(), 'fitHeight');
          expect(ImageFit.none.toJson(), 'none');
          expect(ImageFit.scaleDown.toJson(), 'scaleDown');
        });
      });

      group('fromJson', () {
        test('parses all values', () {
          expect(ImageFit.fromJson('fill'), ImageFit.fill);
          expect(ImageFit.fromJson('contain'), ImageFit.contain);
          expect(ImageFit.fromJson('cover'), ImageFit.cover);
          expect(ImageFit.fromJson('fitWidth'), ImageFit.fitWidth);
          expect(ImageFit.fromJson('fitHeight'), ImageFit.fitHeight);
          expect(ImageFit.fromJson('none'), ImageFit.none);
          expect(ImageFit.fromJson('scaleDown'), ImageFit.scaleDown);
        });

        test('throws for underscored values', () {
          expect(
            () => ImageFit.fromJson('fit_width'),
            throwsA(isA<ArgumentError>()),
          );
          expect(
            () => ImageFit.fromJson('fit_height'),
            throwsA(isA<ArgumentError>()),
          );
          expect(
            () => ImageFit.fromJson('scale_down'),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('parses case-insensitively', () {
          expect(ImageFit.fromJson('FILL'), ImageFit.fill);
          expect(ImageFit.fromJson('Cover'), ImageFit.cover);
          expect(ImageFit.fromJson('FITWIDTH'), ImageFit.fitWidth);
        });

        test('throws for invalid value', () {
          expect(
            () => ImageFit.fromJson('invalid'),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('schema', () {
        test('validates all enum values', () {
          expect(ImageFit.schema.safeParse('fill').isOk, isTrue);
          expect(ImageFit.schema.safeParse('contain').isOk, isTrue);
          expect(ImageFit.schema.safeParse('cover').isOk, isTrue);
          expect(ImageFit.schema.safeParse('fitWidth').isOk, isTrue);
          expect(ImageFit.schema.safeParse('fitHeight').isOk, isTrue);
          expect(ImageFit.schema.safeParse('none').isOk, isTrue);
          expect(ImageFit.schema.safeParse('scaleDown').isOk, isTrue);
        });

        test('rejects underscored values', () {
          expect(ImageFit.schema.safeParse('fit_width').isOk, isFalse);
          expect(ImageFit.schema.safeParse('fit_height').isOk, isFalse);
          expect(ImageFit.schema.safeParse('scale_down').isOk, isFalse);
        });

        test('rejects invalid values', () {
          expect(ImageFit.schema.safeParse('invalid').isOk, isFalse);
          expect(ImageFit.schema.safeParse('fitwidth').isOk, isFalse);
        });
      });
    });

    group('ContentAlignment', () {
      group('toJson', () {
        test('returns correct name for each value', () {
          expect(ContentAlignment.topLeft.toJson(), 'topLeft');
          expect(ContentAlignment.topCenter.toJson(), 'topCenter');
          expect(ContentAlignment.topRight.toJson(), 'topRight');
          expect(ContentAlignment.centerLeft.toJson(), 'centerLeft');
          expect(ContentAlignment.center.toJson(), 'center');
          expect(ContentAlignment.centerRight.toJson(), 'centerRight');
          expect(ContentAlignment.bottomLeft.toJson(), 'bottomLeft');
          expect(ContentAlignment.bottomCenter.toJson(), 'bottomCenter');
          expect(ContentAlignment.bottomRight.toJson(), 'bottomRight');
        });
      });

      group('fromJson', () {
        test('parses all values', () {
          expect(
            ContentAlignment.fromJson('topLeft'),
            ContentAlignment.topLeft,
          );
          expect(
            ContentAlignment.fromJson('topCenter'),
            ContentAlignment.topCenter,
          );
          expect(
            ContentAlignment.fromJson('topRight'),
            ContentAlignment.topRight,
          );
          expect(
            ContentAlignment.fromJson('centerLeft'),
            ContentAlignment.centerLeft,
          );
          expect(ContentAlignment.fromJson('center'), ContentAlignment.center);
          expect(
            ContentAlignment.fromJson('centerRight'),
            ContentAlignment.centerRight,
          );
          expect(
            ContentAlignment.fromJson('bottomLeft'),
            ContentAlignment.bottomLeft,
          );
          expect(
            ContentAlignment.fromJson('bottomCenter'),
            ContentAlignment.bottomCenter,
          );
          expect(
            ContentAlignment.fromJson('bottomRight'),
            ContentAlignment.bottomRight,
          );
        });

        test('throws for underscored values', () {
          expect(
            () => ContentAlignment.fromJson('top_left'),
            throwsA(isA<ArgumentError>()),
          );
          expect(
            () => ContentAlignment.fromJson('top_center'),
            throwsA(isA<ArgumentError>()),
          );
          expect(
            () => ContentAlignment.fromJson('center_left'),
            throwsA(isA<ArgumentError>()),
          );
          expect(
            () => ContentAlignment.fromJson('bottom_right'),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('parses case-insensitively', () {
          expect(
            ContentAlignment.fromJson('TOPLEFT'),
            ContentAlignment.topLeft,
          );
          expect(ContentAlignment.fromJson('Center'), ContentAlignment.center);
          expect(
            ContentAlignment.fromJson('BOTTOMCENTER'),
            ContentAlignment.bottomCenter,
          );
        });

        test('throws for invalid value', () {
          expect(
            () => ContentAlignment.fromJson('invalid'),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('schema', () {
        test('validates all enum values', () {
          expect(ContentAlignment.schema.safeParse('topLeft').isOk, isTrue);
          expect(ContentAlignment.schema.safeParse('topCenter').isOk, isTrue);
          expect(ContentAlignment.schema.safeParse('topRight').isOk, isTrue);
          expect(ContentAlignment.schema.safeParse('centerLeft').isOk, isTrue);
          expect(ContentAlignment.schema.safeParse('center').isOk, isTrue);
          expect(ContentAlignment.schema.safeParse('centerRight').isOk, isTrue);
          expect(ContentAlignment.schema.safeParse('bottomLeft').isOk, isTrue);
          expect(
            ContentAlignment.schema.safeParse('bottomCenter').isOk,
            isTrue,
          );
          expect(ContentAlignment.schema.safeParse('bottomRight').isOk, isTrue);
        });

        test('rejects underscored values', () {
          expect(ContentAlignment.schema.safeParse('top_left').isOk, isFalse);
          expect(ContentAlignment.schema.safeParse('top_center').isOk, isFalse);
          expect(
            ContentAlignment.schema.safeParse('center_left').isOk,
            isFalse,
          );
          expect(
            ContentAlignment.schema.safeParse('bottom_right').isOk,
            isFalse,
          );
        });

        test('rejects invalid values', () {
          expect(ContentAlignment.schema.safeParse('invalid').isOk, isFalse);
          expect(ContentAlignment.schema.safeParse('topleft').isOk, isFalse);
        });
      });
    });

    group('ContentBlock', () {
      test('creates with default values', () {
        final block = ContentBlock('Hello');

        expect(block.content, 'Hello');
        expect(block.type, 'block');
        expect(block.flex, 1);
        expect(block.scrollable, false);
        expect(block.align, isNull);
      });

      test('creates with null content as empty string', () {
        final block = ContentBlock(null);

        expect(block.content, '');
      });

      test('creates with all parameters', () {
        final block = ContentBlock(
          'Content',
          align: ContentAlignment.center,
          flex: 2,
          scrollable: true,
        );

        expect(block.content, 'Content');
        expect(block.align, ContentAlignment.center);
        expect(block.flex, 2);
        expect(block.scrollable, true);
      });

      group('resolvedAlign', () {
        test('defaults to centerLeft when align is not set', () {
          final block = ContentBlock('Content');

          expect(block.align, isNull);
          expect(block.resolvedAlign, ContentAlignment.centerLeft);
        });

        test('uses explicit align when set', () {
          final block = ContentBlock(
            'Content',
            align: ContentAlignment.center,
          );

          expect(block.resolvedAlign, ContentAlignment.center);
        });
      });

      group('copyWith', () {
        test('copies with new content', () {
          final original = ContentBlock('Original');
          final copy = original.copyWith(content: 'New');

          expect(copy.content, 'New');
          expect(copy.flex, original.flex);
        });

        test('copies with new alignment', () {
          final original = ContentBlock('Content');
          final copy = original.copyWith(align: ContentAlignment.topLeft);

          expect(copy.align, ContentAlignment.topLeft);
          expect(copy.content, original.content);
        });

        test('copies with new flex', () {
          final original = ContentBlock('Content');
          final copy = original.copyWith(flex: 3);

          expect(copy.flex, 3);
        });

        test('copies with new scrollable', () {
          final original = ContentBlock('Content');
          final copy = original.copyWith(scrollable: true);

          expect(copy.scrollable, true);
        });

        test('preserves values when not specified', () {
          final original = ContentBlock(
            'Content',
            align: ContentAlignment.center,
            flex: 2,
            scrollable: true,
          );
          final copy = original.copyWith();

          expect(copy.content, original.content);
          expect(copy.align, original.align);
          expect(copy.flex, original.flex);
          expect(copy.scrollable, original.scrollable);
        });
      });

      group('toMap', () {
        test('serializes minimal block', () {
          final block = ContentBlock('');
          final map = block.toMap();

          expect(map['type'], 'block');
          expect(map['flex'], 1);
          expect(map['scrollable'], false);
          expect(map['content'], '');
          expect(map.containsKey('align'), isFalse);
        });

        test('serializes full block', () {
          final block = ContentBlock(
            'Content',
            align: ContentAlignment.center,
            flex: 2,
            scrollable: true,
          );
          final map = block.toMap();

          expect(map['type'], 'block');
          expect(map['content'], 'Content');
          expect(map['align'], 'center');
          expect(map['flex'], 2);
          expect(map['scrollable'], true);
        });
      });

      group('fromMap', () {
        test('deserializes minimal map', () {
          final map = {'type': 'block'};
          final block = ContentBlock.fromMap(map);

          expect(block.content, '');
          expect(block.flex, 1);
          expect(block.scrollable, false);
          expect(block.align, isNull);
        });

        test('deserializes full map', () {
          final map = {
            'type': 'block',
            'content': 'Content',
            'align': 'center',
            'flex': 2,
            'scrollable': true,
          };
          final block = ContentBlock.fromMap(map);

          expect(block.content, 'Content');
          expect(block.align, ContentAlignment.center);
          expect(block.flex, 2);
          expect(block.scrollable, true);
        });

        test('deserializes new block type', () {
          final map = {'type': 'block', 'content': 'New format'};
          final block = ContentBlock.fromMap(map);

          expect(block.content, 'New format');
          expect(block.type, 'block');
        });

        test('handles numeric flex as double', () {
          final map = {'type': 'block', 'flex': 2.0};
          final block = ContentBlock.fromMap(map);

          expect(block.flex, 2);
        });

        test('throws on invalid alignment', () {
          final map = {'type': 'block', 'align': 'invalid'};
          expect(() => ContentBlock.fromMap(map), throwsA(anything));
        });
      });

      group('round-trip serialization', () {
        test('preserves data through toMap/fromMap', () {
          final original = ContentBlock(
            'Test content',
            align: ContentAlignment.bottomRight,
            flex: 3,
            scrollable: true,
          );

          final restored = ContentBlock.fromMap(original.toMap());

          expect(restored, original);
        });
      });

      group('equality', () {
        test('equal blocks are equal', () {
          final block1 = ContentBlock('Content', flex: 2);
          final block2 = ContentBlock('Content', flex: 2);

          expect(block1, block2);
          expect(block1.hashCode, block2.hashCode);
        });

        test('different content makes blocks unequal', () {
          final block1 = ContentBlock('Content1');
          final block2 = ContentBlock('Content2');

          expect(block1, isNot(block2));
        });

        test('different alignment makes blocks unequal', () {
          final block1 = ContentBlock('X', align: ContentAlignment.center);
          final block2 = ContentBlock('X', align: ContentAlignment.topLeft);

          expect(block1, isNot(block2));
        });
      });

      group('schema', () {
        test('validates minimal block', () {
          // Note: 'content' is required to satisfy Google AI schema requirements
          final result = ContentBlock.schema.safeParse({
            'type': 'block',
            'content': '',
          });
          expect(result.isOk, isTrue);
        });

        test('validates full block', () {
          final result = ContentBlock.schema.safeParse({
            'type': 'block',
            'content': 'Content',
            'align': 'center',
            'flex': 2,
            'scrollable': true,
          });
          expect(result.isOk, isTrue);
        });

        test('rejects unsupported column type', () {
          final result = ContentBlock.schema.safeParse({
            'type': 'column',
            'content': 'Content',
          });

          expect(result.isOk, isFalse);
        });
      });
    });

    group('SectionBlock', () {
      test('creates with default values', () {
        final section = SectionBlock(null);

        expect(section.blocks, isEmpty);
        expect(section.type, 'section');
        expect(section.flex, 1);
      });

      test('creates with child blocks', () {
        final children = [ContentBlock('A'), ContentBlock('B')];
        final section = SectionBlock(children);

        expect(section.blocks.length, 2);
        expect((section.blocks[0] as ContentBlock).content, 'A');
      });

      test('blocks is unmodifiable', () {
        final section = SectionBlock([ContentBlock('A')]);

        expect(
          () => (section.blocks as List).add(ContentBlock('B')),
          throwsUnsupportedError,
        );
      });

      test('creates with all parameters', () {
        final section = SectionBlock(
          [ContentBlock('Test')],
          align: ContentAlignment.center,
          flex: 2,
        );

        expect(section.align, ContentAlignment.center);
        expect(section.flex, 2);
      });

      group('totalBlockFlex', () {
        test('returns 0 for empty section', () {
          final section = SectionBlock([]);
          expect(section.totalBlockFlex, 0);
        });

        test('sums child flex values', () {
          final section = SectionBlock([
            ContentBlock('A', flex: 1),
            ContentBlock('B', flex: 2),
            ContentBlock('C', flex: 3),
          ]);

          expect(section.totalBlockFlex, 6);
        });
      });

      group('copyWith', () {
        test('copies with new blocks', () {
          final original = SectionBlock([ContentBlock('A')]);
          final newBlocks = [ContentBlock('B'), ContentBlock('C')];
          final copy = original.copyWith(blocks: newBlocks);

          expect(copy.blocks.length, 2);
        });

        test('preserves values when not specified', () {
          final original = SectionBlock(
            [ContentBlock('Test')],
            align: ContentAlignment.center,
            flex: 2,
          );
          final copy = original.copyWith();

          expect(copy.blocks.length, original.blocks.length);
          expect(copy.align, original.align);
          expect(copy.flex, original.flex);
        });
      });

      group('toMap', () {
        test('serializes empty section', () {
          final section = SectionBlock([]);
          final map = section.toMap();

          expect(map['type'], 'section');
          expect(map['blocks'], isEmpty);
          expect(map.containsKey('scrollable'), isFalse);
        });

        test('serializes section with blocks', () {
          final section = SectionBlock([ContentBlock('Test')]);
          final map = section.toMap();

          expect(map['type'], 'section');
          expect(map['blocks'], isA<List>());
          expect((map['blocks'] as List).length, 1);
          expect(map.containsKey('scrollable'), isFalse);
        });
      });

      group('fromMap', () {
        test('deserializes empty section', () {
          final map = {'type': 'section'};
          final section = SectionBlock.fromMap(map);

          expect(section.blocks, isEmpty);
        });

        test('deserializes section with blocks', () {
          final map = {
            'type': 'section',
            'blocks': [
              {'type': 'block', 'content': 'Test'},
            ],
          };
          final section = SectionBlock.fromMap(map);

          expect(section.blocks.length, 1);
          expect((section.blocks[0] as ContentBlock).content, 'Test');
        });
      });

      group('schema', () {
        test('validates full section', () {
          final result = SectionBlock.schema.safeParse({
            'align': 'center',
            'flex': 2,
            'blocks': [
              {'type': 'block', 'content': 'Test'},
            ],
          });

          expect(result.isOk, isTrue);
        });

        test('rejects section-level scrollable', () {
          final result = SectionBlock.schema.safeParse({
            'scrollable': true,
            'blocks': [
              {'type': 'block', 'content': 'Test'},
            ],
          });

          expect(result.isOk, isFalse);
        });

        test('rejects unknown section-level fields', () {
          final result = SectionBlock.schema.safeParse({
            'customSectionArg': 'value',
            'blocks': [
              {'type': 'block', 'content': 'Test'},
            ],
          });

          expect(result.isOk, isFalse);
        });
      });

      group('text factory', () {
        test('creates section with single content block', () {
          final section = SectionBlock.text('Hello');

          expect(section.blocks.length, 1);
          expect((section.blocks[0] as ContentBlock).content, 'Hello');
        });
      });

      group('equality', () {
        test('equal sections are equal', () {
          final section1 = SectionBlock([ContentBlock('A')], flex: 2);
          final section2 = SectionBlock([ContentBlock('A')], flex: 2);

          expect(section1, section2);
          expect(section1.hashCode, section2.hashCode);
        });

        test('different blocks make sections unequal', () {
          final section1 = SectionBlock([ContentBlock('A')]);
          final section2 = SectionBlock([ContentBlock('B')]);

          expect(section1, isNot(section2));
        });
      });
    });

    group('WidgetBlock', () {
      test('creates with required name', () {
        final widget = WidgetBlock(name: 'CustomWidget');

        expect(widget.name, 'CustomWidget');
        expect(widget.type, 'widget');
        expect(widget.args, isEmpty);
        expect(widget.flex, 1);
        expect(widget.scrollable, false);
      });

      test('creates with args', () {
        final widget = WidgetBlock(
          name: 'Test',
          args: {'key': 'value', 'count': 42},
        );

        expect(widget.args['key'], 'value');
        expect(widget.args['count'], 42);
      });

      test('args are unmodifiable', () {
        final widget = WidgetBlock(name: 'Test', args: {'key': 'value'});

        expect(() => widget.args['newKey'] = 'fail', throwsUnsupportedError);
      });

      group('constructor validation', () {
        test('throws ArgumentError when args contain reserved keys', () {
          for (final reservedKey in const [
            'name',
            'align',
            'flex',
            'scrollable',
          ]) {
            expect(
              () => WidgetBlock(
                name: 'Test',
                args: {reservedKey: 'invalid', 'custom': 'kept'},
              ),
              throwsArgumentError,
            );
          }
        });

        test('silently strips type key leaked by deserialization hook', () {
          final widget = WidgetBlock(
            name: 'Test',
            args: {'type': 'widget', 'custom': 'kept'},
          );

          expect(widget.args.containsKey('type'), isFalse);
          expect(widget.args['custom'], 'kept');
        });

        test('non-reserved keys pass through unchanged', () {
          final widget = WidgetBlock(
            name: 'Test',
            args: {'custom': 'value', 'count': 42, 'flag': true},
          );

          expect(widget.args, {'custom': 'value', 'count': 42, 'flag': true});
        });
      });

      group('resolvedAlign', () {
        test('defaults to centerLeft when align is not set', () {
          final widget = WidgetBlock(name: 'Test');

          expect(widget.align, isNull);
          expect(widget.resolvedAlign, ContentAlignment.centerLeft);
        });

        test('uses explicit align when set', () {
          final widget = WidgetBlock(
            name: 'Test',
            align: ContentAlignment.topRight,
          );

          expect(widget.resolvedAlign, ContentAlignment.topRight);
        });
      });

      group('copyWith', () {
        test('copies with new name', () {
          final original = WidgetBlock(name: 'Original');
          final copy = original.copyWith(name: 'NewName');

          expect(copy.name, 'NewName');
        });

        test('copies with new args', () {
          final original = WidgetBlock(name: 'Test', args: {'a': 1});
          final copy = original.copyWith(args: {'b': 2});

          expect(copy.args, {'b': 2});
        });

        test('preserves values when not specified', () {
          final original = WidgetBlock(
            name: 'Test',
            args: {'key': 'value'},
            align: ContentAlignment.center,
            flex: 2,
            scrollable: true,
          );
          final copy = original.copyWith();

          expect(copy.name, original.name);
          expect(copy.args, original.args);
          expect(copy.align, original.align);
          expect(copy.flex, original.flex);
          expect(copy.scrollable, original.scrollable);
        });
      });

      group('toMap', () {
        test('serializes widget without args', () {
          final widget = WidgetBlock(name: 'Test');
          final map = widget.toMap();

          expect(map['type'], 'widget');
          expect(map['name'], 'Test');
          expect(map['flex'], 1);
          expect(map['scrollable'], false);
        });

        test('spreads args into map', () {
          final widget = WidgetBlock(
            name: 'Test',
            args: {'customKey': 'customValue', 'count': 5},
          );
          final map = widget.toMap();

          expect(map['customKey'], 'customValue');
          expect(map['count'], 5);
        });

        test('serializes reserved fields and custom args together', () {
          final widget = WidgetBlock(
            name: 'ReservedName',
            align: ContentAlignment.center,
            flex: 2,
            scrollable: true,
            args: {'custom': 'value'},
          );
          final map = widget.toMap();

          expect(map['type'], 'widget');
          expect(map['name'], 'ReservedName');
          expect(map['align'], 'center');
          expect(map['flex'], 2);
          expect(map['scrollable'], true);
          expect(map['custom'], 'value');
        });
      });

      group('fromMap', () {
        test('extracts known fields', () {
          final map = {
            'type': 'widget',
            'name': 'MyWidget',
            'flex': 3,
            'scrollable': true,
            'align': 'center',
          };
          final widget = WidgetBlock.fromMap(map);

          expect(widget.name, 'MyWidget');
          expect(widget.flex, 3);
          expect(widget.scrollable, true);
          expect(widget.align, ContentAlignment.center);
        });

        test('puts unknown fields into args', () {
          final map = {
            'type': 'widget',
            'name': 'Test',
            'customKey': 'customValue',
            'otherKey': 123,
          };
          final widget = WidgetBlock.fromMap(map);

          expect(widget.args['customKey'], 'customValue');
          expect(widget.args['otherKey'], 123);
          expect(widget.args.containsKey('type'), isFalse);
          expect(widget.args.containsKey('name'), isFalse);
        });

        test('strips reserved fields from args', () {
          final widget = WidgetBlock.fromMap({
            'type': 'widget',
            'name': 'MyWidget',
            'align': 'center',
            'flex': 3,
            'scrollable': true,
            'custom': 'value',
          });

          expect(widget.args.containsKey('type'), isFalse);
          expect(widget.args.containsKey('name'), isFalse);
          expect(widget.args.containsKey('align'), isFalse);
          expect(widget.args.containsKey('flex'), isFalse);
          expect(widget.args.containsKey('scrollable'), isFalse);
          expect(widget.args['custom'], 'value');
        });
      });

      group('round-trip serialization', () {
        test('preserves data through toMap/fromMap', () {
          final original = WidgetBlock(
            name: 'TestWidget',
            args: {'config': 'value'},
            align: ContentAlignment.topLeft,
            flex: 2,
            scrollable: true,
          );

          final restored = WidgetBlock.fromMap(original.toMap());

          expect(restored, original);
        });
      });

      group('equality', () {
        test('equal widgets are equal', () {
          final widget1 = WidgetBlock(name: 'Test', args: {'a': 1});
          final widget2 = WidgetBlock(name: 'Test', args: {'a': 1});

          expect(widget1, widget2);
          expect(widget1.hashCode, widget2.hashCode);
        });

        test('different names make widgets unequal', () {
          final widget1 = WidgetBlock(name: 'Widget1');
          final widget2 = WidgetBlock(name: 'Widget2');

          expect(widget1, isNot(widget2));
        });

        test('different args make widgets unequal', () {
          final widget1 = WidgetBlock(name: 'Test', args: {'a': 1});
          final widget2 = WidgetBlock(name: 'Test', args: {'a': 2});

          expect(widget1, isNot(widget2));
        });
      });
    });

    group('Block', () {
      group('fromMap', () {
        test('creates ContentBlock from block type', () {
          final map = {'type': 'block', 'content': 'Test'};
          final block = Block.fromMap(map);

          expect(block, isA<ContentBlock>());
          expect((block as ContentBlock).content, 'Test');
        });

        test('rejects unsupported column type', () {
          final map = {'type': 'column', 'content': 'Test'};

          expect(() => Block.fromMap(map), throwsA(anything));
        });

        test('rejects SectionBlock from section type', () {
          final map = {'type': 'section', 'blocks': []};

          expect(() => Block.fromMap(map), throwsA(anything));
        });

        test('creates WidgetBlock from widget type', () {
          final map = {'type': 'widget', 'name': 'Test'};
          final block = Block.fromMap(map);

          expect(block, isA<WidgetBlock>());
          expect((block as WidgetBlock).name, 'Test');
        });

        test('throws for unknown type', () {
          final map = {'type': 'unknown'};
          expect(() => Block.fromMap(map), throwsA(anything));
        });
      });

      group('parse', () {
        test('parses ContentBlock', () {
          final map = {'type': 'block', 'content': 'Parsed'};
          final block = Block.parse(map);

          expect(block, isA<ContentBlock>());
        });

        test('rejects unsupported column type', () {
          final map = {'type': 'column', 'content': 'Parsed'};

          expect(() => Block.parse(map), throwsA(anything));
        });

        test('parses WidgetBlock', () {
          final map = {'type': 'widget', 'name': 'ParsedWidget'};
          final block = Block.parse(map);

          expect(block, isA<WidgetBlock>());
        });
      });

      group('schema', () {
        test('validates content block', () {
          final result = Block.schema.safeParse({
            'type': 'block',
            'content': 'Test',
          });
          expect(result.isOk, isTrue);
        });

        test('validates widget block', () {
          final result = Block.schema.safeParse({
            'type': 'widget',
            'name': 'Test',
          });
          expect(result.isOk, isTrue);
        });
      });
    });

    group('Nested structures', () {
      test('round-trips mixed leaf blocks', () {
        final original = SectionBlock([
          ContentBlock('A', align: ContentAlignment.topLeft),
          WidgetBlock(name: 'W', args: {'x': 1}),
        ]);

        final map = original.toMap();
        final restored = SectionBlock.fromMap(map);

        expect(restored.blocks.length, 2);
        expect(restored.blocks[0], isA<ContentBlock>());
        expect(restored.blocks[1], isA<WidgetBlock>());
      });

      test('schema rejects nested sections', () {
        final result = SectionBlock.schema.safeParse({
          'blocks': [
            {'type': 'section', 'blocks': []},
          ],
        });

        expect(result.isOk, isFalse);
      });
    });
  });
}
