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

  PresentationCopyWith<Presentation, Presentation, Presentation> get copyWith =>
      _PresentationCopyWithImpl(this as Presentation, $identity, $identity);
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

extension PresentationValueCopy<$R, $Out>
    on ObjectCopyWith<$R, Presentation, $Out> {
  PresentationCopyWith<$R, Presentation, $Out> get $asPresentation =>
      $base.as((v, t, t2) => _PresentationCopyWithImpl(v, t, t2));
}

abstract class PresentationCopyWith<$R, $In extends Presentation, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Slide, SlideCopyWith<$R, Slide, Slide>> get slides;
  PresentationConfigCopyWith<$R, PresentationConfig, PresentationConfig>
      get configuration;
  $R call({List<Slide>? slides, PresentationConfig? configuration});
  PresentationCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PresentationCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Presentation, $Out>
    implements PresentationCopyWith<$R, Presentation, $Out> {
  _PresentationCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Presentation> $mapper =
      PresentationMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Slide, SlideCopyWith<$R, Slide, Slide>> get slides =>
      ListCopyWith($value.slides, (v, t) => v.copyWith.$chain(t),
          (v) => call(slides: v));
  @override
  PresentationConfigCopyWith<$R, PresentationConfig, PresentationConfig>
      get configuration =>
          $value.configuration.copyWith.$chain((v) => call(configuration: v));
  @override
  $R call({List<Slide>? slides, PresentationConfig? configuration}) =>
      $apply(FieldCopyWithData({
        if (slides != null) #slides: slides,
        if (configuration != null) #configuration: configuration
      }));
  @override
  Presentation $make(CopyWithData data) => Presentation(
      slides: data.get(#slides, or: $value.slides),
      configuration: data.get(#configuration, or: $value.configuration));

  @override
  PresentationCopyWith<$R2, Presentation, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _PresentationCopyWithImpl($value, $cast, t);
}
