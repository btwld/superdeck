// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deck_configuration.dart';

class DeckConfigurationMapper extends ClassMapperBase<DeckConfiguration> {
  DeckConfigurationMapper._();

  static DeckConfigurationMapper? _instance;
  static DeckConfigurationMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckConfigurationMapper._());
      MapperContainer.globals.useAll([DirectoryMapper(), FileMapper()]);
    }
    return _instance!;
  }

  @override
  final String id = 'DeckConfiguration';

  static const Field<DeckConfiguration, File> _f$slidesMarkdown = Field(
      'slidesMarkdown', null,
      key: r'slides_markdown', mode: FieldMode.param, opt: true);
  static Directory _$superdeckDir(DeckConfiguration v) => v.superdeckDir;
  static const Field<DeckConfiguration, Directory> _f$superdeckDir = Field(
      'superdeckDir', _$superdeckDir,
      key: r'superdeck_dir', mode: FieldMode.member);
  static File _$deckJson(DeckConfiguration v) => v.deckJson;
  static const Field<DeckConfiguration, File> _f$deckJson =
      Field('deckJson', _$deckJson, key: r'deck_json', mode: FieldMode.member);
  static Directory _$assetsDir(DeckConfiguration v) => v.assetsDir;
  static const Field<DeckConfiguration, Directory> _f$assetsDir = Field(
      'assetsDir', _$assetsDir,
      key: r'assets_dir', mode: FieldMode.member);
  static File _$assetsRefJson(DeckConfiguration v) => v.assetsRefJson;
  static const Field<DeckConfiguration, File> _f$assetsRefJson = Field(
      'assetsRefJson', _$assetsRefJson,
      key: r'assets_ref_json', mode: FieldMode.member);
  static File _$slidesFile(DeckConfiguration v) => v.slidesFile;
  static const Field<DeckConfiguration, File> _f$slidesFile = Field(
      'slidesFile', _$slidesFile,
      key: r'slides_file', mode: FieldMode.member);

  @override
  final MappableFields<DeckConfiguration> fields = const {
    #slidesMarkdown: _f$slidesMarkdown,
    #superdeckDir: _f$superdeckDir,
    #deckJson: _f$deckJson,
    #assetsDir: _f$assetsDir,
    #assetsRefJson: _f$assetsRefJson,
    #slidesFile: _f$slidesFile,
  };
  @override
  final bool ignoreNull = true;

  static DeckConfiguration _instantiate(DecodingData data) {
    return DeckConfiguration(slidesMarkdown: data.dec(_f$slidesMarkdown));
  }

  @override
  final Function instantiate = _instantiate;

  static DeckConfiguration fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeckConfiguration>(map);
  }

  static DeckConfiguration fromJson(String json) {
    return ensureInitialized().decodeJson<DeckConfiguration>(json);
  }
}

mixin DeckConfigurationMappable {
  String toJson() {
    return DeckConfigurationMapper.ensureInitialized()
        .encodeJson<DeckConfiguration>(this as DeckConfiguration);
  }

  Map<String, dynamic> toMap() {
    return DeckConfigurationMapper.ensureInitialized()
        .encodeMap<DeckConfiguration>(this as DeckConfiguration);
  }

  DeckConfigurationCopyWith<DeckConfiguration, DeckConfiguration,
          DeckConfiguration>
      get copyWith => _DeckConfigurationCopyWithImpl(
          this as DeckConfiguration, $identity, $identity);
  @override
  String toString() {
    return DeckConfigurationMapper.ensureInitialized()
        .stringifyValue(this as DeckConfiguration);
  }

  @override
  bool operator ==(Object other) {
    return DeckConfigurationMapper.ensureInitialized()
        .equalsValue(this as DeckConfiguration, other);
  }

  @override
  int get hashCode {
    return DeckConfigurationMapper.ensureInitialized()
        .hashValue(this as DeckConfiguration);
  }
}

extension DeckConfigurationValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeckConfiguration, $Out> {
  DeckConfigurationCopyWith<$R, DeckConfiguration, $Out>
      get $asDeckConfiguration =>
          $base.as((v, t, t2) => _DeckConfigurationCopyWithImpl(v, t, t2));
}

abstract class DeckConfigurationCopyWith<$R, $In extends DeckConfiguration,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({File? slidesMarkdown});
  DeckConfigurationCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _DeckConfigurationCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeckConfiguration, $Out>
    implements DeckConfigurationCopyWith<$R, DeckConfiguration, $Out> {
  _DeckConfigurationCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeckConfiguration> $mapper =
      DeckConfigurationMapper.ensureInitialized();
  @override
  $R call({File? slidesMarkdown}) =>
      $apply(FieldCopyWithData({#slidesMarkdown: slidesMarkdown}));
  @override
  DeckConfiguration $make(CopyWithData data) =>
      DeckConfiguration(slidesMarkdown: data.get(#slidesMarkdown));

  @override
  DeckConfigurationCopyWith<$R2, DeckConfiguration, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _DeckConfigurationCopyWithImpl($value, $cast, t);
}
