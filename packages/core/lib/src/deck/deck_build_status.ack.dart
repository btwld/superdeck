// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'deck_build_status.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

final _deckBuildErrorObject = Ack.object({
  'message': Ack.string(),
}, additionalProperties: true);

final _deckBuildErrorWireSchema = Ack.preserveBoundary(_deckBuildErrorObject);

final _deckBuildErrorSchema = _deckBuildErrorObject.codec<DeckBuildError>(
  decode: _$DeckBuildErrorFromRuntime,
  encode: _$DeckBuildErrorToRuntime,
);

abstract final class DeckBuildErrorSchema {
  static AckSchema<Map<String, Object?>, DeckBuildError> get schema =>
      _deckBuildErrorSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _deckBuildErrorWireSchema;

  static DeckBuildError parse(Object? value, {String? debugName}) =>
      _deckBuildErrorSchema.parse(value, debugName: debugName)!;

  static SchemaResult<DeckBuildError> safeParse(
    Object? value, {
    String? debugName,
  }) => _deckBuildErrorSchema.safeParse(value, debugName: debugName);

  static DeckBuildError fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(
    DeckBuildError value, {
    String? debugName,
  }) => _deckBuildErrorSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    DeckBuildError value, {
    String? debugName,
  }) => _deckBuildErrorSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() =>
      _deckBuildErrorSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_deckBuildErrorSchema).toSchemaModel();
}

DeckBuildError _$DeckBuildErrorFromRuntime(Map<String, Object?> value) =>
    _$DeckBuildErrorFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$DeckBuildErrorToRuntime(DeckBuildError model) =>
    <String, Object?>{..._$DeckBuildErrorToJson(model)};

mixin _$DeckBuildErrorAck {
  DeckBuildError copyWith({String? message}) {
    final self = this as DeckBuildError;
    return DeckBuildError(message: message ?? self.message);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DeckBuildError || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as DeckBuildError;
    return deepEquals(self.message, other.message);
  }

  @override
  int get hashCode {
    final self = this as DeckBuildError;
    return Object.hashAll([runtimeType, deepHashCode(self.message)]);
  }

  @override
  String toString() {
    final self = this as DeckBuildError;
    return 'DeckBuildError(message: ${self.message})';
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(
    DeckBuildErrorSchema.encode(this as DeckBuildError),
  );

  SchemaResult<Map<String, Object?>> safeToJson() =>
      DeckBuildErrorSchema.safeEncode(this as DeckBuildError);
}

String _ackDeckBuildErrorFromRuntimeMessage(Object? value) => value as String;
Object? _ackDeckBuildErrorToRuntimeMessage(String value) => value;

final _deckBuildStatusObject = Ack.object({
  'status': Ack.enumValues(DeckBuildPhase.values),
  'timestamp': Ack.datetime(),
  'slideCount': Ack.integer().optional().nullable(),
  'error': DeckBuildErrorSchema.schema.optional().nullable(),
}, additionalProperties: true);

final _deckBuildStatusWireSchema = Ack.preserveBoundary(_deckBuildStatusObject);

final _deckBuildStatusSchema = _deckBuildStatusObject.codec<DeckBuildStatus>(
  decode: _$DeckBuildStatusFromRuntime,
  encode: _$DeckBuildStatusToRuntime,
);

abstract final class DeckBuildStatusSchema {
  static AckSchema<Map<String, Object?>, DeckBuildStatus> get schema =>
      _deckBuildStatusSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _deckBuildStatusWireSchema;

  static DeckBuildStatus parse(Object? value, {String? debugName}) =>
      _deckBuildStatusSchema.parse(value, debugName: debugName)!;

  static SchemaResult<DeckBuildStatus> safeParse(
    Object? value, {
    String? debugName,
  }) => _deckBuildStatusSchema.safeParse(value, debugName: debugName);

  static DeckBuildStatus fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(
    DeckBuildStatus value, {
    String? debugName,
  }) => _deckBuildStatusSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    DeckBuildStatus value, {
    String? debugName,
  }) => _deckBuildStatusSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() =>
      _deckBuildStatusSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_deckBuildStatusSchema).toSchemaModel();
}

DeckBuildStatus _$DeckBuildStatusFromRuntime(Map<String, Object?> value) =>
    _$DeckBuildStatusFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$DeckBuildStatusToRuntime(DeckBuildStatus model) =>
    <String, Object?>{..._$DeckBuildStatusToJson(model)};

mixin _$DeckBuildStatusAck {
  DeckBuildStatus copyWith({
    DeckBuildPhase? phase,
    DateTime? timestamp,
    int? slideCount,
    DeckBuildError? error,
  }) {
    final self = this as DeckBuildStatus;
    return DeckBuildStatus(
      phase: phase ?? self.phase,
      timestamp: timestamp ?? self.timestamp,
      slideCount: slideCount ?? self.slideCount,
      error: error ?? self.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DeckBuildStatus || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as DeckBuildStatus;
    return deepEquals(self.phase, other.phase) &&
        deepEquals(self.timestamp, other.timestamp) &&
        deepEquals(self.slideCount, other.slideCount) &&
        deepEquals(self.error, other.error);
  }

  @override
  int get hashCode {
    final self = this as DeckBuildStatus;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.phase),
      deepHashCode(self.timestamp),
      deepHashCode(self.slideCount),
      deepHashCode(self.error),
    ]);
  }

  @override
  String toString() {
    final self = this as DeckBuildStatus;
    return 'DeckBuildStatus(phase: ${self.phase}, timestamp: ${self.timestamp}, slideCount: ${self.slideCount}, error: ${self.error})';
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(
    DeckBuildStatusSchema.encode(this as DeckBuildStatus),
  );

  SchemaResult<Map<String, Object?>> safeToJson() =>
      DeckBuildStatusSchema.safeEncode(this as DeckBuildStatus);
}

DeckBuildPhase _ackDeckBuildStatusFromRuntimePhase(Object? value) =>
    value as DeckBuildPhase;
Object? _ackDeckBuildStatusToRuntimePhase(DeckBuildPhase value) => value;
DateTime _ackDeckBuildStatusFromRuntimeTimestamp(Object? value) =>
    value as DateTime;
Object? _ackDeckBuildStatusToRuntimeTimestamp(DateTime value) => value;
int? _ackDeckBuildStatusFromRuntimeSlideCount(Object? value) => value as int?;
Object? _ackDeckBuildStatusToRuntimeSlideCount(int? value) => value;
DeckBuildError? _ackDeckBuildStatusFromRuntimeError(Object? value) =>
    value as DeckBuildError?;
Object? _ackDeckBuildStatusToRuntimeError(DeckBuildError? value) => value;
