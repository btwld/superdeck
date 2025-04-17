// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'presentation.model.dart';

class PresentationMapper extends ClassMapperBase<Presentation> {
  PresentationMapper._();

  static PresentationMapper? _instance;
  static PresentationMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PresentationMapper._());
      SlideMapper.ensureInitialized();
      PresentationConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Presentation';

  static List<Slide> _$slides(Presentation v) => v.slides;
  static const Field<Presentation, List<Slide>> _f$slides =
      Field('slides', _$slides);
  static PresentationConfig _$configuration(Presentation v) => v.configuration;
  static const Field<Presentation, PresentationConfig> _f$configuration =
      Field('configuration', _$configuration);

  @override
  final MappableFields<Presentation> fields = const {
    #slides: _f$slides,
    #configuration: _f$configuration,
  };
  @override
  final bool ignoreNull = true;

  static Presentation _instantiate(DecodingData data) {
    return Presentation(
        slides: data.dec(_f$slides), configuration: data.dec(_f$configuration));
  }

  @override
  final Function instantiate = _instantiate;

  static Presentation fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Presentation>(map);
  }

  static Presentation fromJson(String json) {
    return ensureInitialized().decodeJson<Presentation>(json);
  }
}

mixin PresentationMappable {
  String toJson() {
    return PresentationMapper.ensureInitialized()
        .encodeJson<Presentation>(this as Presentation);
  }

  Map<String, dynamic> toMap() {
    return PresentationMapper.ensureInitialized()
        .encodeMap<Presentation>(this as Presentation);
  }

  @override
  String toString() {
    return PresentationMapper.ensureInitialized()
        .stringifyValue(this as Presentation);
  }

  @override
  bool operator ==(Object other) {
    return PresentationMapper.ensureInitialized()
        .equalsValue(this as Presentation, other);
  }

  @override
  int get hashCode {
    return PresentationMapper.ensureInitialized()
        .hashValue(this as Presentation);
  }
}
