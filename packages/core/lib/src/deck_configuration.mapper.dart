// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deck_configuration.dart';

class DeckConfigurationMapper extends ClassMapperBase<DeckConfiguration> {
  DeckConfigurationMapper._();

  static DeckConfigurationMapper? _instance;
  static DeckConfigurationMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckConfigurationMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DeckConfiguration';

  static String? _$projectDir(DeckConfiguration v) => v.projectDir;
  static const Field<DeckConfiguration, String> _f$projectDir = Field(
    'projectDir',
    _$projectDir,
    opt: true,
  );
  static String? _$slidesPath(DeckConfiguration v) => v.slidesPath;
  static const Field<DeckConfiguration, String> _f$slidesPath = Field(
    'slidesPath',
    _$slidesPath,
    opt: true,
  );
  static String? _$outputDir(DeckConfiguration v) => v.outputDir;
  static const Field<DeckConfiguration, String> _f$outputDir = Field(
    'outputDir',
    _$outputDir,
    opt: true,
  );
  static String? _$assetsPath(DeckConfiguration v) => v.assetsPath;
  static const Field<DeckConfiguration, String> _f$assetsPath = Field(
    'assetsPath',
    _$assetsPath,
    opt: true,
  );
  static Directory _$superdeckDir(DeckConfiguration v) => v.superdeckDir;
  static const Field<DeckConfiguration, Directory> _f$superdeckDir = Field(
    'superdeckDir',
    _$superdeckDir,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<DeckConfiguration> fields = const {
    #projectDir: _f$projectDir,
    #slidesPath: _f$slidesPath,
    #outputDir: _f$outputDir,
    #assetsPath: _f$assetsPath,
    #superdeckDir: _f$superdeckDir,
  };
  @override
  final bool ignoreNull = true;

  static DeckConfiguration _instantiate(DecodingData data) {
    return DeckConfiguration(
      projectDir: data.dec(_f$projectDir),
      slidesPath: data.dec(_f$slidesPath),
      outputDir: data.dec(_f$outputDir),
      assetsPath: data.dec(_f$assetsPath),
    );
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

  DeckConfigurationCopyWith<
    DeckConfiguration,
    DeckConfiguration,
    DeckConfiguration
  >
  get copyWith =>
      _DeckConfigurationCopyWithImpl<DeckConfiguration, DeckConfiguration>(
        this as DeckConfiguration,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return DeckConfigurationMapper.ensureInitialized().stringifyValue(
      this as DeckConfiguration,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeckConfigurationMapper.ensureInitialized().equalsValue(
      this as DeckConfiguration,
      other,
    );
  }

  @override
  int get hashCode {
    return DeckConfigurationMapper.ensureInitialized().hashValue(
      this as DeckConfiguration,
    );
  }
}

extension DeckConfigurationValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeckConfiguration, $Out> {
  DeckConfigurationCopyWith<$R, DeckConfiguration, $Out>
  get $asDeckConfiguration => $base.as(
    (v, t, t2) => _DeckConfigurationCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DeckConfigurationCopyWith<
  $R,
  $In extends DeckConfiguration,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? projectDir,
    String? slidesPath,
    String? outputDir,
    String? assetsPath,
  });
  DeckConfigurationCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DeckConfigurationCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeckConfiguration, $Out>
    implements DeckConfigurationCopyWith<$R, DeckConfiguration, $Out> {
  _DeckConfigurationCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeckConfiguration> $mapper =
      DeckConfigurationMapper.ensureInitialized();
  @override
  $R call({
    Object? projectDir = $none,
    Object? slidesPath = $none,
    Object? outputDir = $none,
    Object? assetsPath = $none,
  }) => $apply(
    FieldCopyWithData({
      if (projectDir != $none) #projectDir: projectDir,
      if (slidesPath != $none) #slidesPath: slidesPath,
      if (outputDir != $none) #outputDir: outputDir,
      if (assetsPath != $none) #assetsPath: assetsPath,
    }),
  );
  @override
  DeckConfiguration $make(CopyWithData data) => DeckConfiguration(
    projectDir: data.get(#projectDir, or: $value.projectDir),
    slidesPath: data.get(#slidesPath, or: $value.slidesPath),
    outputDir: data.get(#outputDir, or: $value.outputDir),
    assetsPath: data.get(#assetsPath, or: $value.assetsPath),
  );

  @override
  DeckConfigurationCopyWith<$R2, DeckConfiguration, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DeckConfigurationCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

