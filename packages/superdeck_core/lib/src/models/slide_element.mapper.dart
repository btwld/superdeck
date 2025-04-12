// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'slide_element.dart';

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
      case 'top_left':
        return ContentAlignment.topLeft;
      case 'top_center':
        return ContentAlignment.topCenter;
      case 'top_right':
        return ContentAlignment.topRight;
      case 'center_left':
        return ContentAlignment.centerLeft;
      case 'center':
        return ContentAlignment.center;
      case 'center_right':
        return ContentAlignment.centerRight;
      case 'bottom_left':
        return ContentAlignment.bottomLeft;
      case 'bottom_center':
        return ContentAlignment.bottomCenter;
      case 'bottom_right':
        return ContentAlignment.bottomRight;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ContentAlignment self) {
    switch (self) {
      case ContentAlignment.topLeft:
        return 'top_left';
      case ContentAlignment.topCenter:
        return 'top_center';
      case ContentAlignment.topRight:
        return 'top_right';
      case ContentAlignment.centerLeft:
        return 'center_left';
      case ContentAlignment.center:
        return 'center';
      case ContentAlignment.centerRight:
        return 'center_right';
      case ContentAlignment.bottomLeft:
        return 'bottom_left';
      case ContentAlignment.bottomCenter:
        return 'bottom_center';
      case ContentAlignment.bottomRight:
        return 'bottom_right';
    }
  }
}

extension ContentAlignmentMapperExtension on ContentAlignment {
  String toValue() {
    ContentAlignmentMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ContentAlignment>(this) as String;
  }
}

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
      case 'dark_mode':
        return DartPadTheme.darkMode;
      case 'light_mode':
        return DartPadTheme.lightMode;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(DartPadTheme self) {
    switch (self) {
      case DartPadTheme.darkMode:
        return 'dark_mode';
      case DartPadTheme.lightMode:
        return 'light_mode';
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
      case 'fill':
        return ImageFit.fill;
      case 'contain':
        return ImageFit.contain;
      case 'cover':
        return ImageFit.cover;
      case 'fit_width':
        return ImageFit.fitWidth;
      case 'fit_height':
        return ImageFit.fitHeight;
      case 'none':
        return ImageFit.none;
      case 'scale_down':
        return ImageFit.scaleDown;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ImageFit self) {
    switch (self) {
      case ImageFit.fill:
        return 'fill';
      case ImageFit.contain:
        return 'contain';
      case ImageFit.cover:
        return 'cover';
      case ImageFit.fitWidth:
        return 'fit_width';
      case ImageFit.fitHeight:
        return 'fit_height';
      case ImageFit.none:
        return 'none';
      case ImageFit.scaleDown:
        return 'scale_down';
    }
  }
}

extension ImageFitMapperExtension on ImageFit {
  String toValue() {
    ImageFitMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ImageFit>(this) as String;
  }
}

class SlideElementMapper extends ClassMapperBase<SlideElement> {
  SlideElementMapper._();

  static SlideElementMapper? _instance;
  static SlideElementMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SlideElementMapper._());
      SlideSectionMapper.ensureInitialized();
      MarkdownElementMapper.ensureInitialized();
      DartPadBlockMapper.ensureInitialized();
      ImageElementMapper.ensureInitialized();
      CustomElementMapper.ensureInitialized();
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SlideElement';

  static String _$type(SlideElement v) => v.type;
  static const Field<SlideElement, String> _f$type = Field('type', _$type);
  static ContentAlignment? _$align(SlideElement v) => v.align;
  static const Field<SlideElement, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(SlideElement v) => v.flex;
  static const Field<SlideElement, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(SlideElement v) => v.scrollable;
  static const Field<SlideElement, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);

  @override
  final MappableFields<SlideElement> fields = const {
    #type: _f$type,
    #align: _f$align,
    #flex: _f$flex,
    #scrollable: _f$scrollable,
  };
  @override
  final bool ignoreNull = true;

  static SlideElement _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
        'SlideElement', 'type', '${data.value['type']}');
  }

  @override
  final Function instantiate = _instantiate;

  static SlideElement fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SlideElement>(map);
  }

  static SlideElement fromJson(String json) {
    return ensureInitialized().decodeJson<SlideElement>(json);
  }
}

