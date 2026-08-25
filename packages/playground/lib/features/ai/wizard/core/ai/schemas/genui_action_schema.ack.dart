// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'genui_action_schema.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

/// Immutable model generated from `_actionContextValueSchema`.
/// Context value - use path or one of the literal types
@AckInfer.jsonSerializable
final class ActionContextValue {
  ActionContextValue({
    this.path,
    this.literalString,
    this.literalNumber,
    this.literalBoolean,
  });

  factory ActionContextValue.parse(Object? input) {
    return $ack.parse(input);
  }

  factory ActionContextValue.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// Data model path binding
  final String? path;

  /// Literal string value
  final String? literalString;

  /// Literal number value
  final double? literalNumber;

  /// Literal boolean value
  final bool? literalBoolean;

  static final $ack = AckModelAdapter(
    schema: () => _actionContextValueSchema,
    fromRuntime: ActionContextValue._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<ActionContextValue> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  ActionContextValue copyWith({
    String? path,
    String? literalString,
    double? literalNumber,
    bool? literalBoolean,
  }) => ActionContextValue(
    path: path ?? this.path,
    literalString: literalString ?? this.literalString,
    literalNumber: literalNumber ?? this.literalNumber,
    literalBoolean: literalBoolean ?? this.literalBoolean,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActionContextValue &&
          runtimeType == other.runtimeType &&
          deepEquals(path, other.path) &&
          deepEquals(literalString, other.literalString) &&
          deepEquals(literalNumber, other.literalNumber) &&
          deepEquals(literalBoolean, other.literalBoolean));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(path),
    deepHashCode(literalString),
    deepHashCode(literalNumber),
    deepHashCode(literalBoolean),
  ]);

  @override
  String toString() =>
      'ActionContextValue(path: $path, literalString: $literalString, literalNumber: $literalNumber, literalBoolean: $literalBoolean)';

  static ActionContextValue _fromAckRuntime(Map<String, Object?> value) =>
      _$ActionContextValueFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$ActionContextValueToJson(this),
  };

  static String? _ackFromRuntimePath(Object? value) => value as String?;

  static Object? _ackToRuntimePath(String? value) => value;

  static String? _ackFromRuntimeLiteralString(Object? value) =>
      value as String?;

  static Object? _ackToRuntimeLiteralString(String? value) => value;

  static double? _ackFromRuntimeLiteralNumber(Object? value) =>
      value as double?;

  static Object? _ackToRuntimeLiteralNumber(double? value) => value;

  static bool? _ackFromRuntimeLiteralBoolean(Object? value) => value as bool?;

  static Object? _ackToRuntimeLiteralBoolean(bool? value) => value;
}

/// Immutable model generated from `_actionContextEntrySchema`.
/// Context entry with key and value
@AckInfer.jsonSerializable
final class ActionContextEntry {
  ActionContextEntry({required this.key, required this.value});

  factory ActionContextEntry.parse(Object? input) {
    return $ack.parse(input);
  }

  factory ActionContextEntry.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// Context key
  final String key;

  final ActionContextValue value;

  static final $ack = AckModelAdapter(
    schema: () => _actionContextEntrySchema,
    fromRuntime: ActionContextEntry._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<ActionContextEntry> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  ActionContextEntry copyWith({String? key, ActionContextValue? value}) =>
      ActionContextEntry(key: key ?? this.key, value: value ?? this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActionContextEntry &&
          runtimeType == other.runtimeType &&
          deepEquals(key, other.key) &&
          deepEquals(value, other.value));

  @override
  int get hashCode =>
      Object.hashAll([runtimeType, deepHashCode(key), deepHashCode(value)]);

  @override
  String toString() => 'ActionContextEntry(key: $key, value: $value)';

  static ActionContextEntry _fromAckRuntime(Map<String, Object?> value) =>
      _$ActionContextEntryFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$ActionContextEntryToJson(this),
  };

  static String _ackFromRuntimeKey(Object? value) => value as String;

  static Object? _ackToRuntimeKey(String value) => value;

  static ActionContextValue _ackFromRuntimeValue(Object? value) =>
      ActionContextValue.$ack.fromRuntime(value as Map<String, Object?>);

  static Object? _ackToRuntimeValue(ActionContextValue value) =>
      ActionContextValue.$ack.toRuntime(value);
}

/// Immutable model generated from `actionSchema`.
/// GenUI action with name and context binding
@AckInfer.jsonSerializable
final class GenUiAction {
  GenUiAction({required this.name, List<ActionContextEntry>? context})
    : context = switch (context) {
        null => null,
        final fieldValue => List<ActionContextEntry>.unmodifiable(
          fieldValue.map((item) => item),
        ),
      };

  factory GenUiAction.parse(Object? input) {
    return $ack.parse(input);
  }

  factory GenUiAction.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// Action name to dispatch
  final String name;

  /// List of context data to include with the action
  final List<ActionContextEntry>? context;

  static final $ack = AckModelAdapter(
    schema: () => actionSchema,
    fromRuntime: GenUiAction._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<GenUiAction> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  GenUiAction copyWith({String? name, List<ActionContextEntry>? context}) =>
      GenUiAction(name: name ?? this.name, context: context ?? this.context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenUiAction &&
          runtimeType == other.runtimeType &&
          deepEquals(name, other.name) &&
          deepEquals(context, other.context));

  @override
  int get hashCode =>
      Object.hashAll([runtimeType, deepHashCode(name), deepHashCode(context)]);

  @override
  String toString() => 'GenUiAction(name: $name, context: $context)';

  static GenUiAction _fromAckRuntime(Map<String, Object?> value) =>
      _$GenUiActionFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$GenUiActionToJson(this),
  };

  static String _ackFromRuntimeName(Object? value) => value as String;

  static Object? _ackToRuntimeName(String value) => value;

  static List<ActionContextEntry>? _ackFromRuntimeContext(Object? value) =>
      switch (value) {
        null => null,
        final fieldValue =>
          (fieldValue as List)
              .map(
                (item) => ActionContextEntry.$ack.fromRuntime(
                  item as Map<String, Object?>,
                ),
              )
              .toList(),
      };

  static Object? _ackToRuntimeContext(List<ActionContextEntry>? value) =>
      switch (value) {
        null => null,
        final fieldValue =>
          fieldValue
              .map((item) => ActionContextEntry.$ack.toRuntime(item))
              .toList(growable: false),
      };
}
