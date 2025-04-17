// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'markdown_block.dart';

class MarkdownBlockMapper extends SubClassMapperBase<MarkdownBlock> {
  MarkdownBlockMapper._();

  static MarkdownBlockMapper? _instance;
  static MarkdownBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MarkdownBlockMapper._());
      BaseBlockMapper.ensureInitialized().addSubMapper(_instance!);
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'MarkdownBlock';

  static String _$content(MarkdownBlock v) => v.content;
  static const Field<MarkdownBlock, String> _f$content =
      Field('content', _$content);
  static ContentAlignment? _$align(MarkdownBlock v) => v.align;
  static const Field<MarkdownBlock, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(MarkdownBlock v) => v.flex;
  static const Field<MarkdownBlock, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(MarkdownBlock v) => v.scrollable;
  static const Field<MarkdownBlock, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);
  static String _$type(MarkdownBlock v) => v.type;
  static const Field<MarkdownBlock, String> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<MarkdownBlock> fields = const {
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
  final dynamic discriminatorValue = MarkdownBlock.key;
  @override
  late final ClassMapperBase superMapper = BaseBlockMapper.ensureInitialized();

  static MarkdownBlock _instantiate(DecodingData data) {
    return MarkdownBlock(data.dec(_f$content),
        align: data.dec(_f$align),
        flex: data.dec(_f$flex),
        scrollable: data.dec(_f$scrollable));
  }

  @override
  final Function instantiate = _instantiate;

  static MarkdownBlock fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MarkdownBlock>(map);
  }

  static MarkdownBlock fromJson(String json) {
    return ensureInitialized().decodeJson<MarkdownBlock>(json);
  }
}

mixin MarkdownBlockMappable {
  String toJson() {
    return MarkdownBlockMapper.ensureInitialized()
        .encodeJson<MarkdownBlock>(this as MarkdownBlock);
  }

  Map<String, dynamic> toMap() {
    return MarkdownBlockMapper.ensureInitialized()
        .encodeMap<MarkdownBlock>(this as MarkdownBlock);
  }

  @override
  String toString() {
    return MarkdownBlockMapper.ensureInitialized()
        .stringifyValue(this as MarkdownBlock);
  }

  @override
  bool operator ==(Object other) {
    return MarkdownBlockMapper.ensureInitialized()
        .equalsValue(this as MarkdownBlock, other);
  }

  @override
  int get hashCode {
    return MarkdownBlockMapper.ensureInitialized()
        .hashValue(this as MarkdownBlock);
  }
}
