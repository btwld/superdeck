// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'genui_action_schema.dart';

/// Extension type for ActionContextValue
extension type ActionContextValueType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ActionContextValueType parse(Object? data) {
    return _actionContextValueSchema.parseAs(
      data,
      (validated) => ActionContextValueType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ActionContextValueType> safeParse(Object? data) {
    return _actionContextValueSchema.safeParseAs(
      data,
      (validated) => ActionContextValueType(validated as Map<String, Object?>),
    );
  }

  String? get path => _data['path'] as String?;

  String? get literalString => _data['literalString'] as String?;

  double? get literalNumber => _data['literalNumber'] as double?;

  bool? get literalBoolean => _data['literalBoolean'] as bool?;
}

/// Extension type for ActionContextEntry
extension type ActionContextEntryType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ActionContextEntryType parse(Object? data) {
    return _actionContextEntrySchema.parseAs(
      data,
      (validated) => ActionContextEntryType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ActionContextEntryType> safeParse(Object? data) {
    return _actionContextEntrySchema.safeParseAs(
      data,
      (validated) => ActionContextEntryType(validated as Map<String, Object?>),
    );
  }

  String get key => _data['key'] as String;

  ActionContextValueType get value =>
      ActionContextValueType(_data['value'] as Map<String, Object?>);
}

/// Extension type for Action
extension type ActionType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ActionType parse(Object? data) {
    return actionSchema.parseAs(
      data,
      (validated) => ActionType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ActionType> safeParse(Object? data) {
    return actionSchema.safeParseAs(
      data,
      (validated) => ActionType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;

  List<ActionContextEntryType>? get context => _data['context'] != null
      ? (_data['context'] as List)
            .map((e) => ActionContextEntryType(e as Map<String, Object?>))
            .toList()
      : null;
}
