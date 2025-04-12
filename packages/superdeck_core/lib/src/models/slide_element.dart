import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../helpers/mappers.dart';

part 'slide_element.mapper.dart';

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

  static final schema = ackEnum(values);
}

@MappableClass(
  discriminatorKey: 'type',
)
sealed class SlideElement with SlideElementMappable {
  final String type;
  final ContentAlignment? align;
  final int? flex;
  final bool? scrollable;
  SlideElement({
    required this.type,
    this.align,
    this.flex,
    this.scrollable,
  });

  static final schema = Ack.object(
    {
      'type': Ack.string,
      'align': ContentAlignment.schema.nullable(),
      'flex': Ack.int.nullable(),
      'scrollable': Ack.boolean.nullable(),
    },
    required: [
      "type",
    ],
  );

  static SlideElement parse(Map<String, dynamic> map) {
    schema.validateOrThrow(map);
    return SlideElementMapper.fromMap(map);
  }

  static final DiscriminatedObjectSchema discriminatedSchema =
      Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      MarkdownElement.key: MarkdownElement.schema,
      DartPadBlock.key: DartPadBlock.schema,
      CustomElement.key: CustomElement.schema,
      ImageElement.key: ImageElement.schema,
    },
  );
}

@MappableClass(
  includeCustomMappers: [NullIfEmptyBlock()],
  discriminatorValue: SlideSection.key,
)
class SlideSection extends SlideElement with SlideSectionMappable {
  late final List<SlideElement> blocks;

  static const key = 'section';

  SlideSection(
    List<SlideElement>? blocks, {
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key) {
    this.blocks = blocks ?? [];
  }

  int get totalBlockFlex {
    return blocks.fold(0, (total, block) => total + (block.flex ?? 1));
  }

  static SlideSection parse(Map<String, dynamic> map) {
    schema.validateOrThrow(map);
    return SlideSectionMapper.fromMap(map);
  }

  static SlideSection text(String content) {
    return SlideSection([MarkdownElement(content)]);
  }

  static final schema = SlideElement.schema.extend(
    {
      'blocks': SlideElement.discriminatedSchema.list.nullable(),
    },
  );
}

@MappableClass(discriminatorValue: MarkdownElement.key)
class MarkdownElement extends SlideElement with MarkdownElementMappable {
  static const key = 'column';
  late final String content;
  MarkdownElement(
    String? content, {
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key) {
    this.content = content ?? '';
  }

  static final schema = SlideElement.schema.extend(
    {
      'content': Ack.string,
    },
    required: [
      "content",
    ],
  );
}

@MappableEnum()
enum DartPadTheme {
  // Using camelCase for enum values
  darkMode,
  lightMode;

  static final schema = ackEnum(values);
}

@MappableClass(discriminatorValue: DartPadBlock.key)
class DartPadBlock extends SlideElement with DartPadBlockMappable {
  final String id;
  final DartPadTheme? theme;
  final bool? embed;
  final bool? run;

  static const key = 'dartpad';

  DartPadBlock({
    required this.id,
    this.theme,
    this.embed,
    this.run,
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key);

  String getDartPadUrl() {
    return 'https://dartpad.dev/?id=$id&theme=$theme&embed=$embed&run=$run';
  }

  static final schema = SlideElement.schema.extend(
    {
      'id': Ack.string,
      'theme': DartPadTheme.schema.nullable(),
      'embed': Ack.boolean.nullable(),
      'run': Ack.boolean.nullable(),
    },
    required: [
      "id",
    ],
  );
}

@MappableClass(discriminatorValue: ImageElement.key)
class ImageElement extends SlideElement with ImageElementMappable {
  static const key = 'image';
  final Asset asset;
  final ImageFit? fit;
  final double? width;
  final double? height;
  ImageElement({
    required this.asset,
    this.fit,
    this.width,
    this.height,
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key);

  static final schema = SlideElement.schema.extend(
    {
      "fit": ImageFit.schema.nullable(),
      "asset": Asset.schema,
      "width": Ack.double.nullable(),
      "height": Ack.double.nullable(),
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

  static final schema = ackEnum(values);
}

@MappableClass(
  discriminatorValue: CustomElement.key,
  hook: UnmappedPropertiesHook('props'),
)
class CustomElement extends SlideElement with CustomElementMappable {
  static const key = 'widget';
  final String id;
  final Map<String, dynamic>? props;
  CustomElement({
    required this.id,
    this.props,
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key);

  static final schema = SlideElement.schema.extend(
    {
      'id': Ack.string,
    },
    required: [
      'id',
    ],
    additionalProperties: true,
  );
}

extension SlideElementExt on SlideElement {
  bool get isSection => this is SlideSection;
  bool get isMarkdown => this is MarkdownElement;
  bool get isImage => this is ImageElement;
  bool get isDartPad => this is DartPadBlock;
  bool get isCustom => this is CustomElement;

  T cast<T extends SlideElement>() => this as T;

  SlideSection get asSection => cast<SlideSection>();
  MarkdownElement get asMarkdown => cast<MarkdownElement>();
  ImageElement get asImage => cast<ImageElement>();
  DartPadBlock get asDartPad => cast<DartPadBlock>();
  CustomElement get asCustom => cast<CustomElement>();

  Map<String, dynamic> toMap() {
    return SlideElementMapper.ensureInitialized().encodeMap(this);
  }

  // Alignment helper methods
  SlideElement alignTopLeft() => copyWith(align: ContentAlignment.topLeft);
  SlideElement alignTopCenter() => copyWith(align: ContentAlignment.topCenter);
  SlideElement alignTopRight() => copyWith(align: ContentAlignment.topRight);
  SlideElement alignCenterLeft() =>
      copyWith(align: ContentAlignment.centerLeft);
  SlideElement alignCenter() => copyWith(align: ContentAlignment.center);
  SlideElement alignCenterRight() =>
      copyWith(align: ContentAlignment.centerRight);
  SlideElement alignBottomLeft() =>
      copyWith(align: ContentAlignment.bottomLeft);
  SlideElement alignBottomCenter() =>
      copyWith(align: ContentAlignment.bottomCenter);
  SlideElement alignBottomRight() =>
      copyWith(align: ContentAlignment.bottomRight);
}

extension StringMarkdownExt on String {
  MarkdownElement markdown({
    ContentAlignment? align,
    int? flex,
    bool? scrollable,
  }) {
    return MarkdownElement(
      this,
      align: align,
      flex: flex,
      scrollable: scrollable,
    );
  }
}

// Temporary backward compatibility aliases
typedef Block = SlideElement;
typedef SectionBlock = SlideSection;
typedef ColumnBlock = MarkdownElement;
typedef ImageBlock = ImageElement;
typedef WidgetBlock = CustomElement;
