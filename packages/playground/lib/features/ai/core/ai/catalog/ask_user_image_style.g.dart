// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'ask_user_image_style.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

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

  String get subject => _data['subject'] as String;

  List<ImageStyle> get imageStyles =>
      _$ackListCast<ImageStyle>(_data['imageStyles']);

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);
}
