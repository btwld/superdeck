// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'ask_user_text.dart';

/// Extension type for AskUserText
extension type AskUserTextType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AskUserTextType parse(Object? data) {
    return _askUserTextSchema.parseAs(
      data,
      (validated) => AskUserTextType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<AskUserTextType> safeParse(Object? data) {
    return _askUserTextSchema.safeParseAs(
      data,
      (validated) => AskUserTextType(validated as Map<String, Object?>),
    );
  }

  String get question => _data['question'] as String;

  String? get description => _data['description'] as String?;

  String? get placeholder => _data['placeholder'] as String?;

  int? get maxLength => _data['maxLength'] as int?;

  bool? get multiline => _data['multiline'] as bool?;

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);
}
