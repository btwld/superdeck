// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'section_block.dart';

class SectionBlockMapper extends SubClassMapperBase<SectionBlock> {
  SectionBlockMapper._();

  static SectionBlockMapper? _instance;
  static SectionBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SectionBlockMapper._());
      BaseBlockMapper.ensureInitialized().addSubMapper(_instance!);
      BaseBlockMapper.ensureInitialized();
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SectionBlock';

  static List<BaseBlock> _$blocks(SectionBlock v) => v.blocks;
  static const Field<SectionBlock, List<BaseBlock>> _f$blocks =
      Field('blocks', _$blocks);
  static ContentAlignment? _$align(SectionBlock v) => v.align;
  static const Field<SectionBlock, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(SectionBlock v) => v.flex;
  static const Field<SectionBlock, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(SectionBlock v) => v.scrollable;
  static const Field<SectionBlock, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);
  static String _$type(SectionBlock v) => v.type;
  static const Field<SectionBlock, String> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<SectionBlock> fields = const {
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
  final dynamic discriminatorValue = SectionBlock.key;
  @override
  late final ClassMapperBase superMapper = BaseBlockMapper.ensureInitialized();

  static SectionBlock _instantiate(DecodingData data) {
    return SectionBlock(data.dec(_f$blocks),
        align: data.dec(_f$align),
        flex: data.dec(_f$flex),
        scrollable: data.dec(_f$scrollable));
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
    return SectionBlockMapper.ensureInitialized()
        .encodeJson<SectionBlock>(this as SectionBlock);
  }

  Map<String, dynamic> toMap() {
    return SectionBlockMapper.ensureInitialized()
        .encodeMap<SectionBlock>(this as SectionBlock);
  }

  @override
  String toString() {
    return SectionBlockMapper.ensureInitialized()
        .stringifyValue(this as SectionBlock);
  }

  @override
  bool operator ==(Object other) {
    return SectionBlockMapper.ensureInitialized()
        .equalsValue(this as SectionBlock, other);
  }

  @override
  int get hashCode {
    return SectionBlockMapper.ensureInitialized()
        .hashValue(this as SectionBlock);
  }
}
