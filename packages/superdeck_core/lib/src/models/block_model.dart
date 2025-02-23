import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../helpers/mappers.dart';

part 'block_model.mapper.dart';

@MappableClass(
  discriminatorKey: 'type',
)
sealed class Block with BlockMappable {
  final String type;
  final ContentAlignment? align;
  final int flex;
  final bool scrollable;
  Block({
    required this.type,
    this.align,
    this.flex = 1,
    this.scrollable = false,
  });

  static final schema = Ok.object(
    {
      'type': Ok.string(),
      'align': ContentAlignment.schema.nullable(),
      'flex': Ok.int(),
      'scrollable': Ok.boolean(),
    },
    required: ['type'],
    additionalProperties: true,
  );

  static Block parse(Map<String, dynamic> map) {
    discriminatedSchema.validateOrThrow(map);
    return BlockMapper.fromMap(map);
  }

  static final discriminatedSchema = Ok.discriminated(
    discriminatorKey: 'type',
    schemas: {
      ColumnBlock.key: ColumnBlock.schema(),
      DartPadBlock.key: DartPadBlock.schema(),
      WidgetBlock.key: WidgetBlock.schema(),
      ImageBlock.key: ImageBlock.schema(),
    },
  );
}

@MappableClass(
  includeCustomMappers: [NullIfEmptyBlock()],
  discriminatorValue: SectionBlock.key,
)
class SectionBlock extends Block with SectionBlockMappable {
  late final List<Block> blocks;

  static const key = 'section';

  SectionBlock(
    List<Block>? blocks, {
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key) {
    this.blocks = blocks ?? [];
  }

  int get totalBlockFlex {
    return blocks.fold(0, (total, block) => total + block.flex);
  }

  static SectionBlock text(String content) {
    return SectionBlock([ColumnBlock(content)]);
  }

  static final schema = Block.schema.extend(
    {
      'blocks': Block.discriminatedSchema.list(),
    },
  );
}

@MappableClass(discriminatorValue: ColumnBlock.key)
class ColumnBlock extends Block with ColumnBlockMappable {
  static const key = 'column';
  late final String content;
  ColumnBlock(
    String? content, {
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key) {
    this.content = content ?? '';
  }

  static final schema = Block.schema.extend(
    {
      'content': Ok.string(),
    },
  );
}

@MappableEnum()
enum DartPadTheme {
  dark,
  light;

  static final schema = Ok.enumValues(values);
}

@MappableClass(discriminatorValue: DartPadBlock.key)
class DartPadBlock extends Block with DartPadBlockMappable {
  final String id;
  final DartPadTheme? theme;
  final bool embed;
  final bool run;

  static const key = 'dartpad';

  DartPadBlock({
    required this.id,
    this.theme,
    this.embed = true,
    this.run = true,
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key);

  String getDartPadUrl() {
    return 'https://dartpad.dev/?id=$id&theme=$theme&embed=$embed&run=$run';
  }

  static final schema = Block.schema.extend(
    {
      'id': Ok.string(),
      'theme': DartPadTheme.schema.nullable(),
      'embed': Ok.boolean(),
      'run': Ok.boolean(),
    },
    required: [
      "id",
    ],
  );
}

@MappableClass(discriminatorValue: ImageBlock.key)
class ImageBlock extends Block with ImageBlockMappable {
  static const key = 'image';
  final GeneratedAsset asset;
  final ImageFit? fit;
  final double? width;
  final double? height;
  ImageBlock({
    required this.asset,
    this.fit,
    this.width,
    this.height,
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key);

  static final schema = Block.schema.extend(
    {
      "fit": ImageFit.schema.nullable(),
      "asset": GeneratedAsset.schema(),
      "width": Ok.double.nullable(),
      "height": Ok.double.nullable(),
    },
    required: [
      "asset",
    ],
  );
}

@MappableEnum()
enum ImageFit {
  fill,
  contain,
  cover,
  fitWidth,
  fitHeight,
  none,
  scaleDown;

  static final schema = Ok.enumValues(values);
}

@MappableClass(
  discriminatorValue: WidgetBlock.key,
  hook: UnmappedPropertiesHook('args'),
)
class WidgetBlock extends Block with WidgetBlockMappable {
  static const key = 'widget';
  final Map<String, dynamic> args;
  final String name;
  @override
  WidgetBlock({
    required this.name,
    this.args = const {},
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key);

  static final schema = Block.schema.extend(
    {
      "name": Ok.string(),
    },
    required: [
      "name",
    ],
    additionalProperties: true,
  );
}

@MappableEnum()
enum ContentAlignment {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  static final schema = Ok.enumValues(values);
}

extension StringColumnExt on String {
  ColumnBlock column() => ColumnBlock(this);
}

extension BlockExt on Block {
  Block alignCenter() => copyWith(align: ContentAlignment.center);
  Block alignCenterLeft() => copyWith(align: ContentAlignment.centerLeft);
  Block alignCenterRight() => copyWith(align: ContentAlignment.centerRight);
  Block alignTopLeft() => copyWith(align: ContentAlignment.topLeft);
  Block alignTopCenter() => copyWith(align: ContentAlignment.topCenter);
  Block alignTopRight() => copyWith(align: ContentAlignment.topRight);
  Block alignBottomLeft() => copyWith(align: ContentAlignment.bottomLeft);
  Block alignBottomCenter() => copyWith(align: ContentAlignment.bottomCenter);
  Block alignBottomRight() => copyWith(align: ContentAlignment.bottomRight);

  Block flex(int flex) => copyWith(flex: flex);
  Block scrollable([bool scrollable = true]) =>
      copyWith(scrollable: scrollable);
}
