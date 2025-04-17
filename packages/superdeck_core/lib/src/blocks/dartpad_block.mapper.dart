// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'dartpad_block.dart';

class DartPadBlockMapper extends SubClassMapperBase<DartPadBlock> {
  DartPadBlockMapper._();

  static DartPadBlockMapper? _instance;
  static DartPadBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DartPadBlockMapper._());
      BaseBlockMapper.ensureInitialized().addSubMapper(_instance!);
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
  late final ClassMapperBase superMapper = BaseBlockMapper.ensureInitialized();

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
    implements BaseBlockCopyWith<$R, $In, $Out> {
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
