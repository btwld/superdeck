// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'ask_user_image_style.dart';

/// Extension type for AskUserImageStyle
extension type AskUserImageStyleType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AskUserImageStyleType parse(Object? data) {
    return _askUserImageStyleSchema.parseAs(
      data,
      (validated) => AskUserImageStyleType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<AskUserImageStyleType> safeParse(Object? data) {
    return _askUserImageStyleSchema.safeParseAs(
      data,
      (validated) => AskUserImageStyleType(validated as Map<String, Object?>),
    );
  }

  String get question => _data['question'] as String;

  String? get description => _data['description'] as String?;

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);
}
