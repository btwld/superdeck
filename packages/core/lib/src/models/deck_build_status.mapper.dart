// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deck_build_status.dart';

class DeckBuildPhaseMapper extends EnumMapper<DeckBuildPhase> {
  DeckBuildPhaseMapper._();

  static DeckBuildPhaseMapper? _instance;
  static DeckBuildPhaseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckBuildPhaseMapper._());
    }
    return _instance!;
  }

  static DeckBuildPhase fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  DeckBuildPhase decode(dynamic value) {
    switch (value) {
      case r'unknown':
        return DeckBuildPhase.unknown;
      case r'building':
        return DeckBuildPhase.building;
      case r'success':
        return DeckBuildPhase.success;
      case r'failure':
        return DeckBuildPhase.failure;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(DeckBuildPhase self) {
    switch (self) {
      case DeckBuildPhase.unknown:
        return r'unknown';
      case DeckBuildPhase.building:
        return r'building';
      case DeckBuildPhase.success:
        return r'success';
      case DeckBuildPhase.failure:
        return r'failure';
    }
  }
}

extension DeckBuildPhaseMapperExtension on DeckBuildPhase {
  String toValue() {
    DeckBuildPhaseMapper.ensureInitialized();
    return MapperContainer.globals.toValue<DeckBuildPhase>(this) as String;
  }
}

class DeckBuildErrorMapper extends ClassMapperBase<DeckBuildError> {
  DeckBuildErrorMapper._();

  static DeckBuildErrorMapper? _instance;
  static DeckBuildErrorMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckBuildErrorMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DeckBuildError';

  static String _$message(DeckBuildError v) => v.message;
  static const Field<DeckBuildError, String> _f$message = Field(
    'message',
    _$message,
  );

  @override
  final MappableFields<DeckBuildError> fields = const {#message: _f$message};

  static DeckBuildError _instantiate(DecodingData data) {
    return DeckBuildError(message: data.dec(_f$message));
  }

  @override
  final Function instantiate = _instantiate;

  static DeckBuildError fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeckBuildError>(map);
  }

  static DeckBuildError fromJson(String json) {
    return ensureInitialized().decodeJson<DeckBuildError>(json);
  }
}

mixin DeckBuildErrorMappable {
  String toJson() {
    return DeckBuildErrorMapper.ensureInitialized().encodeJson<DeckBuildError>(
      this as DeckBuildError,
    );
  }

  Map<String, dynamic> toMap() {
    return DeckBuildErrorMapper.ensureInitialized().encodeMap<DeckBuildError>(
      this as DeckBuildError,
    );
  }

  DeckBuildErrorCopyWith<DeckBuildError, DeckBuildError, DeckBuildError>
  get copyWith => _DeckBuildErrorCopyWithImpl<DeckBuildError, DeckBuildError>(
    this as DeckBuildError,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return DeckBuildErrorMapper.ensureInitialized().stringifyValue(
      this as DeckBuildError,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeckBuildErrorMapper.ensureInitialized().equalsValue(
      this as DeckBuildError,
      other,
    );
  }

  @override
  int get hashCode {
    return DeckBuildErrorMapper.ensureInitialized().hashValue(
      this as DeckBuildError,
    );
  }
}

extension DeckBuildErrorValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeckBuildError, $Out> {
  DeckBuildErrorCopyWith<$R, DeckBuildError, $Out> get $asDeckBuildError =>
      $base.as((v, t, t2) => _DeckBuildErrorCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeckBuildErrorCopyWith<$R, $In extends DeckBuildError, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? message});
  DeckBuildErrorCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DeckBuildErrorCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeckBuildError, $Out>
    implements DeckBuildErrorCopyWith<$R, DeckBuildError, $Out> {
  _DeckBuildErrorCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeckBuildError> $mapper =
      DeckBuildErrorMapper.ensureInitialized();
  @override
  $R call({String? message}) =>
      $apply(FieldCopyWithData({if (message != null) #message: message}));
  @override
  DeckBuildError $make(CopyWithData data) =>
      DeckBuildError(message: data.get(#message, or: $value.message));

  @override
  DeckBuildErrorCopyWith<$R2, DeckBuildError, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DeckBuildErrorCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class DeckBuildStatusMapper extends ClassMapperBase<DeckBuildStatus> {
  DeckBuildStatusMapper._();

  static DeckBuildStatusMapper? _instance;
  static DeckBuildStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckBuildStatusMapper._());
      DeckBuildPhaseMapper.ensureInitialized();
      DeckBuildErrorMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'DeckBuildStatus';

  static DeckBuildPhase _$phase(DeckBuildStatus v) => v.phase;
  static const Field<DeckBuildStatus, DeckBuildPhase> _f$phase = Field(
    'phase',
    _$phase,
    key: r'status',
  );
  static DateTime _$timestamp(DeckBuildStatus v) => v.timestamp;
  static const Field<DeckBuildStatus, DateTime> _f$timestamp = Field(
    'timestamp',
    _$timestamp,
  );
  static int? _$slideCount(DeckBuildStatus v) => v.slideCount;
  static const Field<DeckBuildStatus, int> _f$slideCount = Field(
    'slideCount',
    _$slideCount,
    opt: true,
  );
  static DeckBuildError? _$error(DeckBuildStatus v) => v.error;
  static const Field<DeckBuildStatus, DeckBuildError> _f$error = Field(
    'error',
    _$error,
    opt: true,
  );

  @override
  final MappableFields<DeckBuildStatus> fields = const {
    #phase: _f$phase,
    #timestamp: _f$timestamp,
    #slideCount: _f$slideCount,
    #error: _f$error,
  };

  static DeckBuildStatus _instantiate(DecodingData data) {
    return DeckBuildStatus(
      phase: data.dec(_f$phase),
      timestamp: data.dec(_f$timestamp),
      slideCount: data.dec(_f$slideCount),
      error: data.dec(_f$error),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DeckBuildStatus fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeckBuildStatus>(map);
  }

  static DeckBuildStatus fromJson(String json) {
    return ensureInitialized().decodeJson<DeckBuildStatus>(json);
  }
}

mixin DeckBuildStatusMappable {
  String toJson() {
    return DeckBuildStatusMapper.ensureInitialized()
        .encodeJson<DeckBuildStatus>(this as DeckBuildStatus);
  }

  Map<String, dynamic> toMap() {
    return DeckBuildStatusMapper.ensureInitialized().encodeMap<DeckBuildStatus>(
      this as DeckBuildStatus,
    );
  }

  DeckBuildStatusCopyWith<DeckBuildStatus, DeckBuildStatus, DeckBuildStatus>
  get copyWith =>
      _DeckBuildStatusCopyWithImpl<DeckBuildStatus, DeckBuildStatus>(
        this as DeckBuildStatus,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return DeckBuildStatusMapper.ensureInitialized().stringifyValue(
      this as DeckBuildStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeckBuildStatusMapper.ensureInitialized().equalsValue(
      this as DeckBuildStatus,
      other,
    );
  }

  @override
  int get hashCode {
    return DeckBuildStatusMapper.ensureInitialized().hashValue(
      this as DeckBuildStatus,
    );
  }
}

extension DeckBuildStatusValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeckBuildStatus, $Out> {
  DeckBuildStatusCopyWith<$R, DeckBuildStatus, $Out> get $asDeckBuildStatus =>
      $base.as((v, t, t2) => _DeckBuildStatusCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeckBuildStatusCopyWith<$R, $In extends DeckBuildStatus, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  DeckBuildErrorCopyWith<$R, DeckBuildError, DeckBuildError>? get error;
  $R call({
    DeckBuildPhase? phase,
    DateTime? timestamp,
    int? slideCount,
    DeckBuildError? error,
  });
  DeckBuildStatusCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DeckBuildStatusCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeckBuildStatus, $Out>
    implements DeckBuildStatusCopyWith<$R, DeckBuildStatus, $Out> {
  _DeckBuildStatusCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeckBuildStatus> $mapper =
      DeckBuildStatusMapper.ensureInitialized();
  @override
  DeckBuildErrorCopyWith<$R, DeckBuildError, DeckBuildError>? get error =>
      $value.error?.copyWith.$chain((v) => call(error: v));
  @override
  $R call({
    DeckBuildPhase? phase,
    DateTime? timestamp,
    Object? slideCount = $none,
    Object? error = $none,
  }) => $apply(
    FieldCopyWithData({
      if (phase != null) #phase: phase,
      if (timestamp != null) #timestamp: timestamp,
      if (slideCount != $none) #slideCount: slideCount,
      if (error != $none) #error: error,
    }),
  );
  @override
  DeckBuildStatus $make(CopyWithData data) => DeckBuildStatus(
    phase: data.get(#phase, or: $value.phase),
    timestamp: data.get(#timestamp, or: $value.timestamp),
    slideCount: data.get(#slideCount, or: $value.slideCount),
    error: data.get(#error, or: $value.error),
  );

  @override
  DeckBuildStatusCopyWith<$R2, DeckBuildStatus, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DeckBuildStatusCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

