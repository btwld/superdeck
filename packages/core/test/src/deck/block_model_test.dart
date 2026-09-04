import 'package:ack/ack.dart';
import 'package:superdeck_core/src/deck/block_insets.dart';
import 'package:superdeck_core/src/deck/block_model.dart';
import 'package:test/test.dart';

Matcher _throwsInvalidFlex() {
  return throwsA(
    isA<ArgumentError>()
        .having((error) => error.name, 'name', 'flex')
        .having(
          (error) => error.message.toString(),
          'message',
          contains('greater than zero'),
        ),
  );
}

Matcher _throwsMappedInvalidFlex() =>
    _throwsConstraintError('#/flex', 'number_positive');

Matcher _throwsConstraintError(String path, String constraintKey) {
  return throwsA(
    isA<AckException>().having(
      (exception) => exception.errors.expand(_flattenSchemaErrors),
      'validation errors',
      contains(
        isA<SchemaConstraintsError>()
            .having((error) => error.path, 'path', path)
            .having(
              (error) => error.constraints.map(
                (constraint) => constraint.constraint.constraintKey,
              ),
              'constraint keys',
              contains(constraintKey),
            ),
      ),
    ),
  );
}

Iterable<SchemaError> _flattenSchemaErrors(SchemaError error) sync* {
  yield error;
  if (error case SchemaNestedError(errors: final nestedErrors)) {
    for (final nestedError in nestedErrors) {
      yield* _flattenSchemaErrors(nestedError);
    }
  }
}

Matcher _throwsInvalidSpacing() {
  return throwsA(
    isA<ArgumentError>()
        .having((error) => error.name, 'name', 'spacing')
        .having(
          (error) => error.message.toString(),
          'message',
          allOf(contains('finite'), contains('greater than or equal to zero')),
        ),
  );
}

