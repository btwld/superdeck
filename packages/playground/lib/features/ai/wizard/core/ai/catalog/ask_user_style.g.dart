// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'ask_user_style.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for AskUserStyle
extension type AskUserStyleType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AskUserStyleType parse(Object? data) {
    return _askUserStyleSchema.parseAs(
      data,
      (validated) => AskUserStyleType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<AskUserStyleType> safeParse(Object? data) {
    return _askUserStyleSchema.safeParseAs(
      data,
      (validated) => AskUserStyleType(validated as Map<String, Object?>),
    );
  }

  String get question => _data['question'] as String;

  String? get description => _data['description'] as String?;

  List<String> get themeIds => _$ackListCast<String>(_data['themeIds']);

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);
}
