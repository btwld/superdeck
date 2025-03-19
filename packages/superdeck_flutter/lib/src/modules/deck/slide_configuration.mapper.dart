// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
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
  static const Field<SlideConfiguration, int> _f$slideIndex =
      Field('slideIndex', _$slideIndex);
  static Style _$style(SlideConfiguration v) => v.style;
  static const Field<SlideConfiguration, Style> _f$style =
      Field('style', _$style);
  static Slide _$_slide(SlideConfiguration v) => v._slide;
  static const Field<SlideConfiguration, Slide> _f$_slide =
      Field('_slide', _$_slide, key: r'slide');
  static bool _$debug(SlideConfiguration v) => v.debug;
  static const Field<SlideConfiguration, bool> _f$debug =
      Field('debug', _$debug, opt: true, def: false);
  static SlideParts? _$parts(SlideConfiguration v) => v.parts;
  static const Field<SlideConfiguration, SlideParts> _f$parts =
      Field('parts', _$parts, opt: true);
  static String _$thumbnailFile(SlideConfiguration v) => v.thumbnailFile;
  static const Field<SlideConfiguration, String> _f$thumbnailFile =
      Field('thumbnailFile', _$thumbnailFile);
  static Map<String, Widget Function(Map<String, dynamic>)> _$_widgets(
          SlideConfiguration v) =>
      v._widgets;
  static const Field<SlideConfiguration,
          Map<String, Widget Function(Map<String, dynamic>)>> _f$_widgets =
      Field('_widgets', _$_widgets, key: r'widgets', opt: true, def: const {});
  static bool _$isExporting(SlideConfiguration v) => v.isExporting;
  static const Field<SlideConfiguration, bool> _f$isExporting =
      Field('isExporting', _$isExporting, opt: true, def: false);

  @override
  final MappableFields<SlideConfiguration> fields = const {
    #slideIndex: _f$slideIndex,
    #style: _f$style,
    #_slide: _f$_slide,
    #debug: _f$debug,
    #parts: _f$parts,
    #thumbnailFile: _f$thumbnailFile,
    #_widgets: _f$_widgets,
    #isExporting: _f$isExporting,
  };

  static SlideConfiguration _instantiate(DecodingData data) {
    return SlideConfiguration(
        slideIndex: data.dec(_f$slideIndex),
        style: data.dec(_f$style),
        slide: data.dec(_f$_slide),
        debug: data.dec(_f$debug),
        parts: data.dec(_f$parts),
        thumbnailFile: data.dec(_f$thumbnailFile),
        widgets: data.dec(_f$_widgets),
        isExporting: data.dec(_f$isExporting));
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

  SlideConfigurationCopyWith<SlideConfiguration, SlideConfiguration,
          SlideConfiguration>
      get copyWith => _SlideConfigurationCopyWithImpl(
          this as SlideConfiguration, $identity, $identity);
  @override
  String toString() {
    return SlideConfigurationMapper.ensureInitialized()
        .stringifyValue(this as SlideConfiguration);
  }

  @override
  bool operator ==(Object other) {
    return SlideConfigurationMapper.ensureInitialized()
        .equalsValue(this as SlideConfiguration, other);
  }

  @override
  int get hashCode {
    return SlideConfigurationMapper.ensureInitialized()
        .hashValue(this as SlideConfiguration);
  }
}

extension SlideConfigurationValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SlideConfiguration, $Out> {
  SlideConfigurationCopyWith<$R, SlideConfiguration, $Out>
      get $asSlideConfiguration =>
          $base.as((v, t, t2) => _SlideConfigurationCopyWithImpl(v, t, t2));
}

abstract class SlideConfigurationCopyWith<$R, $In extends SlideConfiguration,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  SlideCopyWith<$R, Slide, Slide> get _slide;
  MapCopyWith<
      $R,
      String,
      Widget Function(Map<String, dynamic>),
      ObjectCopyWith<$R, Widget Function(Map<String, dynamic>),
          Widget Function(Map<String, dynamic>)>> get _widgets;
  $R call(
      {int? slideIndex,
      Style? style,
      Slide? slide,
      bool? debug,
      SlideParts? parts,
      String? thumbnailFile,
      Map<String, Widget Function(Map<String, dynamic>)>? widgets,
      bool? isExporting});
  SlideConfigurationCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _SlideConfigurationCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SlideConfiguration, $Out>
    implements SlideConfigurationCopyWith<$R, SlideConfiguration, $Out> {
  _SlideConfigurationCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SlideConfiguration> $mapper =
      SlideConfigurationMapper.ensureInitialized();
  @override
  SlideCopyWith<$R, Slide, Slide> get _slide =>
      $value._slide.copyWith.$chain((v) => call(slide: v));
  @override
  MapCopyWith<
      $R,
      String,
      Widget Function(Map<String, dynamic>),
      ObjectCopyWith<$R, Widget Function(Map<String, dynamic>),
          Widget Function(Map<String, dynamic>)>> get _widgets => MapCopyWith(
      $value._widgets,
      (v, t) => ObjectCopyWith(v, $identity, t),
      (v) => call(widgets: v));
  @override
  $R call(
          {int? slideIndex,
          Style? style,
          Slide? slide,
          bool? debug,
          Object? parts = $none,
          String? thumbnailFile,
          Map<String, Widget Function(Map<String, dynamic>)>? widgets,
          bool? isExporting}) =>
      $apply(FieldCopyWithData({
        if (slideIndex != null) #slideIndex: slideIndex,
        if (style != null) #style: style,
        if (slide != null) #slide: slide,
        if (debug != null) #debug: debug,
        if (parts != $none) #parts: parts,
        if (thumbnailFile != null) #thumbnailFile: thumbnailFile,
        if (widgets != null) #widgets: widgets,
        if (isExporting != null) #isExporting: isExporting
      }));
  @override
  SlideConfiguration $make(CopyWithData data) => SlideConfiguration(
      slideIndex: data.get(#slideIndex, or: $value.slideIndex),
      style: data.get(#style, or: $value.style),
      slide: data.get(#slide, or: $value._slide),
      debug: data.get(#debug, or: $value.debug),
      parts: data.get(#parts, or: $value.parts),
      thumbnailFile: data.get(#thumbnailFile, or: $value.thumbnailFile),
      widgets: data.get(#widgets, or: $value._widgets),
      isExporting: data.get(#isExporting, or: $value.isExporting));

  @override
  SlideConfigurationCopyWith<$R2, SlideConfiguration, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _SlideConfigurationCopyWithImpl($value, $cast, t);
}
