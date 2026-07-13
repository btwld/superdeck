// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'slide_configuration.dart';

class SlideConfigurationMapper extends ClassMapperBase<SlideConfiguration> {
  SlideConfigurationMapper._();

  static SlideConfigurationMapper? _instance;
  static SlideConfigurationMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SlideConfigurationMapper._());
      SlideMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SlideConfiguration';

  static int _$slideIndex(SlideConfiguration v) => v.slideIndex;
  static const Field<SlideConfiguration, int> _f$slideIndex = Field(
    'slideIndex',
    _$slideIndex,
  );
  static SlideStyler _$style(SlideConfiguration v) => v.style;
  static const Field<SlideConfiguration, SlideStyler> _f$style = Field(
    'style',
    _$style,
  );
  static Slide _$slide(SlideConfiguration v) => v.slide;
  static const Field<SlideConfiguration, Slide> _f$slide = Field(
    'slide',
    _$slide,
  );
  static bool _$debug(SlideConfiguration v) => v.debug;
  static const Field<SlideConfiguration, bool> _f$debug = Field(
    'debug',
    _$debug,
    opt: true,
    def: false,
  );
  static SlideParts? _$parts(SlideConfiguration v) => v.parts;
  static const Field<SlideConfiguration, SlideParts> _f$parts = Field(
    'parts',
    _$parts,
    opt: true,
  );
  static String _$thumbnailKey(SlideConfiguration v) => v.thumbnailKey;
  static const Field<SlideConfiguration, String> _f$thumbnailKey = Field(
    'thumbnailKey',
    _$thumbnailKey,
  );
  static Map<String, Widget Function(Map<String, Object?>)> _$widgets(
    SlideConfiguration v,
  ) => v.widgets;
  static const Field<
    SlideConfiguration,
    Map<String, Widget Function(Map<String, Object?>)>
  >
  _f$widgets = Field('widgets', _$widgets, opt: true, def: const {});
  static bool _$isStaticRendering(SlideConfiguration v) => v.isStaticRendering;
  static const Field<SlideConfiguration, bool> _f$isStaticRendering = Field(
    'isStaticRendering',
    _$isStaticRendering,
    opt: true,
    def: false,
  );
  static AssetCacheStore? _$assetCacheStore(SlideConfiguration v) =>
      v.assetCacheStore;
  static const Field<SlideConfiguration, AssetCacheStore> _f$assetCacheStore =
      Field('assetCacheStore', _$assetCacheStore, opt: true);

  @override
  final MappableFields<SlideConfiguration> fields = const {
    #slideIndex: _f$slideIndex,
    #style: _f$style,
    #slide: _f$slide,
    #debug: _f$debug,
    #parts: _f$parts,
    #thumbnailKey: _f$thumbnailKey,
    #widgets: _f$widgets,
    #isStaticRendering: _f$isStaticRendering,
    #assetCacheStore: _f$assetCacheStore,
  };

  static SlideConfiguration _instantiate(DecodingData data) {
    return SlideConfiguration(
      slideIndex: data.dec(_f$slideIndex),
      style: data.dec(_f$style),
      slide: data.dec(_f$slide),
      debug: data.dec(_f$debug),
      parts: data.dec(_f$parts),
      thumbnailKey: data.dec(_f$thumbnailKey),
      widgets: data.dec(_f$widgets),
      isStaticRendering: data.dec(_f$isStaticRendering),
      assetCacheStore: data.dec(_f$assetCacheStore),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SlideConfiguration fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SlideConfiguration>(map);
  }

  static SlideConfiguration fromJson(String json) {
    return ensureInitialized().decodeJson<SlideConfiguration>(json);
  }
}

