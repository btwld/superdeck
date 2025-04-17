// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'presentation_config.model.dart';

class PresentationConfigMapper extends ClassMapperBase<PresentationConfig> {
  PresentationConfigMapper._();

  static PresentationConfigMapper? _instance;
  static PresentationConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PresentationConfigMapper._());
      MapperContainer.globals.useAll([DirectoryMapper(), FileMapper()]);
    }
    return _instance!;
  }

  @override
  final String id = 'PresentationConfig';

  static const Field<PresentationConfig, File> _f$slidesMarkdown = Field(
      'slidesMarkdown', null,
      key: r'slides_markdown', mode: FieldMode.param, opt: true);
  static Directory _$superdeckDir(PresentationConfig v) => v.superdeckDir;
  static const Field<PresentationConfig, Directory> _f$superdeckDir = Field(
      'superdeckDir', _$superdeckDir,
      key: r'superdeck_dir', mode: FieldMode.member);
  static File _$deckJson(PresentationConfig v) => v.deckJson;
  static const Field<PresentationConfig, File> _f$deckJson =
      Field('deckJson', _$deckJson, key: r'deck_json', mode: FieldMode.member);
  static Directory _$assetsDir(PresentationConfig v) => v.assetsDir;
  static const Field<PresentationConfig, Directory> _f$assetsDir = Field(
      'assetsDir', _$assetsDir,
      key: r'assets_dir', mode: FieldMode.member);
  static File _$assetsRefJson(PresentationConfig v) => v.assetsRefJson;
  static const Field<PresentationConfig, File> _f$assetsRefJson = Field(
      'assetsRefJson', _$assetsRefJson,
      key: r'assets_ref_json', mode: FieldMode.member);
  static File _$slidesFile(PresentationConfig v) => v.slidesFile;
  static const Field<PresentationConfig, File> _f$slidesFile = Field(
      'slidesFile', _$slidesFile,
      key: r'slides_file', mode: FieldMode.member);

  @override
  final MappableFields<PresentationConfig> fields = const {
    #slidesMarkdown: _f$slidesMarkdown,
    #superdeckDir: _f$superdeckDir,
    #deckJson: _f$deckJson,
    #assetsDir: _f$assetsDir,
    #assetsRefJson: _f$assetsRefJson,
    #slidesFile: _f$slidesFile,
  };
  @override
  final bool ignoreNull = true;

  static PresentationConfig _instantiate(DecodingData data) {
    return PresentationConfig(slidesMarkdown: data.dec(_f$slidesMarkdown));
  }

  @override
  final Function instantiate = _instantiate;

  static PresentationConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PresentationConfig>(map);
  }

  static PresentationConfig fromJson(String json) {
    return ensureInitialized().decodeJson<PresentationConfig>(json);
  }
}

mixin PresentationConfigMappable {
  String toJson() {
    return PresentationConfigMapper.ensureInitialized()
        .encodeJson<PresentationConfig>(this as PresentationConfig);
  }

  Map<String, dynamic> toMap() {
    return PresentationConfigMapper.ensureInitialized()
        .encodeMap<PresentationConfig>(this as PresentationConfig);
  }

  @override
  String toString() {
    return PresentationConfigMapper.ensureInitialized()
        .stringifyValue(this as PresentationConfig);
  }

  @override
  bool operator ==(Object other) {
    return PresentationConfigMapper.ensureInitialized()
        .equalsValue(this as PresentationConfig, other);
  }

  @override
  int get hashCode {
    return PresentationConfigMapper.ensureInitialized()
        .hashValue(this as PresentationConfig);
  }
}
