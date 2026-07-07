// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'ask_user_style.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for StyleOption
extension type StyleOptionType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static StyleOptionType parse(Object? data) {
    return _styleOptionSchema.parseAs(
      data,
      (validated) => StyleOptionType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<StyleOptionType> safeParse(Object? data) {
    return _styleOptionSchema.safeParseAs(
      data,
      (validated) => StyleOptionType(validated as Map<String, Object?>),
    );
  }

  String get id => _data['id'] as String;

  String get title => _data['title'] as String;

  String get description => _data['description'] as String;

  List<String> get colors => _$ackListCast<String>(_data['colors']);

  HeadlineFont get headlineFont => _data['headlineFont'] as HeadlineFont;

  BodyFont get bodyFont => _data['bodyFont'] as BodyFont;
}

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

  List<StyleOptionType> get styleOptions => (_data['styleOptions'] as List)
      .map((e) => StyleOptionType(e as Map<String, Object?>))
      .toList();

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);
}
