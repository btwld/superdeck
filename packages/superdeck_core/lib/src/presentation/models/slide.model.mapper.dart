// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'slide.model.dart';

class SlideMapper extends ClassMapperBase<Slide> {
  SlideMapper._();

  static SlideMapper? _instance;
  static SlideMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SlideMapper._());
      SlideOptionsMapper.ensureInitialized();
      SectionBlockMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Slide';

  static String _$key(Slide v) => v.key;
  static const Field<Slide, String> _f$key = Field('key', _$key);
  static SlideOptions? _$options(Slide v) => v.options;
  static const Field<Slide, SlideOptions> _f$options =
      Field('options', _$options, opt: true);
  static List<SectionBlock> _$sections(Slide v) => v.sections;
  static const Field<Slide, List<SectionBlock>> _f$sections =
      Field('sections', _$sections, opt: true, def: const []);
  static List<String> _$comments(Slide v) => v.comments;
  static const Field<Slide, List<String>> _f$comments =
      Field('comments', _$comments, opt: true, def: const []);

  @override
  final MappableFields<Slide> fields = const {
    #key: _f$key,
    #options: _f$options,
    #sections: _f$sections,
    #comments: _f$comments,
  };
  @override
  final bool ignoreNull = true;

  static Slide _instantiate(DecodingData data) {
    return Slide(
        key: data.dec(_f$key),
        options: data.dec(_f$options),
        sections: data.dec(_f$sections),
        comments: data.dec(_f$comments));
  }

  @override
  final Function instantiate = _instantiate;

  static Slide fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Slide>(map);
  }

  static Slide fromJson(String json) {
    return ensureInitialized().decodeJson<Slide>(json);
  }
}

mixin SlideMappable {
  String toJson() {
    return SlideMapper.ensureInitialized().encodeJson<Slide>(this as Slide);
  }

  Map<String, dynamic> toMap() {
    return SlideMapper.ensureInitialized().encodeMap<Slide>(this as Slide);
  }

  @override
  String toString() {
    return SlideMapper.ensureInitialized().stringifyValue(this as Slide);
  }

  @override
  bool operator ==(Object other) {
    return SlideMapper.ensureInitialized().equalsValue(this as Slide, other);
  }

  @override
  int get hashCode {
    return SlideMapper.ensureInitialized().hashValue(this as Slide);
  }
}

class SlideOptionsMapper extends ClassMapperBase<SlideOptions> {
  SlideOptionsMapper._();

  static SlideOptionsMapper? _instance;
  static SlideOptionsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SlideOptionsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SlideOptions';

  static String? _$title(SlideOptions v) => v.title;
  static const Field<SlideOptions, String> _f$title =
      Field('title', _$title, opt: true);
  static String? _$style(SlideOptions v) => v.style;
  static const Field<SlideOptions, String> _f$style =
      Field('style', _$style, opt: true);
  static Map<String, Object?> _$args(SlideOptions v) => v.args;
  static const Field<SlideOptions, Map<String, Object?>> _f$args =
      Field('args', _$args, opt: true, def: const {});

  @override
  final MappableFields<SlideOptions> fields = const {
    #title: _f$title,
    #style: _f$style,
    #args: _f$args,
  };
  @override
  final bool ignoreNull = true;

  @override
  final MappingHook hook = const UnmappedPropertiesHook('args');
  static SlideOptions _instantiate(DecodingData data) {
    return SlideOptions(
        title: data.dec(_f$title),
        style: data.dec(_f$style),
        args: data.dec(_f$args));
  }

  @override
  final Function instantiate = _instantiate;

  static SlideOptions fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SlideOptions>(map);
  }

  static SlideOptions fromJson(String json) {
    return ensureInitialized().decodeJson<SlideOptions>(json);
  }
}

mixin SlideOptionsMappable {
  String toJson() {
    return SlideOptionsMapper.ensureInitialized()
        .encodeJson<SlideOptions>(this as SlideOptions);
  }

  Map<String, dynamic> toMap() {
    return SlideOptionsMapper.ensureInitialized()
        .encodeMap<SlideOptions>(this as SlideOptions);
  }

  @override
  String toString() {
    return SlideOptionsMapper.ensureInitialized()
        .stringifyValue(this as SlideOptions);
  }

  @override
  bool operator ==(Object other) {
    return SlideOptionsMapper.ensureInitialized()
        .equalsValue(this as SlideOptions, other);
  }

  @override
  int get hashCode {
    return SlideOptionsMapper.ensureInitialized()
        .hashValue(this as SlideOptions);
  }
}
