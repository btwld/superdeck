// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deck_config.dart';

class DeckConfigMapper extends ClassMapperBase<DeckConfig> {
  DeckConfigMapper._();

  static DeckConfigMapper? _instance;
  static DeckConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckConfigMapper._());
      LocalDeckConfigMapper.ensureInitialized();
      BundledDeckConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'DeckConfig';

  static String? _$projectDir(DeckConfig v) => v.projectDir;
  static const Field<DeckConfig, String> _f$projectDir = Field(
    'projectDir',
    _$projectDir,
    opt: true,
  );
  static String? _$outputDir(DeckConfig v) => v.outputDir;
  static const Field<DeckConfig, String> _f$outputDir = Field(
    'outputDir',
    _$outputDir,
    opt: true,
  );
  static String? _$assetsPath(DeckConfig v) => v.assetsPath;
  static const Field<DeckConfig, String> _f$assetsPath = Field(
    'assetsPath',
    _$assetsPath,
    opt: true,
  );

  @override
  final MappableFields<DeckConfig> fields = const {
    #projectDir: _f$projectDir,
    #outputDir: _f$outputDir,
    #assetsPath: _f$assetsPath,
  };

  static DeckConfig _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'DeckConfig',
      'type',
      '${data.value['type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DeckConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeckConfig>(map);
  }

  static DeckConfig fromJson(String json) {
    return ensureInitialized().decodeJson<DeckConfig>(json);
  }
}

mixin DeckConfigMappable {
  String toJson();
  Map<String, dynamic> toMap();
  DeckConfigCopyWith<DeckConfig, DeckConfig, DeckConfig> get copyWith;
}

abstract class DeckConfigCopyWith<$R, $In extends DeckConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? projectDir, String? outputDir, String? assetsPath});
  DeckConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class LocalDeckConfigMapper extends SubClassMapperBase<LocalDeckConfig> {
  LocalDeckConfigMapper._();

  static LocalDeckConfigMapper? _instance;
  static LocalDeckConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LocalDeckConfigMapper._());
      DeckConfigMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'LocalDeckConfig';

  static String _$slidesPath(LocalDeckConfig v) => v.slidesPath;
  static const Field<LocalDeckConfig, String> _f$slidesPath = Field(
    'slidesPath',
    _$slidesPath,
    opt: true,
    def: 'slides.md',
  );
  static bool _$watch(LocalDeckConfig v) => v.watch;
  static const Field<LocalDeckConfig, bool> _f$watch = Field(
    'watch',
    _$watch,
    opt: true,
    def: false,
  );
  static String? _$projectDir(LocalDeckConfig v) => v.projectDir;
  static const Field<LocalDeckConfig, String> _f$projectDir = Field(
    'projectDir',
    _$projectDir,
    opt: true,
  );
  static String? _$outputDir(LocalDeckConfig v) => v.outputDir;
  static const Field<LocalDeckConfig, String> _f$outputDir = Field(
    'outputDir',
    _$outputDir,
    opt: true,
  );
  static String? _$assetsPath(LocalDeckConfig v) => v.assetsPath;
  static const Field<LocalDeckConfig, String> _f$assetsPath = Field(
    'assetsPath',
    _$assetsPath,
    opt: true,
  );

  @override
  final MappableFields<LocalDeckConfig> fields = const {
    #slidesPath: _f$slidesPath,
    #watch: _f$watch,
    #projectDir: _f$projectDir,
    #outputDir: _f$outputDir,
    #assetsPath: _f$assetsPath,
  };

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'local';
  @override
  late final ClassMapperBase superMapper = DeckConfigMapper.ensureInitialized();

  static LocalDeckConfig _instantiate(DecodingData data) {
    return LocalDeckConfig(
      slidesPath: data.dec(_f$slidesPath),
      watch: data.dec(_f$watch),
      projectDir: data.dec(_f$projectDir),
      outputDir: data.dec(_f$outputDir),
      assetsPath: data.dec(_f$assetsPath),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LocalDeckConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LocalDeckConfig>(map);
  }

  static LocalDeckConfig fromJson(String json) {
    return ensureInitialized().decodeJson<LocalDeckConfig>(json);
  }
}

