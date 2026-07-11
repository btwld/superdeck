// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'block_model.dart';

class DartPadThemeMapper extends EnumMapper<DartPadTheme> {
  DartPadThemeMapper._();

  static DartPadThemeMapper? _instance;
  static DartPadThemeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DartPadThemeMapper._());
    }
    return _instance!;
  }

  static DartPadTheme fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  DartPadTheme decode(dynamic value) {
    switch (value) {
      case r'dark':
        return DartPadTheme.dark;
      case r'light':
        return DartPadTheme.light;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(DartPadTheme self) {
    switch (self) {
      case DartPadTheme.dark:
        return r'dark';
      case DartPadTheme.light:
        return r'light';
    }
  }
}

extension DartPadThemeMapperExtension on DartPadTheme {
  String toValue() {
    DartPadThemeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<DartPadTheme>(this) as String;
  }
}

class ImageFitMapper extends EnumMapper<ImageFit> {
  ImageFitMapper._();

  static ImageFitMapper? _instance;
  static ImageFitMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ImageFitMapper._());
    }
    return _instance!;
  }

  static ImageFit fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ImageFit decode(dynamic value) {
    switch (value) {
      case r'fill':
        return ImageFit.fill;
      case r'contain':
        return ImageFit.contain;
      case r'cover':
        return ImageFit.cover;
      case r'fitWidth':
        return ImageFit.fitWidth;
      case r'fitHeight':
        return ImageFit.fitHeight;
      case r'none':
        return ImageFit.none;
      case r'scaleDown':
        return ImageFit.scaleDown;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ImageFit self) {
    switch (self) {
      case ImageFit.fill:
        return r'fill';
      case ImageFit.contain:
        return r'contain';
      case ImageFit.cover:
        return r'cover';
      case ImageFit.fitWidth:
        return r'fitWidth';
      case ImageFit.fitHeight:
        return r'fitHeight';
      case ImageFit.none:
        return r'none';
      case ImageFit.scaleDown:
        return r'scaleDown';
    }
  }
}

extension ImageFitMapperExtension on ImageFit {
  String toValue() {
    ImageFitMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ImageFit>(this) as String;
  }
}

class ContentAlignmentMapper extends EnumMapper<ContentAlignment> {
  ContentAlignmentMapper._();

  static ContentAlignmentMapper? _instance;
  static ContentAlignmentMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ContentAlignmentMapper._());
    }
    return _instance!;
  }

  static ContentAlignment fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ContentAlignment decode(dynamic value) {
    switch (value) {
      case r'topLeft':
        return ContentAlignment.topLeft;
      case r'topCenter':
        return ContentAlignment.topCenter;
      case r'topRight':
        return ContentAlignment.topRight;
      case r'centerLeft':
        return ContentAlignment.centerLeft;
      case r'center':
        return ContentAlignment.center;
      case r'centerRight':
        return ContentAlignment.centerRight;
      case r'bottomLeft':
        return ContentAlignment.bottomLeft;
      case r'bottomCenter':
        return ContentAlignment.bottomCenter;
      case r'bottomRight':
        return ContentAlignment.bottomRight;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ContentAlignment self) {
    switch (self) {
      case ContentAlignment.topLeft:
        return r'topLeft';
      case ContentAlignment.topCenter:
        return r'topCenter';
      case ContentAlignment.topRight:
        return r'topRight';
      case ContentAlignment.centerLeft:
        return r'centerLeft';
      case ContentAlignment.center:
        return r'center';
      case ContentAlignment.centerRight:
        return r'centerRight';
      case ContentAlignment.bottomLeft:
        return r'bottomLeft';
      case ContentAlignment.bottomCenter:
        return r'bottomCenter';
      case ContentAlignment.bottomRight:
        return r'bottomRight';
    }
  }
}

extension ContentAlignmentMapperExtension on ContentAlignment {
  String toValue() {
    ContentAlignmentMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ContentAlignment>(this) as String;
  }
}

class BlockMapper extends ClassMapperBase<Block> {
  BlockMapper._();

