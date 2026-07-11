// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'deck_schemas.dart';

/// Extension type for DeckColors
extension type DeckColorsType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckColorsType parse(Object? data) {
    return _deckColorsSchema.parseAs(
      data,
      (validated) => DeckColorsType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckColorsType> safeParse(Object? data) {
    return _deckColorsSchema.safeParseAs(
      data,
      (validated) => DeckColorsType(validated as Map<String, Object?>),
    );
  }

  String get background => _data['background'] as String;

  String get heading => _data['heading'] as String;

  String get body => _data['body'] as String;
}

/// Extension type for DeckFonts
extension type DeckFontsType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckFontsType parse(Object? data) {
    return _deckFontsSchema.parseAs(
      data,
      (validated) => DeckFontsType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckFontsType> safeParse(Object? data) {
    return _deckFontsSchema.safeParseAs(
      data,
      (validated) => DeckFontsType(validated as Map<String, Object?>),
    );
  }

  HeadlineFont get headline => _data['headline'] as HeadlineFont;

  BodyFont get body => _data['body'] as BodyFont;
}

/// Extension type for DeckStyle
extension type DeckStyleType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckStyleType parse(Object? data) {
    return styleSchema.parseAs(
      data,
      (validated) => DeckStyleType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckStyleType> safeParse(Object? data) {
    return styleSchema.safeParseAs(
      data,
      (validated) => DeckStyleType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;

  DeckColorsType get colors =>
      DeckColorsType(_data['colors'] as Map<String, Object?>);

  DeckFontsType get fonts =>
      DeckFontsType(_data['fonts'] as Map<String, Object?>);
}
