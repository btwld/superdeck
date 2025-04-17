// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'widget_block.dart';

class WidgetBlockMapper extends SubClassMapperBase<WidgetBlock> {
  WidgetBlockMapper._();

  static WidgetBlockMapper? _instance;
  static WidgetBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WidgetBlockMapper._());
      BaseBlockMapper.ensureInitialized().addSubMapper(_instance!);
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WidgetBlock';

  static String _$id(WidgetBlock v) => v.id;
  static const Field<WidgetBlock, String> _f$id = Field('id', _$id);
  static Map<String, dynamic>? _$props(WidgetBlock v) => v.props;
  static const Field<WidgetBlock, Map<String, dynamic>> _f$props =
      Field('props', _$props, opt: true);
  static ContentAlignment? _$align(WidgetBlock v) => v.align;
  static const Field<WidgetBlock, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(WidgetBlock v) => v.flex;
  static const Field<WidgetBlock, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(WidgetBlock v) => v.scrollable;
  static const Field<WidgetBlock, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);
  static String _$type(WidgetBlock v) => v.type;
  static const Field<WidgetBlock, String> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<WidgetBlock> fields = const {
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
  final dynamic discriminatorValue = WidgetBlock.key;
  @override
  late final ClassMapperBase superMapper = BaseBlockMapper.ensureInitialized();

  @override
  final MappingHook hook = const UnmappedPropertiesHook('props');
  static WidgetBlock _instantiate(DecodingData data) {
    return WidgetBlock(
        id: data.dec(_f$id),
        props: data.dec(_f$props),
        align: data.dec(_f$align),
        flex: data.dec(_f$flex),
        scrollable: data.dec(_f$scrollable));
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
    return WidgetBlockMapper.ensureInitialized()
        .encodeJson<WidgetBlock>(this as WidgetBlock);
  }

  Map<String, dynamic> toMap() {
    return WidgetBlockMapper.ensureInitialized()
        .encodeMap<WidgetBlock>(this as WidgetBlock);
  }

  WidgetBlockCopyWith<WidgetBlock, WidgetBlock, WidgetBlock> get copyWith =>
      _WidgetBlockCopyWithImpl(this as WidgetBlock, $identity, $identity);
  @override
  String toString() {
    return WidgetBlockMapper.ensureInitialized()
        .stringifyValue(this as WidgetBlock);
  }

  @override
  bool operator ==(Object other) {
    return WidgetBlockMapper.ensureInitialized()
        .equalsValue(this as WidgetBlock, other);
  }

  @override
  int get hashCode {
    return WidgetBlockMapper.ensureInitialized().hashValue(this as WidgetBlock);
  }
}

extension WidgetBlockValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WidgetBlock, $Out> {
  WidgetBlockCopyWith<$R, WidgetBlock, $Out> get $asWidgetBlock =>
      $base.as((v, t, t2) => _WidgetBlockCopyWithImpl(v, t, t2));
}

abstract class WidgetBlockCopyWith<$R, $In extends WidgetBlock, $Out>
    implements BaseBlockCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>?
      get props;
  @override
  $R call(
      {String? id,
      Map<String, dynamic>? props,
      ContentAlignment? align,
      int? flex,
      bool? scrollable});
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
  WidgetBlock $make(CopyWithData data) => WidgetBlock(
      id: data.get(#id, or: $value.id),
      props: data.get(#props, or: $value.props),
      align: data.get(#align, or: $value.align),
      flex: data.get(#flex, or: $value.flex),
      scrollable: data.get(#scrollable, or: $value.scrollable));

  @override
  WidgetBlockCopyWith<$R2, WidgetBlock, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _WidgetBlockCopyWithImpl($value, $cast, t);
}
