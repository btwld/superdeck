// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'wizard_context.dart';

class WizardContextMapper extends ClassMapperBase<WizardContext> {
  WizardContextMapper._();

  static WizardContextMapper? _instance;
  static WizardContextMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WizardContextMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'WizardContext';

  static String? _$topic(WizardContext v) => v.topic;
  static const Field<WizardContext, String> _f$topic = Field(
    'topic',
    _$topic,
    opt: true,
  );
  static String? _$audience(WizardContext v) => v.audience;
  static const Field<WizardContext, String> _f$audience = Field(
    'audience',
    _$audience,
    opt: true,
  );
  static String? _$approach(WizardContext v) => v.approach;
  static const Field<WizardContext, String> _f$approach = Field(
    'approach',
    _$approach,
    opt: true,
  );
  static List<String>? _$emphasis(WizardContext v) => v.emphasis;
  static const Field<WizardContext, List<String>> _f$emphasis = Field(
    'emphasis',
    _$emphasis,
    opt: true,
  );
  static int? _$slideCount(WizardContext v) => v.slideCount;
  static const Field<WizardContext, int> _f$slideCount = Field(
    'slideCount',
    _$slideCount,
    opt: true,
  );
  static String? _$style(WizardContext v) => v.style;
  static const Field<WizardContext, String> _f$style = Field(
    'style',
    _$style,
    opt: true,
  );
  static List<String>? _$colors(WizardContext v) => v.colors;
  static const Field<WizardContext, List<String>> _f$colors = Field(
    'colors',
    _$colors,
    opt: true,
  );
  static String? _$headlineFont(WizardContext v) => v.headlineFont;
  static const Field<WizardContext, String> _f$headlineFont = Field(
    'headlineFont',
    _$headlineFont,
    opt: true,
  );
  static String? _$bodyFont(WizardContext v) => v.bodyFont;
  static const Field<WizardContext, String> _f$bodyFont = Field(
    'bodyFont',
    _$bodyFont,
    opt: true,
  );
  static String? _$imageStyleId(WizardContext v) => v.imageStyleId;
  static const Field<WizardContext, String> _f$imageStyleId = Field(
    'imageStyleId',
    _$imageStyleId,
    opt: true,
  );
  static String? _$imageStyleName(WizardContext v) => v.imageStyleName;
  static const Field<WizardContext, String> _f$imageStyleName = Field(
    'imageStyleName',
    _$imageStyleName,
    opt: true,
  );
  static String? _$imageStyleDescription(WizardContext v) =>
      v.imageStyleDescription;
  static const Field<WizardContext, String> _f$imageStyleDescription = Field(
    'imageStyleDescription',
    _$imageStyleDescription,
    opt: true,
  );

  @override
  final MappableFields<WizardContext> fields = const {
    #topic: _f$topic,
    #audience: _f$audience,
    #approach: _f$approach,
    #emphasis: _f$emphasis,
    #slideCount: _f$slideCount,
    #style: _f$style,
    #colors: _f$colors,
    #headlineFont: _f$headlineFont,
    #bodyFont: _f$bodyFont,
    #imageStyleId: _f$imageStyleId,
    #imageStyleName: _f$imageStyleName,
    #imageStyleDescription: _f$imageStyleDescription,
  };
  @override
  final bool ignoreNull = true;