  static BlockMapper? _instance;
  static BlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BlockMapper._());
      ContentBlockMapper.ensureInitialized();
      WidgetBlockMapper.ensureInitialized();
      ContentAlignmentMapper.ensureInitialized();
      BlockInsetsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Block';

  static String _$type(Block v) => v.type;
  static const Field<Block, String> _f$type = Field('type', _$type);
  static ContentAlignment? _$align(Block v) => v.align;
  static const Field<Block, ContentAlignment> _f$align = Field(
    'align',
    _$align,
    opt: true,
  );
  static int _$flex(Block v) => v.flex;
  static const Field<Block, int> _f$flex = Field(
    'flex',
    _$flex,
    opt: true,
    def: 1,
  );
  static BlockInsets? _$padding(Block v) => v.padding;
  static const Field<Block, BlockInsets> _f$padding = Field(
    'padding',
    _$padding,
    opt: true,
  );
  static bool _$scrollable(Block v) => v.scrollable;
  static const Field<Block, bool> _f$scrollable = Field(
    'scrollable',
    _$scrollable,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<Block> fields = const {
    #type: _f$type,
    #align: _f$align,
    #flex: _f$flex,
    #padding: _f$padding,
    #scrollable: _f$scrollable,
  };
  @override
  final bool ignoreNull = true;

  static Block _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'Block',
      'type',
      '${data.value['type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Block fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Block>(map);
  }

  static Block fromJson(String json) {
    return ensureInitialized().decodeJson<Block>(json);
  }
}

mixin BlockMappable {
  String toJson();
  Map<String, dynamic> toMap();
  BlockCopyWith<Block, Block, Block> get copyWith;
}

abstract class BlockCopyWith<$R, $In extends Block, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  BlockInsetsCopyWith<$R, BlockInsets, BlockInsets>? get padding;
  $R call({
    ContentAlignment? align,
    int? flex,
    BlockInsets? padding,
    bool? scrollable,
  });
  BlockCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class SectionBlockMapper extends ClassMapperBase<SectionBlock> {
  SectionBlockMapper._();

  static SectionBlockMapper? _instance;
  static SectionBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SectionBlockMapper._());
      BlockMapper.ensureInitialized();
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SectionBlock';

  static List<Block> _$blocks(SectionBlock v) => v.blocks;
  static const Field<SectionBlock, List<Block>> _f$blocks = Field(
    'blocks',
    _$blocks,
  );
  static ContentAlignment? _$align(SectionBlock v) => v.align;
  static const Field<SectionBlock, ContentAlignment> _f$align = Field(
    'align',
    _$align,
    opt: true,
  );
  static int _$flex(SectionBlock v) => v.flex;
  static const Field<SectionBlock, int> _f$flex = Field(
    'flex',
    _$flex,
    opt: true,
    def: 1,
  );
  static double _$spacing(SectionBlock v) => v.spacing;
  static const Field<SectionBlock, double> _f$spacing = Field(
    'spacing',
    _$spacing,
    opt: true,
    def: 0,
  );
  static String _$type(SectionBlock v) => v.type;
  static const Field<SectionBlock, String> _f$type = Field(
    'type',
    _$type,
    opt: true,
    def: SectionBlock.key,
  );

  @override
  final MappableFields<SectionBlock> fields = const {
    #blocks: _f$blocks,
    #align: _f$align,
    #flex: _f$flex,
    #spacing: _f$spacing,
    #type: _f$type,
  };
  @override
  final bool ignoreNull = true;

  static SectionBlock _instantiate(DecodingData data) {
    return SectionBlock(
      data.dec(_f$blocks),
      align: data.dec(_f$align),
      flex: data.dec(_f$flex),
      spacing: data.dec(_f$spacing),
      type: data.dec(_f$type),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SectionBlock fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SectionBlock>(map);
  }

  static SectionBlock fromJson(String json) {
    return ensureInitialized().decodeJson<SectionBlock>(json);
  }
}

mixin SectionBlockMappable {
  String toJson() {
    return SectionBlockMapper.ensureInitialized().encodeJson<SectionBlock>(
      this as SectionBlock,
    );
  }

  Map<String, dynamic> toMap() {
    return SectionBlockMapper.ensureInitialized().encodeMap<SectionBlock>(
      this as SectionBlock,
    );
  }

  SectionBlockCopyWith<SectionBlock, SectionBlock, SectionBlock> get copyWith =>
      _SectionBlockCopyWithImpl<SectionBlock, SectionBlock>(
        this as SectionBlock,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SectionBlockMapper.ensureInitialized().stringifyValue(
      this as SectionBlock,
    );
  }

  @override
  bool operator ==(Object other) {
    return SectionBlockMapper.ensureInitialized().equalsValue(
      this as SectionBlock,
      other,
    );
  }

  @override
  int get hashCode {
    return SectionBlockMapper.ensureInitialized().hashValue(
      this as SectionBlock,
    );
  }
}

