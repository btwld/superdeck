// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deck_workspace.dart';

class DeckWorkspaceMapper extends ClassMapperBase<DeckWorkspace> {
  DeckWorkspaceMapper._();

  static DeckWorkspaceMapper? _instance;
  static DeckWorkspaceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckWorkspaceMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DeckWorkspace';

  static String _$projectDir(DeckWorkspace v) => v.projectDir;
  static const Field<DeckWorkspace, String> _f$projectDir = Field(
    'projectDir',
    _$projectDir,
    opt: true,
  );
  static String _$slidesPath(DeckWorkspace v) => v.slidesPath;
  static const Field<DeckWorkspace, String> _f$slidesPath = Field(
    'slidesPath',
    _$slidesPath,
    opt: true,
  );
  static String _$outputDir(DeckWorkspace v) => v.outputDir;
  static const Field<DeckWorkspace, String> _f$outputDir = Field(
    'outputDir',
    _$outputDir,
    opt: true,
  );

  @override
  final MappableFields<DeckWorkspace> fields = const {
    #projectDir: _f$projectDir,
    #slidesPath: _f$slidesPath,
    #outputDir: _f$outputDir,
  };

  static DeckWorkspace _instantiate(DecodingData data) {
    return DeckWorkspace(
      projectDir: data.dec(_f$projectDir),
      slidesPath: data.dec(_f$slidesPath),
      outputDir: data.dec(_f$outputDir),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DeckWorkspace fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeckWorkspace>(map);
  }

  static DeckWorkspace fromJson(String json) {
    return ensureInitialized().decodeJson<DeckWorkspace>(json);
  }
}

mixin DeckWorkspaceMappable {
  String toJson() {
    return DeckWorkspaceMapper.ensureInitialized().encodeJson<DeckWorkspace>(
      this as DeckWorkspace,
    );
  }

  Map<String, dynamic> toMap() {
    return DeckWorkspaceMapper.ensureInitialized().encodeMap<DeckWorkspace>(
      this as DeckWorkspace,
    );
  }

  DeckWorkspaceCopyWith<DeckWorkspace, DeckWorkspace, DeckWorkspace>
  get copyWith => _DeckWorkspaceCopyWithImpl<DeckWorkspace, DeckWorkspace>(
    this as DeckWorkspace,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return DeckWorkspaceMapper.ensureInitialized().stringifyValue(
      this as DeckWorkspace,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeckWorkspaceMapper.ensureInitialized().equalsValue(
      this as DeckWorkspace,
      other,
    );
  }

  @override
  int get hashCode {
    return DeckWorkspaceMapper.ensureInitialized().hashValue(
      this as DeckWorkspace,
    );
  }
}

extension DeckWorkspaceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeckWorkspace, $Out> {
  DeckWorkspaceCopyWith<$R, DeckWorkspace, $Out> get $asDeckWorkspace =>
      $base.as((v, t, t2) => _DeckWorkspaceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeckWorkspaceCopyWith<$R, $In extends DeckWorkspace, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? projectDir, String? slidesPath, String? outputDir});
  DeckWorkspaceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DeckWorkspaceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeckWorkspace, $Out>
    implements DeckWorkspaceCopyWith<$R, DeckWorkspace, $Out> {
  _DeckWorkspaceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeckWorkspace> $mapper =
      DeckWorkspaceMapper.ensureInitialized();
  @override
  $R call({
    Object? projectDir = $none,
    Object? slidesPath = $none,
    Object? outputDir = $none,
  }) => $apply(
    FieldCopyWithData({
      if (projectDir != $none) #projectDir: projectDir,
      if (slidesPath != $none) #slidesPath: slidesPath,
      if (outputDir != $none) #outputDir: outputDir,
    }),
  );
  @override
  DeckWorkspace $make(CopyWithData data) => DeckWorkspace(
    projectDir: data.get(#projectDir, or: $value.projectDir),
    slidesPath: data.get(#slidesPath, or: $value.slidesPath),
    outputDir: data.get(#outputDir, or: $value.outputDir),
  );

  @override
  DeckWorkspaceCopyWith<$R2, DeckWorkspace, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DeckWorkspaceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