mixin SlideConfigurationMappable {
  String toJson() {
    return SlideConfigurationMapper.ensureInitialized()
        .encodeJson<SlideConfiguration>(this as SlideConfiguration);
  }

  Map<String, dynamic> toMap() {
    return SlideConfigurationMapper.ensureInitialized()
        .encodeMap<SlideConfiguration>(this as SlideConfiguration);
  }

  SlideConfigurationCopyWith<
    SlideConfiguration,
    SlideConfiguration,
    SlideConfiguration
  >
  get copyWith =>
      _SlideConfigurationCopyWithImpl<SlideConfiguration, SlideConfiguration>(
        this as SlideConfiguration,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SlideConfigurationMapper.ensureInitialized().stringifyValue(
      this as SlideConfiguration,
    );
  }

  @override
  bool operator ==(Object other) {
    return SlideConfigurationMapper.ensureInitialized().equalsValue(
      this as SlideConfiguration,
      other,
    );
  }

  @override
  int get hashCode {
    return SlideConfigurationMapper.ensureInitialized().hashValue(
      this as SlideConfiguration,
    );
  }
}

extension SlideConfigurationValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SlideConfiguration, $Out> {
  SlideConfigurationCopyWith<$R, SlideConfiguration, $Out>
  get $asSlideConfiguration => $base.as(
    (v, t, t2) => _SlideConfigurationCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SlideConfigurationCopyWith<
  $R,
  $In extends SlideConfiguration,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  SlideCopyWith<$R, Slide, Slide> get slide;
  MapCopyWith<
    $R,
    String,
    Widget Function(Map<String, Object?>),
    ObjectCopyWith<
      $R,
      Widget Function(Map<String, Object?>),
      Widget Function(Map<String, Object?>)
    >
  >
  get widgets;
  $R call({
    int? slideIndex,
    SlideStyler? style,
    Slide? slide,
    bool? debug,
    SlideParts? parts,
    String? thumbnailKey,
    Map<String, Widget Function(Map<String, Object?>)>? widgets,
    bool? isStaticRendering,
    AssetCacheStore? assetCacheStore,
  });
  SlideConfigurationCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SlideConfigurationCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SlideConfiguration, $Out>
    implements SlideConfigurationCopyWith<$R, SlideConfiguration, $Out> {
  _SlideConfigurationCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SlideConfiguration> $mapper =
      SlideConfigurationMapper.ensureInitialized();
  @override
  SlideCopyWith<$R, Slide, Slide> get slide =>
      $value.slide.copyWith.$chain((v) => call(slide: v));
  @override
  MapCopyWith<
    $R,
    String,
    Widget Function(Map<String, Object?>),
    ObjectCopyWith<
      $R,
      Widget Function(Map<String, Object?>),
      Widget Function(Map<String, Object?>)
    >
  >
  get widgets => MapCopyWith(
    $value.widgets,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(widgets: v),
  );
  @override
  $R call({
    int? slideIndex,
    SlideStyler? style,
    Slide? slide,
    bool? debug,
    Object? parts = $none,
    String? thumbnailKey,
    Map<String, Widget Function(Map<String, Object?>)>? widgets,
    bool? isStaticRendering,
    Object? assetCacheStore = $none,
  }) => $apply(
    FieldCopyWithData({
      if (slideIndex != null) #slideIndex: slideIndex,
      if (style != null) #style: style,
      if (slide != null) #slide: slide,
      if (debug != null) #debug: debug,
      if (parts != $none) #parts: parts,
      if (thumbnailKey != null) #thumbnailKey: thumbnailKey,
      if (widgets != null) #widgets: widgets,
      if (isStaticRendering != null) #isStaticRendering: isStaticRendering,
      if (assetCacheStore != $none) #assetCacheStore: assetCacheStore,
    }),
  );
  @override
  SlideConfiguration $make(CopyWithData data) => SlideConfiguration(
    slideIndex: data.get(#slideIndex, or: $value.slideIndex),
    style: data.get(#style, or: $value.style),
    slide: data.get(#slide, or: $value.slide),
    debug: data.get(#debug, or: $value.debug),
    parts: data.get(#parts, or: $value.parts),
    thumbnailKey: data.get(#thumbnailKey, or: $value.thumbnailKey),
    widgets: data.get(#widgets, or: $value.widgets),
    isStaticRendering: data.get(
      #isStaticRendering,
      or: $value.isStaticRendering,
    ),
    assetCacheStore: data.get(#assetCacheStore, or: $value.assetCacheStore),
  );

  @override
  SlideConfigurationCopyWith<$R2, SlideConfiguration, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SlideConfigurationCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

