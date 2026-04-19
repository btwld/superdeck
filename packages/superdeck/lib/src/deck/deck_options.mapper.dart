// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deck_options.dart';

class DeckOptionsMapper extends ClassMapperBase<DeckOptions> {
  DeckOptionsMapper._();

  static DeckOptionsMapper? _instance;
  static DeckOptionsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckOptionsMapper._());
      SlideTemplateMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'DeckOptions';

  static SlideStyle? _$baseStyle(DeckOptions v) => v.baseStyle;
  static const Field<DeckOptions, SlideStyle> _f$baseStyle = Field(
    'baseStyle',
    _$baseStyle,
    opt: true,
  );
  static Map<String, SlideStyle> _$styles(DeckOptions v) => v.styles;
  static const Field<DeckOptions, Map<String, SlideStyle>> _f$styles = Field(
    'styles',
    _$styles,
    opt: true,
    def: const <String, SlideStyle>{},
  );
  static Map<String, Widget Function(Map<String, Object?>)> _$widgets(
    DeckOptions v,
  ) => v.widgets;
  static const Field<
    DeckOptions,
    Map<String, Widget Function(Map<String, Object?>)>
  >
  _f$widgets = Field(
    'widgets',
    _$widgets,
    opt: true,
    def: const <String, WidgetFactory>{},
  );
  static SlideParts _$parts(DeckOptions v) => v.parts;
  static const Field<DeckOptions, SlideParts> _f$parts = Field(
    'parts',
    _$parts,
    opt: true,
    def: const SlideParts(),
  );
  static bool _$debug(DeckOptions v) => v.debug;
  static const Field<DeckOptions, bool> _f$debug = Field(
    'debug',
    _$debug,
    opt: true,
    def: false,
  );
  static Map<String, SlideTemplate> _$templates(DeckOptions v) => v.templates;
  static const Field<DeckOptions, Map<String, SlideTemplate>> _f$templates =
      Field(
        'templates',
        _$templates,
        opt: true,
        def: const <String, SlideTemplate>{},
      );
  static SlideTemplate? _$defaultTemplate(DeckOptions v) => v.defaultTemplate;
  static const Field<DeckOptions, SlideTemplate> _f$defaultTemplate = Field(
    'defaultTemplate',
    _$defaultTemplate,
    opt: true,
  );

  @override
  final MappableFields<DeckOptions> fields = const {
    #baseStyle: _f$baseStyle,
    #styles: _f$styles,
    #widgets: _f$widgets,
    #parts: _f$parts,
    #debug: _f$debug,
    #templates: _f$templates,
    #defaultTemplate: _f$defaultTemplate,
  };

  static DeckOptions _instantiate(DecodingData data) {
    return DeckOptions(
      baseStyle: data.dec(_f$baseStyle),
      styles: data.dec(_f$styles),
      widgets: data.dec(_f$widgets),
      parts: data.dec(_f$parts),
      debug: data.dec(_f$debug),
      templates: data.dec(_f$templates),
      defaultTemplate: data.dec(_f$defaultTemplate),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DeckOptions fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeckOptions>(map);
  }

  static DeckOptions fromJson(String json) {
    return ensureInitialized().decodeJson<DeckOptions>(json);
  }
}

mixin DeckOptionsMappable {
  String toJson() {
    return DeckOptionsMapper.ensureInitialized().encodeJson<DeckOptions>(
      this as DeckOptions,
    );
  }

  Map<String, dynamic> toMap() {
    return DeckOptionsMapper.ensureInitialized().encodeMap<DeckOptions>(
      this as DeckOptions,
    );
  }

  DeckOptionsCopyWith<DeckOptions, DeckOptions, DeckOptions> get copyWith =>
      _DeckOptionsCopyWithImpl<DeckOptions, DeckOptions>(
        this as DeckOptions,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return DeckOptionsMapper.ensureInitialized().stringifyValue(
      this as DeckOptions,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeckOptionsMapper.ensureInitialized().equalsValue(
      this as DeckOptions,
      other,
    );
  }

  @override
  int get hashCode {
    return DeckOptionsMapper.ensureInitialized().hashValue(this as DeckOptions);
  }
}

extension DeckOptionsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeckOptions, $Out> {
  DeckOptionsCopyWith<$R, DeckOptions, $Out> get $asDeckOptions =>
      $base.as((v, t, t2) => _DeckOptionsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeckOptionsCopyWith<$R, $In extends DeckOptions, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    SlideStyle,
    ObjectCopyWith<$R, SlideStyle, SlideStyle>
  >
  get styles;
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
  MapCopyWith<
    $R,
    String,
    SlideTemplate,
    SlideTemplateCopyWith<$R, SlideTemplate, SlideTemplate>
  >
  get templates;
  SlideTemplateCopyWith<$R, SlideTemplate, SlideTemplate>? get defaultTemplate;
  $R call({
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
    Map<String, Widget Function(Map<String, Object?>)>? widgets,
    SlideParts? parts,
    bool? debug,
    Map<String, SlideTemplate>? templates,
    SlideTemplate? defaultTemplate,
  });
  DeckOptionsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DeckOptionsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeckOptions, $Out>
    implements DeckOptionsCopyWith<$R, DeckOptions, $Out> {
  _DeckOptionsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeckOptions> $mapper =
      DeckOptionsMapper.ensureInitialized();
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
  MapCopyWith<
    $R,
    String,
    SlideTemplate,
    SlideTemplateCopyWith<$R, SlideTemplate, SlideTemplate>
  >
  get templates => MapCopyWith(
    $value.templates,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(templates: v),
  );
  @override
  SlideTemplateCopyWith<$R, SlideTemplate, SlideTemplate>?
  get defaultTemplate =>
      $value.defaultTemplate?.copyWith.$chain((v) => call(defaultTemplate: v));
  @override
  $R call({
    Object? baseStyle = $none,
    Map<String, SlideStyle>? styles,
    Map<String, Widget Function(Map<String, Object?>)>? widgets,
    SlideParts? parts,
    bool? debug,
    Map<String, SlideTemplate>? templates,
    Object? defaultTemplate = $none,
  }) => $apply(
    FieldCopyWithData({
      if (baseStyle != $none) #baseStyle: baseStyle,
      if (styles != null) #styles: styles,
      if (widgets != null) #widgets: widgets,
      if (parts != null) #parts: parts,
      if (debug != null) #debug: debug,
      if (templates != null) #templates: templates,
      if (defaultTemplate != $none) #defaultTemplate: defaultTemplate,
    }),
  );
  @override
  DeckOptions $make(CopyWithData data) => DeckOptions(
    baseStyle: data.get(#baseStyle, or: $value.baseStyle),
    styles: data.get(#styles, or: $value.styles),
    widgets: data.get(#widgets, or: $value.widgets),
    parts: data.get(#parts, or: $value.parts),
    debug: data.get(#debug, or: $value.debug),
    templates: data.get(#templates, or: $value.templates),
    defaultTemplate: data.get(#defaultTemplate, or: $value.defaultTemplate),
  );

  @override
  DeckOptionsCopyWith<$R2, DeckOptions, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DeckOptionsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