mixin SlideElementMappable {
  String toJson();
  Map<String, dynamic> toMap();
  SlideElementCopyWith<SlideElement, SlideElement, SlideElement> get copyWith;
}

abstract class SlideElementCopyWith<$R, $In extends SlideElement, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({ContentAlignment? align, int? flex, bool? scrollable});
  SlideElementCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class SlideSectionMapper extends SubClassMapperBase<SlideSection> {
  SlideSectionMapper._();

  static SlideSectionMapper? _instance;
  static SlideSectionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SlideSectionMapper._());
      SlideElementMapper.ensureInitialized().addSubMapper(_instance!);
      MapperContainer.globals.useAll([NullIfEmptyBlock()]);
      SlideElementMapper.ensureInitialized();
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SlideSection';

  static List<SlideElement> _$blocks(SlideSection v) => v.blocks;
  static const Field<SlideSection, List<SlideElement>> _f$blocks =
      Field('blocks', _$blocks);
  static ContentAlignment? _$align(SlideSection v) => v.align;
  static const Field<SlideSection, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(SlideSection v) => v.flex;
  static const Field<SlideSection, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(SlideSection v) => v.scrollable;
  static const Field<SlideSection, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);
  static String _$type(SlideSection v) => v.type;
  static const Field<SlideSection, String> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<SlideSection> fields = const {
    #blocks: _f$blocks,
    #align: _f$align,
    #flex: _f$flex,
    #scrollable: _f$scrollable,
    #type: _f$type,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = SlideSection.key;
  @override
  late final ClassMapperBase superMapper =
      SlideElementMapper.ensureInitialized();

  static SlideSection _instantiate(DecodingData data) {
    return SlideSection(data.dec(_f$blocks),
        align: data.dec(_f$align),
        flex: data.dec(_f$flex),
        scrollable: data.dec(_f$scrollable));
  }

  @override
  final Function instantiate = _instantiate;

  static SlideSection fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SlideSection>(map);
  }

  static SlideSection fromJson(String json) {
    return ensureInitialized().decodeJson<SlideSection>(json);
  }
}

mixin SlideSectionMappable {
  String toJson() {
    return SlideSectionMapper.ensureInitialized()
        .encodeJson<SlideSection>(this as SlideSection);
  }

  Map<String, dynamic> toMap() {
    return SlideSectionMapper.ensureInitialized()
        .encodeMap<SlideSection>(this as SlideSection);
  }

  SlideSectionCopyWith<SlideSection, SlideSection, SlideSection> get copyWith =>
      _SlideSectionCopyWithImpl(this as SlideSection, $identity, $identity);
  @override
  String toString() {
    return SlideSectionMapper.ensureInitialized()
        .stringifyValue(this as SlideSection);
  }

  @override
  bool operator ==(Object other) {
    return SlideSectionMapper.ensureInitialized()
        .equalsValue(this as SlideSection, other);
  }

  @override
  int get hashCode {
    return SlideSectionMapper.ensureInitialized()
        .hashValue(this as SlideSection);
  }
}

extension SlideSectionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SlideSection, $Out> {
  SlideSectionCopyWith<$R, SlideSection, $Out> get $asSlideSection =>
      $base.as((v, t, t2) => _SlideSectionCopyWithImpl(v, t, t2));
}

