// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'image_block.dart';

class ImageBlockMapper extends SubClassMapperBase<ImageBlock> {
  ImageBlockMapper._();

  static ImageBlockMapper? _instance;
  static ImageBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ImageBlockMapper._());
      BaseBlockMapper.ensureInitialized().addSubMapper(_instance!);
      AssetMapper.ensureInitialized();
      ImageFitMapper.ensureInitialized();
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ImageBlock';

  static Asset _$asset(ImageBlock v) => v.asset;
  static const Field<ImageBlock, Asset> _f$asset = Field('asset', _$asset);
  static ImageFit? _$fit(ImageBlock v) => v.fit;
  static const Field<ImageBlock, ImageFit> _f$fit =
      Field('fit', _$fit, opt: true);
  static double? _$width(ImageBlock v) => v.width;
  static const Field<ImageBlock, double> _f$width =
      Field('width', _$width, opt: true);
  static double? _$height(ImageBlock v) => v.height;
  static const Field<ImageBlock, double> _f$height =
      Field('height', _$height, opt: true);
  static ContentAlignment? _$align(ImageBlock v) => v.align;
  static const Field<ImageBlock, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(ImageBlock v) => v.flex;
  static const Field<ImageBlock, int> _f$flex =
      Field('flex', _$flex, opt: true);
  static bool? _$scrollable(ImageBlock v) => v.scrollable;
  static const Field<ImageBlock, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);
  static String _$type(ImageBlock v) => v.type;
  static const Field<ImageBlock, String> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<ImageBlock> fields = const {
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
  final dynamic discriminatorValue = ImageBlock.key;
  @override
  late final ClassMapperBase superMapper = BaseBlockMapper.ensureInitialized();

  static ImageBlock _instantiate(DecodingData data) {
    return ImageBlock(
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

  static ImageBlock fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ImageBlock>(map);
  }

  static ImageBlock fromJson(String json) {
    return ensureInitialized().decodeJson<ImageBlock>(json);
  }
}

mixin ImageBlockMappable {
  String toJson() {
    return ImageBlockMapper.ensureInitialized()
        .encodeJson<ImageBlock>(this as ImageBlock);
  }

  Map<String, dynamic> toMap() {
    return ImageBlockMapper.ensureInitialized()
        .encodeMap<ImageBlock>(this as ImageBlock);
  }

  @override
  String toString() {
    return ImageBlockMapper.ensureInitialized()
        .stringifyValue(this as ImageBlock);
  }

  @override
  bool operator ==(Object other) {
    return ImageBlockMapper.ensureInitialized()
        .equalsValue(this as ImageBlock, other);
  }

  @override
  int get hashCode {
    return ImageBlockMapper.ensureInitialized().hashValue(this as ImageBlock);
  }
}