extension SectionBlockValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SectionBlock, $Out> {
  SectionBlockCopyWith<$R, SectionBlock, $Out> get $asSectionBlock =>
      $base.as((v, t, t2) => _SectionBlockCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SectionBlockCopyWith<$R, $In extends SectionBlock, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Block, BlockCopyWith<$R, Block, Block>> get blocks;
  $R call({
    List<Block>? blocks,
    ContentAlignment? align,
    int? flex,
    double? spacing,
    String? type,
  });
  SectionBlockCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SectionBlockCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SectionBlock, $Out>
    implements SectionBlockCopyWith<$R, SectionBlock, $Out> {
  _SectionBlockCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SectionBlock> $mapper =
      SectionBlockMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Block, BlockCopyWith<$R, Block, Block>> get blocks =>
      ListCopyWith(
        $value.blocks,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(blocks: v),
      );
  @override
  $R call({
    Object? blocks = $none,
    Object? align = $none,
    int? flex,
    double? spacing,
    String? type,
  }) => $apply(
    FieldCopyWithData({
      if (blocks != $none) #blocks: blocks,
      if (align != $none) #align: align,
      if (flex != null) #flex: flex,
      if (spacing != null) #spacing: spacing,
      if (type != null) #type: type,
    }),
  );
  @override
  SectionBlock $make(CopyWithData data) => SectionBlock(
    data.get(#blocks, or: $value.blocks),
    align: data.get(#align, or: $value.align),
    flex: data.get(#flex, or: $value.flex),
    spacing: data.get(#spacing, or: $value.spacing),
    type: data.get(#type, or: $value.type),
  );

  @override
  SectionBlockCopyWith<$R2, SectionBlock, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SectionBlockCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ContentBlockMapper extends SubClassMapperBase<ContentBlock> {
  ContentBlockMapper._();

  static ContentBlockMapper? _instance;
  static ContentBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ContentBlockMapper._());
      BlockMapper.ensureInitialized().addSubMapper(_instance!);
      ContentAlignmentMapper.ensureInitialized();
      BlockInsetsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ContentBlock';

  static String _$content(ContentBlock v) => v.content;
  static const Field<ContentBlock, String> _f$content = Field(
    'content',
    _$content,
  );
  static ContentAlignment? _$align(ContentBlock v) => v.align;
  static const Field<ContentBlock, ContentAlignment> _f$align = Field(
    'align',
    _$align,
    opt: true,
  );
  static int _$flex(ContentBlock v) => v.flex;
  static const Field<ContentBlock, int> _f$flex = Field(
    'flex',
    _$flex,
    opt: true,
    def: 1,
  );
  static BlockInsets? _$padding(ContentBlock v) => v.padding;
  static const Field<ContentBlock, BlockInsets> _f$padding = Field(
    'padding',
    _$padding,
    opt: true,
  );
  static bool _$scrollable(ContentBlock v) => v.scrollable;
  static const Field<ContentBlock, bool> _f$scrollable = Field(
    'scrollable',
    _$scrollable,
    opt: true,
    def: false,
  );
  static String _$type(ContentBlock v) => v.type;
  static const Field<ContentBlock, String> _f$type = Field(
    'type',
    _$type,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<ContentBlock> fields = const {
    #content: _f$content,
    #align: _f$align,
    #flex: _f$flex,
    #padding: _f$padding,
    #scrollable: _f$scrollable,
    #type: _f$type,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = ContentBlock.key;
  @override
  late final ClassMapperBase superMapper = BlockMapper.ensureInitialized();

  static ContentBlock _instantiate(DecodingData data) {
    return ContentBlock(
      data.dec(_f$content),
      align: data.dec(_f$align),
      flex: data.dec(_f$flex),
      padding: data.dec(_f$padding),
      scrollable: data.dec(_f$scrollable),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ContentBlock fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ContentBlock>(map);
  }

  static ContentBlock fromJson(String json) {
    return ensureInitialized().decodeJson<ContentBlock>(json);
  }
}

mixin ContentBlockMappable {
  String toJson() {
    return ContentBlockMapper.ensureInitialized().encodeJson<ContentBlock>(
      this as ContentBlock,
    );
  }

  Map<String, dynamic> toMap() {
    return ContentBlockMapper.ensureInitialized().encodeMap<ContentBlock>(
      this as ContentBlock,
    );
  }

  ContentBlockCopyWith<ContentBlock, ContentBlock, ContentBlock> get copyWith =>
      _ContentBlockCopyWithImpl<ContentBlock, ContentBlock>(
        this as ContentBlock,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ContentBlockMapper.ensureInitialized().stringifyValue(
      this as ContentBlock,
    );
  }

  @override
  bool operator ==(Object other) {
    return ContentBlockMapper.ensureInitialized().equalsValue(
      this as ContentBlock,
      other,
    );
  }

  @override
  int get hashCode {
    return ContentBlockMapper.ensureInitialized().hashValue(
      this as ContentBlock,
    );
  }
}

extension ContentBlockValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ContentBlock, $Out> {
  ContentBlockCopyWith<$R, ContentBlock, $Out> get $asContentBlock =>
      $base.as((v, t, t2) => _ContentBlockCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ContentBlockCopyWith<$R, $In extends ContentBlock, $Out>
    implements BlockCopyWith<$R, $In, $Out> {
  @override
  BlockInsetsCopyWith<$R, BlockInsets, BlockInsets>? get padding;
  @override
  $R call({
    String? content,
    ContentAlignment? align,
    int? flex,
    BlockInsets? padding,
    bool? scrollable,
  });
  ContentBlockCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ContentBlockCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ContentBlock, $Out>
    implements ContentBlockCopyWith<$R, ContentBlock, $Out> {
  _ContentBlockCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ContentBlock> $mapper =
      ContentBlockMapper.ensureInitialized();
  @override
  BlockInsetsCopyWith<$R, BlockInsets, BlockInsets>? get padding =>
      $value.padding?.copyWith.$chain((v) => call(padding: v));
  @override
  $R call({
    Object? content = $none,
    Object? align = $none,
    int? flex,
    Object? padding = $none,
    bool? scrollable,
  }) => $apply(
    FieldCopyWithData({
      if (content != $none) #content: content,
      if (align != $none) #align: align,
      if (flex != null) #flex: flex,
      if (padding != $none) #padding: padding,
      if (scrollable != null) #scrollable: scrollable,
    }),
  );
  @override
  ContentBlock $make(CopyWithData data) => ContentBlock(
    data.get(#content, or: $value.content),
    align: data.get(#align, or: $value.align),
    flex: data.get(#flex, or: $value.flex),
    padding: data.get(#padding, or: $value.padding),
    scrollable: data.get(#scrollable, or: $value.scrollable),
  );

  @override
  ContentBlockCopyWith<$R2, ContentBlock, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ContentBlockCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class WidgetBlockMapper extends SubClassMapperBase<WidgetBlock> {
  WidgetBlockMapper._();

  static WidgetBlockMapper? _instance;
  static WidgetBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WidgetBlockMapper._());
      BlockMapper.ensureInitialized().addSubMapper(_instance!);
      ContentAlignmentMapper.ensureInitialized();
      BlockInsetsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WidgetBlock';

  static String _$name(WidgetBlock v) => v.name;
  static const Field<WidgetBlock, String> _f$name = Field('name', _$name);
  static Map<String, Object?> _$args(WidgetBlock v) => v.args;
  static const Field<WidgetBlock, Map<String, Object?>> _f$args = Field(
    'args',
    _$args,
    opt: true,
  );
  static ContentAlignment? _$align(WidgetBlock v) => v.align;
  static const Field<WidgetBlock, ContentAlignment> _f$align = Field(
    'align',
    _$align,
    opt: true,
  );
  static int _$flex(WidgetBlock v) => v.flex;
  static const Field<WidgetBlock, int> _f$flex = Field(
    'flex',
    _$flex,
    opt: true,
    def: 1,
  );
  static BlockInsets? _$padding(WidgetBlock v) => v.padding;
  static const Field<WidgetBlock, BlockInsets> _f$padding = Field(
    'padding',
    _$padding,
    opt: true,
  );
  static bool _$scrollable(WidgetBlock v) => v.scrollable;
  static const Field<WidgetBlock, bool> _f$scrollable = Field(
    'scrollable',
    _$scrollable,
    opt: true,
    def: false,
  );
  static String _$type(WidgetBlock v) => v.type;
  static const Field<WidgetBlock, String> _f$type = Field(
    'type',
    _$type,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<WidgetBlock> fields = const {
    #name: _f$name,
    #args: _f$args,
    #align: _f$align,
    #flex: _f$flex,
    #padding: _f$padding,
    #scrollable: _f$scrollable,
    #type: _f$type,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = WidgetBlock.key;
  @override
  late final ClassMapperBase superMapper = BlockMapper.ensureInitialized();

  @override
  final MappingHook hook = const UnmappedPropertiesHook('args');
  static WidgetBlock _instantiate(DecodingData data) {
    return WidgetBlock(
      name: data.dec(_f$name),
      args: data.dec(_f$args),
      align: data.dec(_f$align),
      flex: data.dec(_f$flex),
      padding: data.dec(_f$padding),
      scrollable: data.dec(_f$scrollable),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static WidgetBlock fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WidgetBlock>(map);
  }

  static WidgetBlock fromJson(String json) {
    return ensureInitialized().decodeJson<WidgetBlock>(json);
  }
}

mixin WidgetBlockMappable {
  String toJson() {
    return WidgetBlockMapper.ensureInitialized().encodeJson<WidgetBlock>(
      this as WidgetBlock,
    );
  }

  Map<String, dynamic> toMap() {
    return WidgetBlockMapper.ensureInitialized().encodeMap<WidgetBlock>(
      this as WidgetBlock,
    );
  }

  WidgetBlockCopyWith<WidgetBlock, WidgetBlock, WidgetBlock> get copyWith =>
      _WidgetBlockCopyWithImpl<WidgetBlock, WidgetBlock>(
        this as WidgetBlock,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return WidgetBlockMapper.ensureInitialized().stringifyValue(
      this as WidgetBlock,
    );
  }

  @override
  bool operator ==(Object other) {
    return WidgetBlockMapper.ensureInitialized().equalsValue(
      this as WidgetBlock,
      other,
    );
  }

  @override
  int get hashCode {
    return WidgetBlockMapper.ensureInitialized().hashValue(this as WidgetBlock);
  }
}

extension WidgetBlockValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WidgetBlock, $Out> {
  WidgetBlockCopyWith<$R, WidgetBlock, $Out> get $asWidgetBlock =>
      $base.as((v, t, t2) => _WidgetBlockCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WidgetBlockCopyWith<$R, $In extends WidgetBlock, $Out>
    implements BlockCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, Object?, ObjectCopyWith<$R, Object?, Object?>?>
  get args;
  @override
  BlockInsetsCopyWith<$R, BlockInsets, BlockInsets>? get padding;
  @override
  $R call({
    String? name,
    Map<String, Object?>? args,
    ContentAlignment? align,
    int? flex,
    BlockInsets? padding,
    bool? scrollable,
  });
  WidgetBlockCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _WidgetBlockCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WidgetBlock, $Out>
    implements WidgetBlockCopyWith<$R, WidgetBlock, $Out> {
  _WidgetBlockCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WidgetBlock> $mapper =
      WidgetBlockMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, Object?, ObjectCopyWith<$R, Object?, Object?>?>
  get args => MapCopyWith(
    $value.args,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(args: v),
  );
  @override
  BlockInsetsCopyWith<$R, BlockInsets, BlockInsets>? get padding =>
      $value.padding?.copyWith.$chain((v) => call(padding: v));
  @override
  $R call({
    String? name,
    Object? args = $none,
    Object? align = $none,
    int? flex,
    Object? padding = $none,
    bool? scrollable,
  }) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (args != $none) #args: args,
      if (align != $none) #align: align,
      if (flex != null) #flex: flex,
      if (padding != $none) #padding: padding,
      if (scrollable != null) #scrollable: scrollable,
    }),
  );
  @override
  WidgetBlock $make(CopyWithData data) => WidgetBlock(
    name: data.get(#name, or: $value.name),
    args: data.get(#args, or: $value.args),
    align: data.get(#align, or: $value.align),
    flex: data.get(#flex, or: $value.flex),
    padding: data.get(#padding, or: $value.padding),
    scrollable: data.get(#scrollable, or: $value.scrollable),
  );

  @override
  WidgetBlockCopyWith<$R2, WidgetBlock, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _WidgetBlockCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