Matcher _throwsInvalidInsets(String name, {required bool structural}) {
  return throwsA(
    isA<ArgumentError>()
        .having((error) => error.name, 'name', name)
        .having(
          (error) => error.message.toString(),
          'message',
          structural
              ? allOf(
                  contains('finite non-negative'),
                  contains('scalar'),
                  contains('horizontal'),
                  contains('top'),
                )
              : contains('finite non-negative'),
        ),
  );
}

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

    group('block insets authoring', () {
      final accepted = <Object, Map<String, Object?>>{
        16: {'top': 16.0, 'right': 16.0, 'bottom': 16.0, 'left': 16.0},
        {'horizontal': 24}: {
          'top': 0.0,
          'right': 24.0,
          'bottom': 0.0,
          'left': 24.0,
        },
        {'vertical': 12}: {
          'top': 12.0,
          'right': 0.0,
          'bottom': 12.0,
          'left': 0.0,
        },
        {'horizontal': 24, 'vertical': 16}: {
          'top': 16.0,
          'right': 24.0,
          'bottom': 16.0,
          'left': 24.0,
        },
        {'top': 12, 'right': 24}: {
          'top': 12.0,
          'right': 24.0,
          'bottom': 0.0,
          'left': 0.0,
        },
      };

      for (final field in const ['padding', 'margin']) {
        for (final MapEntry(key: input, value: normalized)
            in accepted.entries) {
          test('$field: $input normalizes to four physical edges', () {
            final block = Block.parseAuthoring({'type': 'block', field: input});

            expect(block.toJson()[field], normalized);
          });
        }
      }

      test('authoring schema accepts the three authoring forms', () {
        for (final input in accepted.keys) {
          expect(
            BlockInsets.authoringSchema.safeParse(input).isOk,
            isTrue,
            reason: 'insets: $input',
          );
        }
      });

      test('contract schema rejects authoring shorthand', () {
        for (final field in const ['padding', 'margin']) {
          for (final input in [
            16,
            {'horizontal': 24},
            {'top': 12, 'right': 24},
          ]) {
            expect(
              ContentBlockSchema.wireSchema.safeParse({
                'type': 'block',
                field: input,
              }).isOk,
              isFalse,
              reason: '$field: $input',
            );
          }
        }
      });

      test('contract schema accepts normalized four-edge insets', () {
        for (final field in const ['padding', 'margin']) {
          expect(
            ContentBlockSchema.wireSchema.safeParse({
              'type': 'block',
              field: {'top': 1, 'right': 2, 'bottom': 3, 'left': 4},
            }).isOk,
            isTrue,
            reason: field,
          );
        }
      });

      final structurallyInvalid = <Object>[
        <String, Object?>{},
        {'unknown': 1},
        {'horizontal': 8, 'top': 4},
      ];

      for (final field in const ['padding', 'margin']) {
        for (final input in structurallyInvalid) {
          test('$field rejects $input naming the field', () {
            expect(
              () => Block.parseAuthoring({'type': 'block', field: input}),
              _throwsInvalidInsets(field, structural: true),
            );
          });
        }

        test('$field rejects invalid scalars naming the field', () {
          for (final input in [-1, double.nan, double.infinity]) {
            expect(
              () => Block.parseAuthoring({'type': 'block', field: input}),
              _throwsInvalidInsets(field, structural: false),
              reason: '$field: $input',
            );
          }
        });

        test('$field reports the exact invalid edge', () {
          expect(
            () => Block.parseAuthoring({
              'type': 'block',
              field: {'left': -1},
            }),
            _throwsInvalidInsets('$field.left', structural: false),
          );
          expect(
            () => Block.parseAuthoring({
              'type': 'block',
              field: {'vertical': double.nan},
            }),
            _throwsInvalidInsets('$field.vertical', structural: false),
          );
          expect(
            () => Block.parseAuthoring({
              'type': 'block',
              field: {'left': null},
            }),
            _throwsInvalidInsets('$field.left', structural: false),
          );
        });

        test('$field omitted edges normalize to zero', () {
          final block = Block.parseAuthoring({
            'type': 'block',
            field: {'top': 12},
          });

          expect(block.toJson()[field], {
            'top': 12.0,
            'right': 0.0,
            'bottom': 0.0,
            'left': 0.0,
          });
        });
      }

      test('authoring schema rejects invalid forms', () {
        for (final input in [
          ...structurallyInvalid,
          -1,
          {'left': -1},
          double.nan,
          double.infinity,
        ]) {
          expect(
            BlockInsets.authoringSchema.safeParse(input).isOk,
            isFalse,
            reason: 'insets: $input',
          );
        }
      });

      test('public constructors create normalized insets', () {
        expect(BlockInsets.all(8).toJson(), {
          'top': 8.0,
          'right': 8.0,
          'bottom': 8.0,
          'left': 8.0,
        });
        expect(BlockInsets.symmetric(horizontal: 12, vertical: 6).toJson(), {
          'top': 6.0,
          'right': 12.0,
          'bottom': 6.0,
          'left': 12.0,
        });
      });

      test('public constructor rejects invalid edges', () {
        for (final value in [-1.0, double.nan, double.infinity]) {
          expect(
            () => BlockInsets(left: value),
            throwsA(
              isA<ArgumentError>()
                  .having((error) => error.name, 'name', 'left')
                  .having(
                    (error) => error.message.toString(),
                    'message',
                    contains('finite non-negative'),
                  ),
            ),
          );
        }
      });

      test('generated map and copy paths preserve invariants', () {
        final insets = BlockInsets.fromJson({
          'top': 1,
          'right': 2,
          'bottom': 3,
          'left': 4,
        });

        expect(insets.toJson(), {
          'top': 1.0,
          'right': 2.0,
          'bottom': 3.0,
          'left': 4.0,
        });
        expect(insets.copyWith(left: 5).left, 5);
        expect(
          () => insets.copyWith(left: double.nan),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('compiled model rejects unknown inset fields', () {
        expect(
          () => BlockInsets.fromJson({
            'top': 1,
            'right': 2,
            'bottom': 3,
            'left': 4,
            'unexpected': true,
          }),
          throwsA(isA<AckException>()),
        );
      });

      test('absent insets stay null; explicit zero stays representable', () {
        final inherited = Block.parseAuthoring({'type': 'block'});
        expect(inherited.margin, isNull);
        expect(inherited.padding, isNull);

        final removed = Block.parseAuthoring({
          'type': 'block',
          'margin': 0,
          'padding': 0,
        });
        expect(removed.margin, BlockInsets.all(0));
        expect(removed.padding, BlockInsets.all(0));
      });
    });

    group('ContentBlock', () {
      test('creates with default values', () {
        final block = ContentBlock('Hello');

        expect(block.content, 'Hello');
        expect(block.type, 'block');
        expect(block.flex, 1);
        expect(block.padding, isNull);
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
          padding: BlockInsets.all(8),
          scrollable: true,
        );

        expect(block.content, 'Content');
        expect(block.align, ContentAlignment.center);
        expect(block.flex, 2);
        expect(block.padding, BlockInsets.all(8));
        expect(block.scrollable, true);
      });

      group('constructor validation', () {
        for (final flex in [0, -1]) {
          test('rejects flex $flex', () {
            expect(
              () => ContentBlock('Content', flex: flex),
              _throwsInvalidFlex(),
            );
          });
        }

        test('copyWith rejects non-positive flex', () {
          final block = ContentBlock('Content');

          expect(() => block.copyWith(flex: 0), _throwsInvalidFlex());
        });

        test('fromJson rejects non-positive flex', () {
          expect(
            () => ContentBlock.fromJson({'type': 'block', 'flex': -1}),
            _throwsMappedInvalidFlex(),
          );
        });

        test('parse reports the flex field and accepted range', () {
          expect(
            () => ContentBlock.parse({'type': 'block', 'flex': 0}),
            _throwsMappedInvalidFlex(),
          );
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
            padding: BlockInsets.all(8),
            scrollable: true,
          );
          final copy = original.copyWith();

          expect(copy.content, original.content);
          expect(copy.align, original.align);
          expect(copy.flex, original.flex);
          expect(copy.padding, original.padding);
          expect(copy.scrollable, original.scrollable);
        });
      });

      group('toJson', () {
        test('serializes minimal block', () {
          final block = ContentBlock('');
          final map = block.toJson();

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
            padding: BlockInsets.symmetric(horizontal: 12, vertical: 8),
            scrollable: true,
          );
          final map = block.toJson();

          expect(map['type'], 'block');
          expect(map['content'], 'Content');
          expect(map['align'], 'center');
          expect(map['flex'], 2);
          expect(map['padding'], {
            'top': 8.0,
            'right': 12.0,
            'bottom': 8.0,
            'left': 12.0,
          });
          expect(map['scrollable'], true);
        });
      });

      group('fromJson', () {
        test('deserializes minimal map', () {
          final map = {'type': 'block'};
          final block = ContentBlock.fromJson(map);

          expect(block.content, '');
          expect(block.flex, 1);
          expect(block.scrollable, false);
          expect(block.align, isNull);
        });

        test('direct branch accepts an omitted discriminator', () {
          final block = ContentBlock.fromJson({'content': 'Direct'});

          expect(block.content, 'Direct');
          expect(block.toJson()['type'], ContentBlock.key);
        });

        test('rejects unknown fields', () {
          expect(
            () => ContentBlock.fromJson({
              'type': 'block',
              'content': 'Known',
              'unknown': {'nested': true},
            }),
            throwsA(isA<AckException>()),
          );
        });

        test('deserializes full map', () {
          final map = {
            'type': 'block',
            'content': 'Content',
            'align': 'center',
            'flex': 2,
            'padding': {'top': 1, 'right': 2, 'bottom': 3, 'left': 4},
            'scrollable': true,
          };
          final block = ContentBlock.fromJson(map);

          expect(block.content, 'Content');
          expect(block.align, ContentAlignment.center);
          expect(block.flex, 2);
          expect(
            block.padding,
            BlockInsets(top: 1, right: 2, bottom: 3, left: 4),
          );
          expect(block.scrollable, true);
        });

        test('deserializes new block type', () {
          final map = {'type': 'block', 'content': 'New format'};
          final block = ContentBlock.fromJson(map);

          expect(block.content, 'New format');
          expect(block.type, 'block');
        });

        test('normalizes an integral numeric flex', () {
          final map = {'type': 'block', 'flex': 2.0};

          expect(ContentBlock.fromJson(map).flex, 2);
        });

        test('rejects a fractional numeric flex', () {
          final map = {'type': 'block', 'flex': 2.5};

          expect(
            () => ContentBlock.fromJson(map),
            throwsA(isA<AckException>()),
          );
        });

        test('throws on invalid alignment', () {
          final map = {'type': 'block', 'align': 'invalid'};
          expect(() => ContentBlock.fromJson(map), throwsA(anything));
        });
      });

      group('round-trip serialization', () {
        test('preserves data through toJson/fromJson', () {
          final original = ContentBlock(
            'Test content',
            align: ContentAlignment.bottomRight,
            flex: 3,
            padding: BlockInsets.all(6),
            scrollable: true,
          );

          final restored = ContentBlock.fromJson(original.toJson());

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
          final result = ContentBlockSchema.wireSchema.safeParse({
            'type': 'block',
            'content': '',
          });
          expect(result.isOk, isTrue);
        });

        test('validates full block', () {
          final result = ContentBlockSchema.wireSchema.safeParse({
            'type': 'block',
            'content': 'Content',
            'align': 'center',
            'flex': 2,
            'scrollable': true,
          });
          expect(result.isOk, isTrue);
        });

        test('rejects unsupported column type', () {
          final result = ContentBlockSchema.wireSchema.safeParse({
            'type': 'column',
            'content': 'Content',
          });

          expect(result.isOk, isFalse);
        });

        test('rejects non-positive flex', () {
          for (final flex in [0, -1]) {
            final result = ContentBlockSchema.wireSchema.safeParse({
              'type': 'block',
              'flex': flex,
            });

            expect(result.isOk, isFalse, reason: 'flex: $flex');
          }
        });
      });
    });

    group('SectionBlock', () {
      test('creates with default values', () {
        final section = SectionBlock(null);

        expect(section.blocks, isEmpty);
        expect(section.type, 'section');
        expect(section.flex, 1);
        expect(section.spacing, 0);
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
          spacing: 24,
        );

        expect(section.align, ContentAlignment.center);
        expect(section.flex, 2);
        expect(section.spacing, 24);
      });

      group('constructor validation', () {
        for (final flex in [0, -1]) {
          test('rejects flex $flex', () {
            expect(() => SectionBlock([], flex: flex), _throwsInvalidFlex());
          });
        }

        test('copyWith rejects non-positive flex', () {
          final section = SectionBlock([]);

          expect(() => section.copyWith(flex: 0), _throwsInvalidFlex());
        });

        test('fromJson rejects non-positive flex', () {
          expect(
            () => SectionBlock.fromJson({'type': 'section', 'flex': -1}),
            _throwsMappedInvalidFlex(),
          );
        });

        test('parse reports the flex field and accepted range', () {
          expect(
            () => SectionBlock.parse({'type': 'section', 'flex': 0}),
            _throwsMappedInvalidFlex(),
          );
        });

        for (final spacing in [-1.0, double.nan, double.infinity]) {
          test('rejects spacing $spacing', () {
            expect(
              () => SectionBlock([], spacing: spacing),
              _throwsInvalidSpacing(),
            );
          });
        }

        test('copyWith rejects invalid spacing', () {
          final section = SectionBlock([]);

          expect(
            () => section.copyWith(spacing: double.infinity),
            _throwsInvalidSpacing(),
          );
        });

        test('parse reports the spacing field and accepted range', () {
          for (final (spacing, constraintKey) in [
            (-1.0, 'number_min'),
            (double.nan, 'number.isFinite'),
            (double.infinity, 'number.isFinite'),
          ]) {
            expect(
              () => SectionBlock.parse({'spacing': spacing}),
              _throwsConstraintError('#/spacing', constraintKey),
              reason: 'spacing: $spacing',
            );
          }
        });
      });

      group('resolveBlockAlign', () {
        test('defaults to centerLeft without explicit alignment', () {
          final block = ContentBlock('Content');
          final section = SectionBlock([block]);

          expect(section.resolveBlockAlign(block), ContentAlignment.centerLeft);
        });

        test('inherits section alignment', () {
          final block = ContentBlock('Content');
          final section = SectionBlock([
            block,
          ], align: ContentAlignment.bottomCenter);

          expect(
            section.resolveBlockAlign(block),
            ContentAlignment.bottomCenter,
          );
        });

        test('prefers explicit block alignment', () {
          final block = ContentBlock(
            'Content',
            align: ContentAlignment.topRight,
          );
          final section = SectionBlock([
            block,
          ], align: ContentAlignment.bottomLeft);

          expect(section.resolveBlockAlign(block), ContentAlignment.topRight);
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
            spacing: 16,
          );
          final copy = original.copyWith();

          expect(copy.blocks.length, original.blocks.length);
          expect(copy.align, original.align);
          expect(copy.flex, original.flex);
          expect(copy.spacing, original.spacing);
        });

        test('copies with new spacing', () {
          final original = SectionBlock([]);

          expect(original.copyWith(spacing: 32).spacing, 32);
        });
      });

      group('toJson', () {
        test('serializes empty section', () {
          final section = SectionBlock([]);
          final map = section.toJson();

          expect(map['type'], 'section');
          expect(map['blocks'], isEmpty);
          expect(map['spacing'], 0);
          expect(map.containsKey('scrollable'), isFalse);
        });

        test('serializes section with blocks', () {
          final section = SectionBlock([ContentBlock('Test')], spacing: 20);
          final map = section.toJson();

          expect(map['type'], 'section');
          expect(map['blocks'], isA<List>());
          expect((map['blocks'] as List).length, 1);
          expect(map['spacing'], 20);
          expect(map.containsKey('scrollable'), isFalse);
        });
      });

      group('fromJson', () {
        test('deserializes empty section', () {
          final map = {'type': 'section'};
          final section = SectionBlock.fromJson(map);

          expect(section.blocks, isEmpty);
        });

        test('deserializes section with blocks', () {
          final map = {
            'type': 'section',
            'blocks': [
              {'type': 'block', 'content': 'Test'},
            ],
            'spacing': 18,
          };
          final section = SectionBlock.fromJson(map);

          expect(section.blocks.length, 1);
          expect((section.blocks[0] as ContentBlock).content, 'Test');
          expect(section.spacing, 18);
        });
      });

      group('schema', () {
        test('validates full section', () {
          final result = SectionBlockSchema.wireSchema.safeParse({
            'align': 'center',
            'flex': 2,
            'blocks': [
              {'type': 'block', 'content': 'Test'},
            ],
          });

          expect(result.isOk, isTrue);
        });

        test('preserves nested blocks as wire maps', () {
          final section = SectionBlockSchema.wireSchema.parse({
            'blocks': [
              {'type': 'block', 'content': 'Test'},
            ],
          });

          final blocks = section!['blocks']! as List<Object?>;
          final block = blocks.single;
          expect(
            block,
            isA<Map<String, Object?>>().having(
              (value) => value['content'],
              'content',
              'Test',
            ),
          );
        });

        test('rejects section-level scrollable', () {
          final result = SectionBlockSchema.wireSchema.safeParse({
            'scrollable': true,
            'blocks': [
              {'type': 'block', 'content': 'Test'},
            ],
          });

          expect(result.isOk, isFalse);
        });

        test('rejects unknown section-level fields', () {
          final result = SectionBlockSchema.wireSchema.safeParse({
            'customSectionArg': 'value',
            'blocks': [
              {'type': 'block', 'content': 'Test'},
            ],
          });

          expect(result.isOk, isFalse);
        });

        test('accepts finite non-negative spacing', () {
          for (final spacing in [0, 12.5, 40]) {
            final result = SectionBlockSchema.wireSchema.safeParse({
              'spacing': spacing,
              'blocks': <Object?>[],
            });

            expect(result.isOk, isTrue, reason: 'spacing: $spacing');
          }
        });

        test('rejects non-positive flex and invalid spacing', () {
          for (final flex in [0, -1]) {
            expect(
              SectionBlockSchema.wireSchema.safeParse({'flex': flex}).isOk,
              isFalse,
              reason: 'flex: $flex',
            );
          }
          for (final spacing in [-1, double.nan, double.infinity]) {
            expect(
              SectionBlockSchema.wireSchema.safeParse({
                'spacing': spacing,
              }).isOk,
              isFalse,
              reason: 'spacing: $spacing',
            );
          }
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

      test('args snapshot nested source collections', () {
        final nestedMap = <String, Object?>{'enabled': true};
        final nestedList = <Object?>['first'];
        final nestedSet = <Object?>{'alpha'};
        final source = <String, Object?>{
          'map': nestedMap,
          'list': nestedList,
          'set': nestedSet,
        };
        final widget = WidgetBlock(name: 'Test', args: source);
        final equalSnapshot = WidgetBlock(
          name: 'Test',
          args: {
            'map': {'enabled': true},
            'list': ['first'],
            'set': {'alpha'},
          },
        );
        final originalHash = widget.hashCode;

        source['later'] = true;
        nestedMap['enabled'] = false;
        nestedList.add('second');
        nestedSet.add('beta');

        expect(widget, equalSnapshot);
        expect(widget.hashCode, originalHash);
        expect(widget.args.containsKey('later'), isFalse);
      });

      test('args nested collections are unmodifiable', () {
        final widget = WidgetBlock(
          name: 'Test',
          args: {
            'map': {'enabled': true},
            'list': ['first'],
            'set': {'alpha'},
          },
        );

        expect(
          () => (widget.args['map']! as Map<String, Object?>)['later'] = true,
          throwsUnsupportedError,
        );
        expect(
          () => (widget.args['list']! as List<Object?>).add('second'),
          throwsUnsupportedError,
        );
        expect(
          () => (widget.args['set']! as Set<Object?>).add('beta'),
          throwsUnsupportedError,
        );
      });

      group('constructor validation', () {
        for (final flex in [0, -1]) {
          test('rejects flex $flex', () {
            expect(
              () => WidgetBlock(name: 'Test', flex: flex),
              _throwsInvalidFlex(),
            );
          });
        }

        test('throws ArgumentError when args contain reserved keys', () {
          for (final reservedKey in const [
            'name',
            'align',
            'flex',
            'scrollable',
            'margin',
            'padding',
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

        test('authored insets are normalized and excluded from args', () {
          final widget =
              Block.parseAuthoring({
                    'type': 'widget',
                    'name': 'Test',
                    'padding': {'horizontal': 12, 'vertical': 8},
                    'margin': 4,
                    'custom': 'value',
                  })
                  as WidgetBlock;

          expect(widget.args.containsKey('padding'), isFalse);
          expect(widget.args.containsKey('margin'), isFalse);
          expect(widget.args['custom'], 'value');
          expect(widget.toJson()['padding'], {
            'top': 8.0,
            'right': 12.0,
            'bottom': 8.0,
            'left': 12.0,
          });
          expect(widget.toJson()['margin'], {
            'top': 4.0,
            'right': 4.0,
            'bottom': 4.0,
            'left': 4.0,
          });
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

        test('snapshots replacement args deeply', () {
          final nested = <String, Object?>{'value': 1};
          final replacement = <String, Object?>{'nested': nested};
          final copy = WidgetBlock(
            name: 'Test',
            args: {'old': true},
          ).copyWith(args: replacement);
          final originalHash = copy.hashCode;

          nested['value'] = 2;
          replacement['later'] = true;

          expect(copy.args, {
            'nested': {'value': 1},
          });
          expect(copy.hashCode, originalHash);
          expect(
            () => (copy.args['nested']! as Map<String, Object?>)['value'] = 3,
            throwsUnsupportedError,
          );
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

      group('toJson', () {
        test('serializes widget without args', () {
          final widget = WidgetBlock(name: 'Test');
          final map = widget.toJson();

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
          final map = widget.toJson();

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
          final map = widget.toJson();

          expect(map['type'], 'widget');
          expect(map['name'], 'ReservedName');
          expect(map['align'], 'center');
          expect(map['flex'], 2);
          expect(map['scrollable'], true);
          expect(map['custom'], 'value');
        });
      });

      group('fromJson', () {
        test('extracts known fields', () {
          final map = {
            'type': 'widget',
            'name': 'MyWidget',
            'flex': 3,
            'scrollable': true,
            'align': 'center',
          };
          final widget = WidgetBlock.fromJson(map);

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
          final widget = WidgetBlock.fromJson(map);

          expect(widget.args['customKey'], 'customValue');
          expect(widget.args['otherKey'], 123);
          expect(widget.args.containsKey('type'), isFalse);
          expect(widget.args.containsKey('name'), isFalse);
        });

        test('strips reserved fields from args', () {
          final widget = WidgetBlock.fromJson({
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
        test('preserves data through toJson/fromJson', () {
          final original = WidgetBlock(
            name: 'TestWidget',
            args: {'config': 'value'},
            align: ContentAlignment.topLeft,
            flex: 2,
            scrollable: true,
          );

          final restored = WidgetBlock.fromJson(original.toJson());

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
      group('fromJson', () {
        test('creates ContentBlock from block type', () {
          final map = {'type': 'block', 'content': 'Test'};
          final block = Block.fromJson(map);

          expect(block, isA<ContentBlock>());
          expect((block as ContentBlock).content, 'Test');
        });

        test('sealed union requires its discriminator', () {
          expect(
            () => Block.fromJson({'content': 'Missing type'}),
            throwsA(isA<AckException>()),
          );
        });

        test('rejects unsupported column type', () {
          final map = {'type': 'column', 'content': 'Test'};

          expect(() => Block.fromJson(map), throwsA(anything));
        });

        test('rejects SectionBlock from section type', () {
          final map = {'type': 'section', 'blocks': []};

          expect(() => Block.fromJson(map), throwsA(anything));
        });

        test('creates WidgetBlock from widget type', () {
          final map = {'type': 'widget', 'name': 'Test'};
          final block = Block.fromJson(map);

          expect(block, isA<WidgetBlock>());
          expect((block as WidgetBlock).name, 'Test');
        });

        test('throws for unknown type', () {
          final map = {'type': 'unknown'};
          expect(() => Block.fromJson(map), throwsA(anything));
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

        test('reports the flex field and accepted range', () {
          expect(
            () => Block.parse({'type': 'widget', 'name': 'Test', 'flex': -1}),
            _throwsMappedInvalidFlex(),
          );
        });
      });

      group('schema', () {
        test('validates content block', () {
          final result = BlockSchema.wireSchema.safeParse({
            'type': 'block',
            'content': 'Test',
          });
          expect(result.isOk, isTrue);
        });

        test('validates widget block', () {
          final result = BlockSchema.wireSchema.safeParse({
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

        final map = original.toJson();
        final restored = SectionBlock.fromJson(map);

        expect(restored.blocks.length, 2);
        expect(restored.blocks[0], isA<ContentBlock>());
        expect(restored.blocks[1], isA<WidgetBlock>());
      });

      test('schema rejects nested sections', () {
        final result = SectionBlockSchema.wireSchema.safeParse({
          'blocks': [
            {'type': 'section', 'blocks': []},
          ],
        });

        expect(result.isOk, isFalse);
      });
    });
  });
}