abstract class SlideSectionCopyWith<$R, $In extends SlideSection, $Out>
    implements SlideElementCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, SlideElement,
      SlideElementCopyWith<$R, SlideElement, SlideElement>> get blocks;
  @override
  $R call(
      {List<SlideElement>? blocks,
      ContentAlignment? align,
      int? flex,
      bool? scrollable});
  SlideSectionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SlideSectionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SlideSection, $Out>
    implements SlideSectionCopyWith<$R, SlideSection, $Out> {
  _SlideSectionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SlideSection> $mapper =
      SlideSectionMapper.ensureInitialized();
  @override
  ListCopyWith<$R, SlideElement,
          SlideElementCopyWith<$R, SlideElement, SlideElement>>
      get blocks => ListCopyWith($value.blocks, (v, t) => v.copyWith.$chain(t),
          (v) => call(blocks: v));
  @override
  $R call(
          {Object? blocks = $none,
          Object? align = $none,
          Object? flex = $none,
          Object? scrollable = $none}) =>
      $apply(FieldCopyWithData({
        if (blocks != $none) #blocks: blocks,
        if (align != $none) #align: align,
        if (flex != $none) #flex: flex,
        if (scrollable != $none) #scrollable: scrollable
      }));
  @override
  SlideSection $make(CopyWithData data) =>
      SlideSection(data.get(#blocks, or: $value.blocks),
          align: data.get(#align, or: $value.align),
          flex: data.get(#flex, or: $value.flex),
          scrollable: data.get(#scrollable, or: $value.scrollable));

  @override
  SlideSectionCopyWith<$R2, SlideSection, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _SlideSectionCopyWithImpl($value, $cast, t);
}

class MarkdownElementMapper extends SubClassMapperBase<MarkdownElement> {
  MarkdownElementMapper._();

  static MarkdownElementMapper? _instance;
  static MarkdownElementMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MarkdownElementMapper._());
      SlideElementMapper.ensureInitialized().addSubMapper(_instance!);
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'MarkdownElement';

  static String _$content(MarkdownElement v) => v.content;
  static const Field<MarkdownElement, String> _f$content =
      Field('content', _$content);
  static ContentAlignment? _$align(MarkdownElement v) => v.align;
  static const Field<MarkdownElement, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(MarkdownElement v) => v.flex;
  static const Field<MarkdownElement, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(MarkdownElement v) => v.scrollable;
  static const Field<MarkdownElement, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);
  static String _$type(MarkdownElement v) => v.type;
  static const Field<MarkdownElement, String> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<MarkdownElement> fields = const {
    #content: _f$content,
    #align: _f$align,
    #flex: _f$flex,
    #scrollable: _f$scrollable,
    #type: _f$type,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = MarkdownElement.key;
  @override
  late final ClassMapperBase superMapper =
      SlideElementMapper.ensureInitialized();

  static MarkdownElement _instantiate(DecodingData data) {
    return MarkdownElement(data.dec(_f$content),
        align: data.dec(_f$align),
        flex: data.dec(_f$flex),
        scrollable: data.dec(_f$scrollable));
  }

  @override
  final Function instantiate = _instantiate;

  static MarkdownElement fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MarkdownElement>(map);
  }

  static MarkdownElement fromJson(String json) {
    return ensureInitialized().decodeJson<MarkdownElement>(json);
  }
}

mixin MarkdownElementMappable {
  String toJson() {
    return MarkdownElementMapper.ensureInitialized()
        .encodeJson<MarkdownElement>(this as MarkdownElement);
  }

  Map<String, dynamic> toMap() {
    return MarkdownElementMapper.ensureInitialized()
        .encodeMap<MarkdownElement>(this as MarkdownElement);
  }

  MarkdownElementCopyWith<MarkdownElement, MarkdownElement, MarkdownElement>
      get copyWith => _MarkdownElementCopyWithImpl(
          this as MarkdownElement, $identity, $identity);
  @override
  String toString() {
    return MarkdownElementMapper.ensureInitialized()
        .stringifyValue(this as MarkdownElement);
  }

  @override
  bool operator ==(Object other) {
    return MarkdownElementMapper.ensureInitialized()
        .equalsValue(this as MarkdownElement, other);
  }

  @override
  int get hashCode {
    return MarkdownElementMapper.ensureInitialized()
        .hashValue(this as MarkdownElement);
  }
}

extension MarkdownElementValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MarkdownElement, $Out> {
  MarkdownElementCopyWith<$R, MarkdownElement, $Out> get $asMarkdownElement =>
      $base.as((v, t, t2) => _MarkdownElementCopyWithImpl(v, t, t2));
}

abstract class MarkdownElementCopyWith<$R, $In extends MarkdownElement, $Out>
    implements SlideElementCopyWith<$R, $In, $Out> {
  @override
  $R call(
      {String? content, ContentAlignment? align, int? flex, bool? scrollable});
  MarkdownElementCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _MarkdownElementCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MarkdownElement, $Out>
    implements MarkdownElementCopyWith<$R, MarkdownElement, $Out> {
  _MarkdownElementCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MarkdownElement> $mapper =
      MarkdownElementMapper.ensureInitialized();
  @override
  $R call(
          {Object? content = $none,
          Object? align = $none,
          Object? flex = $none,
          Object? scrollable = $none}) =>
      $apply(FieldCopyWithData({
        if (content != $none) #content: content,
        if (align != $none) #align: align,
        if (flex != $none) #flex: flex,
        if (scrollable != $none) #scrollable: scrollable
      }));
  @override
  MarkdownElement $make(CopyWithData data) =>
      MarkdownElement(data.get(#content, or: $value.content),
          align: data.get(#align, or: $value.align),
          flex: data.get(#flex, or: $value.flex),
          scrollable: data.get(#scrollable, or: $value.scrollable));

  @override
  MarkdownElementCopyWith<$R2, MarkdownElement, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _MarkdownElementCopyWithImpl($value, $cast, t);
}

class DartPadBlockMapper extends SubClassMapperBase<DartPadBlock> {
  DartPadBlockMapper._();

  static DartPadBlockMapper? _instance;
  static DartPadBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DartPadBlockMapper._());
      SlideElementMapper.ensureInitialized().addSubMapper(_instance!);
      DartPadThemeMapper.ensureInitialized();
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'DartPadBlock';

  static String _$id(DartPadBlock v) => v.id;
  static const Field<DartPadBlock, String> _f$id = Field('id', _$id);
  static DartPadTheme? _$theme(DartPadBlock v) => v.theme;
  static const Field<DartPadBlock, DartPadTheme> _f$theme =
      Field('theme', _$theme, opt: true);
  static bool? _$embed(DartPadBlock v) => v.embed;
  static const Field<DartPadBlock, bool> _f$embed =
      Field('embed', _$embed, opt: true);
  static bool? _$run(DartPadBlock v) => v.run;
  static const Field<DartPadBlock, bool> _f$run =
      Field('run', _$run, opt: true);
  static ContentAlignment? _$align(DartPadBlock v) => v.align;
  static const Field<DartPadBlock, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(DartPadBlock v) => v.flex;
  static const Field<DartPadBlock, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(DartPadBlock v) => v.scrollable;
  static const Field<DartPadBlock, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);
  static String _$type(DartPadBlock v) => v.type;
  static const Field<DartPadBlock, String> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<DartPadBlock> fields = const {
    #id: _f$id,
    #theme: _f$theme,
    #embed: _f$embed,
    #run: _f$run,
    #align: _f$align,
    #flex: _f$flex,
    #scrollable: _f$scrollable,
    #type: _f$type,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = DartPadBlock.key;
  @override
  late final ClassMapperBase superMapper =
      SlideElementMapper.ensureInitialized();

  static DartPadBlock _instantiate(DecodingData data) {
    return DartPadBlock(
        id: data.dec(_f$id),
        theme: data.dec(_f$theme),
        embed: data.dec(_f$embed),
        run: data.dec(_f$run),
        align: data.dec(_f$align),
        flex: data.dec(_f$flex),
        scrollable: data.dec(_f$scrollable));
  }

  @override
  final Function instantiate = _instantiate;

  static DartPadBlock fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DartPadBlock>(map);
  }

  static DartPadBlock fromJson(String json) {
    return ensureInitialized().decodeJson<DartPadBlock>(json);
  }
}

mixin DartPadBlockMappable {
  String toJson() {
    return DartPadBlockMapper.ensureInitialized()
        .encodeJson<DartPadBlock>(this as DartPadBlock);
  }

  Map<String, dynamic> toMap() {
    return DartPadBlockMapper.ensureInitialized()
        .encodeMap<DartPadBlock>(this as DartPadBlock);
  }

  DartPadBlockCopyWith<DartPadBlock, DartPadBlock, DartPadBlock> get copyWith =>
      _DartPadBlockCopyWithImpl(this as DartPadBlock, $identity, $identity);
  @override
  String toString() {
    return DartPadBlockMapper.ensureInitialized()
        .stringifyValue(this as DartPadBlock);
  }

  @override
  bool operator ==(Object other) {
    return DartPadBlockMapper.ensureInitialized()
        .equalsValue(this as DartPadBlock, other);
  }

  @override
  int get hashCode {
    return DartPadBlockMapper.ensureInitialized()
        .hashValue(this as DartPadBlock);
  }
}

extension DartPadBlockValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DartPadBlock, $Out> {
  DartPadBlockCopyWith<$R, DartPadBlock, $Out> get $asDartPadBlock =>
      $base.as((v, t, t2) => _DartPadBlockCopyWithImpl(v, t, t2));
}

abstract class DartPadBlockCopyWith<$R, $In extends DartPadBlock, $Out>
    implements SlideElementCopyWith<$R, $In, $Out> {
  @override
  $R call(
      {String? id,
      DartPadTheme? theme,
      bool? embed,
      bool? run,
      ContentAlignment? align,
      int? flex,
      bool? scrollable});
  DartPadBlockCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DartPadBlockCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DartPadBlock, $Out>
    implements DartPadBlockCopyWith<$R, DartPadBlock, $Out> {
  _DartPadBlockCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DartPadBlock> $mapper =
      DartPadBlockMapper.ensureInitialized();
  @override
  $R call(
          {String? id,
          Object? theme = $none,
          Object? embed = $none,
          Object? run = $none,
          Object? align = $none,
          Object? flex = $none,
          Object? scrollable = $none}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (theme != $none) #theme: theme,
        if (embed != $none) #embed: embed,
        if (run != $none) #run: run,
        if (align != $none) #align: align,
        if (flex != $none) #flex: flex,
        if (scrollable != $none) #scrollable: scrollable
      }));
  @override
  DartPadBlock $make(CopyWithData data) => DartPadBlock(
      id: data.get(#id, or: $value.id),
      theme: data.get(#theme, or: $value.theme),
      embed: data.get(#embed, or: $value.embed),
      run: data.get(#run, or: $value.run),
      align: data.get(#align, or: $value.align),
      flex: data.get(#flex, or: $value.flex),
      scrollable: data.get(#scrollable, or: $value.scrollable));

  @override
  DartPadBlockCopyWith<$R2, DartPadBlock, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _DartPadBlockCopyWithImpl($value, $cast, t);
}

class ImageElementMapper extends SubClassMapperBase<ImageElement> {
  ImageElementMapper._();

  static ImageElementMapper? _instance;
  static ImageElementMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ImageElementMapper._());
      SlideElementMapper.ensureInitialized().addSubMapper(_instance!);
      AssetMapper.ensureInitialized();
      ImageFitMapper.ensureInitialized();
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ImageElement';

  static Asset _$asset(ImageElement v) => v.asset;
  static const Field<ImageElement, Asset> _f$asset = Field('asset', _$asset);
  static ImageFit? _$fit(ImageElement v) => v.fit;
  static const Field<ImageElement, ImageFit> _f$fit =
      Field('fit', _$fit, opt: true);
  static double? _$width(ImageElement v) => v.width;
  static const Field<ImageElement, double> _f$width =
      Field('width', _$width, opt: true);
  static double? _$height(ImageElement v) => v.height;
  static const Field<ImageElement, double> _f$height =
      Field('height', _$height, opt: true);
  static ContentAlignment? _$align(ImageElement v) => v.align;
  static const Field<ImageElement, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(ImageElement v) => v.flex;
  static const Field<ImageElement, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(ImageElement v) => v.scrollable;
  static const Field<ImageElement, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);
  static String _$type(ImageElement v) => v.type;
  static const Field<ImageElement, String> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<ImageElement> fields = const {
    #asset: _f$asset,
    #fit: _f$fit,
    #width: _f$width,
    #height: _f$height,
    #align: _f$align,
    #flex: _f$flex,
    #scrollable: _f$scrollable,
    #type: _f$type,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = ImageElement.key;
  @override
  late final ClassMapperBase superMapper =
      SlideElementMapper.ensureInitialized();

  static ImageElement _instantiate(DecodingData data) {
    return ImageElement(
        asset: data.dec(_f$asset),
        fit: data.dec(_f$fit),
        width: data.dec(_f$width),
        height: data.dec(_f$height),
        align: data.dec(_f$align),
        flex: data.dec(_f$flex),
        scrollable: data.dec(_f$scrollable));
  }

  @override
  final Function instantiate = _instantiate;

  static ImageElement fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ImageElement>(map);
  }

  static ImageElement fromJson(String json) {
    return ensureInitialized().decodeJson<ImageElement>(json);
  }
}

mixin ImageElementMappable {
  String toJson() {
    return ImageElementMapper.ensureInitialized()
        .encodeJson<ImageElement>(this as ImageElement);
  }

  Map<String, dynamic> toMap() {
    return ImageElementMapper.ensureInitialized()
        .encodeMap<ImageElement>(this as ImageElement);
  }

  ImageElementCopyWith<ImageElement, ImageElement, ImageElement> get copyWith =>
      _ImageElementCopyWithImpl(this as ImageElement, $identity, $identity);
  @override
  String toString() {
    return ImageElementMapper.ensureInitialized()
        .stringifyValue(this as ImageElement);
  }

  @override
  bool operator ==(Object other) {
    return ImageElementMapper.ensureInitialized()
        .equalsValue(this as ImageElement, other);
  }

  @override
  int get hashCode {
    return ImageElementMapper.ensureInitialized()
        .hashValue(this as ImageElement);
  }
}

extension ImageElementValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ImageElement, $Out> {
  ImageElementCopyWith<$R, ImageElement, $Out> get $asImageElement =>
      $base.as((v, t, t2) => _ImageElementCopyWithImpl(v, t, t2));
}

abstract class ImageElementCopyWith<$R, $In extends ImageElement, $Out>
    implements SlideElementCopyWith<$R, $In, $Out> {
  AssetCopyWith<$R, Asset, Asset> get asset;
  @override
  $R call(
      {Asset? asset,
      ImageFit? fit,
      double? width,
      double? height,
      ContentAlignment? align,
      int? flex,
      bool? scrollable});
  ImageElementCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ImageElementCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ImageElement, $Out>
    implements ImageElementCopyWith<$R, ImageElement, $Out> {
  _ImageElementCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ImageElement> $mapper =
      ImageElementMapper.ensureInitialized();
  @override
  AssetCopyWith<$R, Asset, Asset> get asset =>
      $value.asset.copyWith.$chain((v) => call(asset: v));
  @override
  $R call(
          {Asset? asset,
          Object? fit = $none,
          Object? width = $none,
          Object? height = $none,
          Object? align = $none,
          Object? flex = $none,
          Object? scrollable = $none}) =>
      $apply(FieldCopyWithData({
        if (asset != null) #asset: asset,
        if (fit != $none) #fit: fit,
        if (width != $none) #width: width,
        if (height != $none) #height: height,
        if (align != $none) #align: align,
        if (flex != $none) #flex: flex,
        if (scrollable != $none) #scrollable: scrollable
      }));
  @override
  ImageElement $make(CopyWithData data) => ImageElement(
      asset: data.get(#asset, or: $value.asset),
      fit: data.get(#fit, or: $value.fit),
      width: data.get(#width, or: $value.width),
      height: data.get(#height, or: $value.height),
      align: data.get(#align, or: $value.align),
      flex: data.get(#flex, or: $value.flex),
      scrollable: data.get(#scrollable, or: $value.scrollable));

  @override
  ImageElementCopyWith<$R2, ImageElement, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ImageElementCopyWithImpl($value, $cast, t);
}

class CustomElementMapper extends SubClassMapperBase<CustomElement> {
  CustomElementMapper._();

  static CustomElementMapper? _instance;
  static CustomElementMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CustomElementMapper._());
      SlideElementMapper.ensureInitialized().addSubMapper(_instance!);
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CustomElement';

  static String _$id(CustomElement v) => v.id;
  static const Field<CustomElement, String> _f$id = Field('id', _$id);
  static Map<String, dynamic>? _$props(CustomElement v) => v.props;
  static const Field<CustomElement, Map<String, dynamic>> _f$props =
      Field('props', _$props, opt: true);
  static ContentAlignment? _$align(CustomElement v) => v.align;
  static const Field<CustomElement, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(CustomElement v) => v.flex;
  static const Field<CustomElement, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(CustomElement v) => v.scrollable;
  static const Field<CustomElement, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);
  static String _$type(CustomElement v) => v.type;
  static const Field<CustomElement, String> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<CustomElement> fields = const {
    #id: _f$id,
    #props: _f$props,
    #align: _f$align,
    #flex: _f$flex,
    #scrollable: _f$scrollable,
    #type: _f$type,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = CustomElement.key;
  @override
  late final ClassMapperBase superMapper =
      SlideElementMapper.ensureInitialized();

  @override
  final MappingHook hook = const UnmappedPropertiesHook('props');
  static CustomElement _instantiate(DecodingData data) {
    return CustomElement(
        id: data.dec(_f$id),
        props: data.dec(_f$props),
        align: data.dec(_f$align),
        flex: data.dec(_f$flex),
        scrollable: data.dec(_f$scrollable));
  }

  @override
  final Function instantiate = _instantiate;

  static CustomElement fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CustomElement>(map);
  }

  static CustomElement fromJson(String json) {
    return ensureInitialized().decodeJson<CustomElement>(json);
  }
}

mixin CustomElementMappable {
  String toJson() {
    return CustomElementMapper.ensureInitialized()
        .encodeJson<CustomElement>(this as CustomElement);
  }

  Map<String, dynamic> toMap() {
    return CustomElementMapper.ensureInitialized()
        .encodeMap<CustomElement>(this as CustomElement);
  }

  CustomElementCopyWith<CustomElement, CustomElement, CustomElement>
      get copyWith => _CustomElementCopyWithImpl(
          this as CustomElement, $identity, $identity);
  @override
  String toString() {
    return CustomElementMapper.ensureInitialized()
        .stringifyValue(this as CustomElement);
  }

  @override
  bool operator ==(Object other) {
    return CustomElementMapper.ensureInitialized()
        .equalsValue(this as CustomElement, other);
  }

  @override
  int get hashCode {
    return CustomElementMapper.ensureInitialized()
        .hashValue(this as CustomElement);
  }
}

extension CustomElementValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CustomElement, $Out> {
  CustomElementCopyWith<$R, CustomElement, $Out> get $asCustomElement =>
      $base.as((v, t, t2) => _CustomElementCopyWithImpl(v, t, t2));
}

abstract class CustomElementCopyWith<$R, $In extends CustomElement, $Out>
    implements SlideElementCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>?
      get props;
  @override
  $R call(
      {String? id,
      Map<String, dynamic>? props,
      ContentAlignment? align,
      int? flex,
      bool? scrollable});
  CustomElementCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CustomElementCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CustomElement, $Out>
    implements CustomElementCopyWith<$R, CustomElement, $Out> {
  _CustomElementCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CustomElement> $mapper =
      CustomElementMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>?
      get props => $value.props != null
          ? MapCopyWith($value.props!,
              (v, t) => ObjectCopyWith(v, $identity, t), (v) => call(props: v))
          : null;
  @override
  $R call(
          {String? id,
          Object? props = $none,
          Object? align = $none,
          Object? flex = $none,
          Object? scrollable = $none}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (props != $none) #props: props,
        if (align != $none) #align: align,
        if (flex != $none) #flex: flex,
        if (scrollable != $none) #scrollable: scrollable
      }));
  @override
  CustomElement $make(CopyWithData data) => CustomElement(
      id: data.get(#id, or: $value.id),
      props: data.get(#props, or: $value.props),
      align: data.get(#align, or: $value.align),
      flex: data.get(#flex, or: $value.flex),
      scrollable: data.get(#scrollable, or: $value.scrollable));

  @override
  CustomElementCopyWith<$R2, CustomElement, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _CustomElementCopyWithImpl($value, $cast, t);
}