mixin LocalDeckConfigMappable {
  String toJson() {
    return LocalDeckConfigMapper.ensureInitialized()
        .encodeJson<LocalDeckConfig>(this as LocalDeckConfig);
  }

  Map<String, dynamic> toMap() {
    return LocalDeckConfigMapper.ensureInitialized().encodeMap<LocalDeckConfig>(
      this as LocalDeckConfig,
    );
  }

  LocalDeckConfigCopyWith<LocalDeckConfig, LocalDeckConfig, LocalDeckConfig>
  get copyWith =>
      _LocalDeckConfigCopyWithImpl<LocalDeckConfig, LocalDeckConfig>(
        this as LocalDeckConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LocalDeckConfigMapper.ensureInitialized().stringifyValue(
      this as LocalDeckConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return LocalDeckConfigMapper.ensureInitialized().equalsValue(
      this as LocalDeckConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return LocalDeckConfigMapper.ensureInitialized().hashValue(
      this as LocalDeckConfig,
    );
  }
}

extension LocalDeckConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LocalDeckConfig, $Out> {
  LocalDeckConfigCopyWith<$R, LocalDeckConfig, $Out> get $asLocalDeckConfig =>
      $base.as((v, t, t2) => _LocalDeckConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LocalDeckConfigCopyWith<$R, $In extends LocalDeckConfig, $Out>
    implements DeckConfigCopyWith<$R, $In, $Out> {
  @override
  $R call({
    String? slidesPath,
    bool? watch,
    String? projectDir,
    String? outputDir,
    String? assetsPath,
  });
  LocalDeckConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _LocalDeckConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LocalDeckConfig, $Out>
    implements LocalDeckConfigCopyWith<$R, LocalDeckConfig, $Out> {
  _LocalDeckConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LocalDeckConfig> $mapper =
      LocalDeckConfigMapper.ensureInitialized();
  @override
  $R call({
    String? slidesPath,
    bool? watch,
    Object? projectDir = $none,
    Object? outputDir = $none,
    Object? assetsPath = $none,
  }) => $apply(
    FieldCopyWithData({
      if (slidesPath != null) #slidesPath: slidesPath,
      if (watch != null) #watch: watch,
      if (projectDir != $none) #projectDir: projectDir,
      if (outputDir != $none) #outputDir: outputDir,
      if (assetsPath != $none) #assetsPath: assetsPath,
    }),
  );
  @override
  LocalDeckConfig $make(CopyWithData data) => LocalDeckConfig(
    slidesPath: data.get(#slidesPath, or: $value.slidesPath),
    watch: data.get(#watch, or: $value.watch),
    projectDir: data.get(#projectDir, or: $value.projectDir),
    outputDir: data.get(#outputDir, or: $value.outputDir),
    assetsPath: data.get(#assetsPath, or: $value.assetsPath),
  );

  @override
  LocalDeckConfigCopyWith<$R2, LocalDeckConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _LocalDeckConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class BundledDeckConfigMapper extends SubClassMapperBase<BundledDeckConfig> {
  BundledDeckConfigMapper._();

  static BundledDeckConfigMapper? _instance;
  static BundledDeckConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BundledDeckConfigMapper._());
      DeckConfigMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'BundledDeckConfig';

  static String _$deckAssetPath(BundledDeckConfig v) => v.deckAssetPath;
  static const Field<BundledDeckConfig, String> _f$deckAssetPath = Field(
    'deckAssetPath',
    _$deckAssetPath,
    opt: true,
    def: DeckArtifacts.bundledDeckAssetPath,
  );
  static String? _$projectDir(BundledDeckConfig v) => v.projectDir;
  static const Field<BundledDeckConfig, String> _f$projectDir = Field(
    'projectDir',
    _$projectDir,
    opt: true,
  );
  static String? _$outputDir(BundledDeckConfig v) => v.outputDir;
  static const Field<BundledDeckConfig, String> _f$outputDir = Field(
    'outputDir',
    _$outputDir,
    opt: true,
  );
  static String? _$assetsPath(BundledDeckConfig v) => v.assetsPath;
  static const Field<BundledDeckConfig, String> _f$assetsPath = Field(
    'assetsPath',
    _$assetsPath,
    opt: true,
  );

  @override
  final MappableFields<BundledDeckConfig> fields = const {
    #deckAssetPath: _f$deckAssetPath,
    #projectDir: _f$projectDir,
    #outputDir: _f$outputDir,
    #assetsPath: _f$assetsPath,
  };

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'bundle';
  @override
  late final ClassMapperBase superMapper = DeckConfigMapper.ensureInitialized();

  static BundledDeckConfig _instantiate(DecodingData data) {
    return BundledDeckConfig(
      deckAssetPath: data.dec(_f$deckAssetPath),
      projectDir: data.dec(_f$projectDir),
      outputDir: data.dec(_f$outputDir),
      assetsPath: data.dec(_f$assetsPath),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static BundledDeckConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BundledDeckConfig>(map);
  }

  static BundledDeckConfig fromJson(String json) {
    return ensureInitialized().decodeJson<BundledDeckConfig>(json);
  }
}

mixin BundledDeckConfigMappable {
  String toJson() {
    return BundledDeckConfigMapper.ensureInitialized()
        .encodeJson<BundledDeckConfig>(this as BundledDeckConfig);
  }

  Map<String, dynamic> toMap() {
    return BundledDeckConfigMapper.ensureInitialized()
        .encodeMap<BundledDeckConfig>(this as BundledDeckConfig);
  }

  BundledDeckConfigCopyWith<
    BundledDeckConfig,
    BundledDeckConfig,
    BundledDeckConfig
  >
  get copyWith =>
      _BundledDeckConfigCopyWithImpl<BundledDeckConfig, BundledDeckConfig>(
        this as BundledDeckConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return BundledDeckConfigMapper.ensureInitialized().stringifyValue(
      this as BundledDeckConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return BundledDeckConfigMapper.ensureInitialized().equalsValue(
      this as BundledDeckConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return BundledDeckConfigMapper.ensureInitialized().hashValue(
      this as BundledDeckConfig,
    );
  }
}

extension BundledDeckConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, BundledDeckConfig, $Out> {
  BundledDeckConfigCopyWith<$R, BundledDeckConfig, $Out>
  get $asBundledDeckConfig => $base.as(
    (v, t, t2) => _BundledDeckConfigCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class BundledDeckConfigCopyWith<
  $R,
  $In extends BundledDeckConfig,
  $Out
>
    implements DeckConfigCopyWith<$R, $In, $Out> {
  @override
  $R call({
    String? deckAssetPath,
    String? projectDir,
    String? outputDir,
    String? assetsPath,
  });
  BundledDeckConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _BundledDeckConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, BundledDeckConfig, $Out>
    implements BundledDeckConfigCopyWith<$R, BundledDeckConfig, $Out> {
  _BundledDeckConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<BundledDeckConfig> $mapper =
      BundledDeckConfigMapper.ensureInitialized();
  @override
  $R call({
    String? deckAssetPath,
    Object? projectDir = $none,
    Object? outputDir = $none,
    Object? assetsPath = $none,
  }) => $apply(
    FieldCopyWithData({
      if (deckAssetPath != null) #deckAssetPath: deckAssetPath,
      if (projectDir != $none) #projectDir: projectDir,
      if (outputDir != $none) #outputDir: outputDir,
      if (assetsPath != $none) #assetsPath: assetsPath,
    }),
  );
  @override
  BundledDeckConfig $make(CopyWithData data) => BundledDeckConfig(
    deckAssetPath: data.get(#deckAssetPath, or: $value.deckAssetPath),
    projectDir: data.get(#projectDir, or: $value.projectDir),
    outputDir: data.get(#outputDir, or: $value.outputDir),
    assetsPath: data.get(#assetsPath, or: $value.assetsPath),
  );

  @override
  BundledDeckConfigCopyWith<$R2, BundledDeckConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _BundledDeckConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

