// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'deck_schemas.dart';

/// Extension type for DeckBrandColors
extension type DeckBrandColorsType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckBrandColorsType parse(Object? data) {
    return deckBrandColorsSchema.parseAs(
      data,
      (validated) => DeckBrandColorsType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckBrandColorsType> safeParse(Object? data) {
    return deckBrandColorsSchema.safeParseAs(
      data,
      (validated) => DeckBrandColorsType(validated as Map<String, Object?>),
    );
  }

  String? get background => _data['background'] as String?;

  String? get surface => _data['surface'] as String?;

  String? get surfaceAlt => _data['surfaceAlt'] as String?;

  String? get heading => _data['heading'] as String?;

  String? get body => _data['body'] as String?;

  String? get accent => _data['accent'] as String?;

  String? get accentContrast => _data['accentContrast'] as String?;
}

/// Extension type for DeckBrandFonts
extension type DeckBrandFontsType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckBrandFontsType parse(Object? data) {
    return deckBrandFontsSchema.parseAs(
      data,
      (validated) => DeckBrandFontsType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckBrandFontsType> safeParse(Object? data) {
    return deckBrandFontsSchema.safeParseAs(
      data,
      (validated) => DeckBrandFontsType(validated as Map<String, Object?>),
    );
  }

  String? get headline => _data['headline'] as String?;

  String? get body => _data['body'] as String?;
}

/// Extension type for DeckBrandOverride
extension type DeckBrandOverrideType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckBrandOverrideType parse(Object? data) {
    return deckBrandOverrideSchema.parseAs(
      data,
      (validated) => DeckBrandOverrideType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckBrandOverrideType> safeParse(Object? data) {
    return deckBrandOverrideSchema.safeParseAs(
      data,
      (validated) => DeckBrandOverrideType(validated as Map<String, Object?>),
    );
  }

  DeckBrandColorsType? get colors => _data['colors'] != null
      ? DeckBrandColorsType(_data['colors'] as Map<String, Object?>)
      : null;

  DeckBrandFontsType? get fonts => _data['fonts'] != null
      ? DeckBrandFontsType(_data['fonts'] as Map<String, Object?>)
      : null;
}

/// Extension type for DeckThemeReference
extension type DeckThemeReferenceType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckThemeReferenceType parse(Object? data) {
    return deckThemeReferenceSchema.parseAs(
      data,
      (validated) => DeckThemeReferenceType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckThemeReferenceType> safeParse(Object? data) {
    return deckThemeReferenceSchema.safeParseAs(
      data,
      (validated) => DeckThemeReferenceType(validated as Map<String, Object?>),
    );
  }

  String get id => _data['id'] as String;

  int get version => _data['version'] as int;

  String get density => _data['density'] as String;

  DeckBrandOverrideType? get brandOverride => _data['brandOverride'] != null
      ? DeckBrandOverrideType(_data['brandOverride'] as Map<String, Object?>)
      : null;
}
