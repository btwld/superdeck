// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'deck_schemas.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

DeckBrandColors _$DeckBrandColorsFromJson(Map<String, dynamic> json) =>
    DeckBrandColors(
      background: DeckBrandColors._ackFromRuntimeBackground(json['background']),
      surface: DeckBrandColors._ackFromRuntimeSurface(json['surface']),
      surfaceAlt: DeckBrandColors._ackFromRuntimeSurfaceAlt(json['surfaceAlt']),
      heading: DeckBrandColors._ackFromRuntimeHeading(json['heading']),
      body: DeckBrandColors._ackFromRuntimeBody(json['body']),
      accent: DeckBrandColors._ackFromRuntimeAccent(json['accent']),
      accentContrast: DeckBrandColors._ackFromRuntimeAccentContrast(
        json['accentContrast'],
      ),
    );

Map<String, dynamic> _$DeckBrandColorsToJson(
  DeckBrandColors instance,
) => <String, dynamic>{
  'background': ?DeckBrandColors._ackToRuntimeBackground(instance.background),
  'surface': ?DeckBrandColors._ackToRuntimeSurface(instance.surface),
  'surfaceAlt': ?DeckBrandColors._ackToRuntimeSurfaceAlt(instance.surfaceAlt),
  'heading': ?DeckBrandColors._ackToRuntimeHeading(instance.heading),
  'body': ?DeckBrandColors._ackToRuntimeBody(instance.body),
  'accent': ?DeckBrandColors._ackToRuntimeAccent(instance.accent),
  'accentContrast': ?DeckBrandColors._ackToRuntimeAccentContrast(
    instance.accentContrast,
  ),
};

DeckBrandFonts _$DeckBrandFontsFromJson(Map<String, dynamic> json) =>
    DeckBrandFonts(
      headline: DeckBrandFonts._ackFromRuntimeHeadline(json['headline']),
      body: DeckBrandFonts._ackFromRuntimeBody(json['body']),
    );

Map<String, dynamic> _$DeckBrandFontsToJson(DeckBrandFonts instance) =>
    <String, dynamic>{
      'headline': ?DeckBrandFonts._ackToRuntimeHeadline(instance.headline),
      'body': ?DeckBrandFonts._ackToRuntimeBody(instance.body),
    };

DeckBrandOverride _$DeckBrandOverrideFromJson(Map<String, dynamic> json) =>
    DeckBrandOverride(
      colors: DeckBrandOverride._ackFromRuntimeColors(json['colors']),
      fonts: DeckBrandOverride._ackFromRuntimeFonts(json['fonts']),
    );

Map<String, dynamic> _$DeckBrandOverrideToJson(DeckBrandOverride instance) =>
    <String, dynamic>{
      'colors': ?DeckBrandOverride._ackToRuntimeColors(instance.colors),
      'fonts': ?DeckBrandOverride._ackToRuntimeFonts(instance.fonts),
    };

DeckThemeReference _$DeckThemeReferenceFromJson(Map<String, dynamic> json) =>
    DeckThemeReference(
      id: DeckThemeReference._ackFromRuntimeId(json['id']),
      version: DeckThemeReference._ackFromRuntimeVersion(json['version']),
      density: DeckThemeReference._ackFromRuntimeDensity(json['density']),
      brandOverride: DeckThemeReference._ackFromRuntimeBrandOverride(
        json['brandOverride'],
      ),
    );

Map<String, dynamic> _$DeckThemeReferenceToJson(DeckThemeReference instance) =>
    <String, dynamic>{
      'id': DeckThemeReference._ackToRuntimeId(instance.id),
      'version': DeckThemeReference._ackToRuntimeVersion(instance.version),
      'density': DeckThemeReference._ackToRuntimeDensity(instance.density),
      'brandOverride': ?DeckThemeReference._ackToRuntimeBrandOverride(
        instance.brandOverride,
      ),
    };
