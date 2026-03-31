// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'slide_template.dart';

class SlideTemplateMapper extends ClassMapperBase<SlideTemplate> {
  SlideTemplateMapper._();

  static SlideTemplateMapper? _instance;
  static SlideTemplateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SlideTemplateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SlideTemplate';

  static SlideParts _$parts(SlideTemplate v) => v.parts;
  static const Field<SlideTemplate, SlideParts> _f$parts = Field(
    'parts',
    _$parts,
    opt: true,
    def: const SlideParts(),
  );
  static SlideStyle? _$baseStyle(SlideTemplate v) => v.baseStyle;
  static const Field<SlideTemplate, SlideStyle> _f$baseStyle = Field(
    'baseStyle',
    _$baseStyle,
    opt: true,
  );
  static Map<String, SlideStyle> _$styles(SlideTemplate v) => v.styles;
  static const Field<SlideTemplate, Map<String, SlideStyle>> _f$styles = Field(
    'styles',
    _$styles,
    opt: true,
    def: const <String, SlideStyle>{},
  );

  @override
  final MappableFields<SlideTemplate> fields = const {
    #parts: _f$parts,
    #baseStyle: _f$baseStyle,
    #styles: _f$styles,
  };

  static SlideTemplate _instantiate(DecodingData data) {
    return SlideTemplate(
      parts: data.dec(_f$parts),
      baseStyle: data.dec(_f$baseStyle),
      styles: data.dec(_f$styles),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SlideTemplate fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SlideTemplate>(map);
  }

  static SlideTemplate fromJson(String json) {
    return ensureInitialized().decodeJson<SlideTemplate>(json);
  }
}

mixin SlideTemplateMappable {
  String toJson() {
    return SlideTemplateMapper.ensureInitialized().encodeJson<SlideTemplate>(
      this as SlideTemplate,
    );
  }

  Map<String, dynamic> toMap() {
    return SlideTemplateMapper.ensureInitialized().encodeMap<SlideTemplate>(
      this as SlideTemplate,
    );
  }

  SlideTemplateCopyWith<SlideTemplate, SlideTemplate, SlideTemplate>
  get copyWith => _SlideTemplateCopyWithImpl<SlideTemplate, SlideTemplate>(
    this as SlideTemplate,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return SlideTemplateMapper.ensureInitialized().stringifyValue(
      this as SlideTemplate,
    );
  }

  @override
  bool operator ==(Object other) {
    return SlideTemplateMapper.ensureInitialized().equalsValue(
      this as SlideTemplate,
      other,
    );
  }

  @override
  int get hashCode {
    return SlideTemplateMapper.ensureInitialized().hashValue(
      this as SlideTemplate,
    );
  }
}

extension SlideTemplateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SlideTemplate, $Out> {
  SlideTemplateCopyWith<$R, SlideTemplate, $Out> get $asSlideTemplate =>
      $base.as((v, t, t2) => _SlideTemplateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SlideTemplateCopyWith<$R, $In extends SlideTemplate, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    SlideStyle,
    ObjectCopyWith<$R, SlideStyle, SlideStyle>
  >
  get styles;
  $R call({
    SlideParts? parts,
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
  });
  SlideTemplateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SlideTemplateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SlideTemplate, $Out>
    implements SlideTemplateCopyWith<$R, SlideTemplate, $Out> {
  _SlideTemplateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SlideTemplate> $mapper =
      SlideTemplateMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    SlideStyle,
    ObjectCopyWith<$R, SlideStyle, SlideStyle>
  >
  get styles => MapCopyWith(
    $value.styles,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(styles: v),
  );
  @override
  $R call({
    SlideParts? parts,
    Object? baseStyle = $none,
    Map<String, SlideStyle>? styles,
  }) => $apply(
    FieldCopyWithData({
      if (parts != null) #parts: parts,
      if (baseStyle != $none) #baseStyle: baseStyle,
      if (styles != null) #styles: styles,
    }),
  );
  @override
  SlideTemplate $make(CopyWithData data) => SlideTemplate(
    parts: data.get(#parts, or: $value.parts),
    baseStyle: data.get(#baseStyle, or: $value.baseStyle),
    styles: data.get(#styles, or: $value.styles),
  );

  @override
  SlideTemplateCopyWith<$R2, SlideTemplate, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SlideTemplateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