  static WizardContext _instantiate(DecodingData data) {
    return WizardContext(
      topic: data.dec(_f$topic),
      audience: data.dec(_f$audience),
      approach: data.dec(_f$approach),
      emphasis: data.dec(_f$emphasis),
      slideCount: data.dec(_f$slideCount),
      style: data.dec(_f$style),
      colors: data.dec(_f$colors),
      headlineFont: data.dec(_f$headlineFont),
      bodyFont: data.dec(_f$bodyFont),
      imageStyleId: data.dec(_f$imageStyleId),
      imageStyleName: data.dec(_f$imageStyleName),
      imageStyleDescription: data.dec(_f$imageStyleDescription),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static WizardContext fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WizardContext>(map);
  }

  static WizardContext fromJson(String json) {
    return ensureInitialized().decodeJson<WizardContext>(json);
  }
}

mixin WizardContextMappable {
  String toJson() {
    return WizardContextMapper.ensureInitialized().encodeJson<WizardContext>(
      this as WizardContext,
    );
  }

  Map<String, dynamic> toMap() {
    return WizardContextMapper.ensureInitialized().encodeMap<WizardContext>(
      this as WizardContext,
    );
  }

  WizardContextCopyWith<WizardContext, WizardContext, WizardContext>
  get copyWith => _WizardContextCopyWithImpl<WizardContext, WizardContext>(
    this as WizardContext,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return WizardContextMapper.ensureInitialized().stringifyValue(
      this as WizardContext,
    );
  }

  @override
  bool operator ==(Object other) {
    return WizardContextMapper.ensureInitialized().equalsValue(
      this as WizardContext,
      other,
    );
  }

  @override
  int get hashCode {
    return WizardContextMapper.ensureInitialized().hashValue(
      this as WizardContext,
    );
  }
}

extension WizardContextValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WizardContext, $Out> {
  WizardContextCopyWith<$R, WizardContext, $Out> get $asWizardContext =>
      $base.as((v, t, t2) => _WizardContextCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WizardContextCopyWith<$R, $In extends WizardContext, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get emphasis;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get colors;
  $R call({
    String? topic,
    String? audience,
    String? approach,
    List<String>? emphasis,
    int? slideCount,
    String? style,
    List<String>? colors,
    String? headlineFont,
    String? bodyFont,
    String? imageStyleId,
    String? imageStyleName,
    String? imageStyleDescription,
  });
  WizardContextCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _WizardContextCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WizardContext, $Out>
    implements WizardContextCopyWith<$R, WizardContext, $Out> {
  _WizardContextCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WizardContext> $mapper =
      WizardContextMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get emphasis =>
      $value.emphasis != null
      ? ListCopyWith(
          $value.emphasis!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(emphasis: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get colors =>
      $value.colors != null
      ? ListCopyWith(
          $value.colors!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(colors: v),
        )
      : null;
  @override
  $R call({
    Object? topic = $none,
    Object? audience = $none,
    Object? approach = $none,
    Object? emphasis = $none,
    Object? slideCount = $none,
    Object? style = $none,
    Object? colors = $none,
    Object? headlineFont = $none,
    Object? bodyFont = $none,
    Object? imageStyleId = $none,
    Object? imageStyleName = $none,
    Object? imageStyleDescription = $none,
  }) => $apply(
    FieldCopyWithData({
      if (topic != $none) #topic: topic,
      if (audience != $none) #audience: audience,
      if (approach != $none) #approach: approach,
      if (emphasis != $none) #emphasis: emphasis,
      if (slideCount != $none) #slideCount: slideCount,
      if (style != $none) #style: style,
      if (colors != $none) #colors: colors,
      if (headlineFont != $none) #headlineFont: headlineFont,
      if (bodyFont != $none) #bodyFont: bodyFont,
      if (imageStyleId != $none) #imageStyleId: imageStyleId,
      if (imageStyleName != $none) #imageStyleName: imageStyleName,
      if (imageStyleDescription != $none)
        #imageStyleDescription: imageStyleDescription,
    }),
  );
  @override
  WizardContext $make(CopyWithData data) => WizardContext(
    topic: data.get(#topic, or: $value.topic),
    audience: data.get(#audience, or: $value.audience),
    approach: data.get(#approach, or: $value.approach),
    emphasis: data.get(#emphasis, or: $value.emphasis),
    slideCount: data.get(#slideCount, or: $value.slideCount),
    style: data.get(#style, or: $value.style),
    colors: data.get(#colors, or: $value.colors),
    headlineFont: data.get(#headlineFont, or: $value.headlineFont),
    bodyFont: data.get(#bodyFont, or: $value.bodyFont),
    imageStyleId: data.get(#imageStyleId, or: $value.imageStyleId),
    imageStyleName: data.get(#imageStyleName, or: $value.imageStyleName),
    imageStyleDescription: data.get(
      #imageStyleDescription,
      or: $value.imageStyleDescription,
    ),
  );

  @override
  WizardContextCopyWith<$R2, WizardContext, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _WizardContextCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

