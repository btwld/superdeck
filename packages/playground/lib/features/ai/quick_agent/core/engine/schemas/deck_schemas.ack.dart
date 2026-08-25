// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'deck_schemas.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

/// Immutable model generated from `deckBrandColorsSchema`.
/// Only exact palette roles supplied by the user
@AckInfer.jsonSerializable
final class DeckBrandColors {
  DeckBrandColors({
    this.background,
    this.surface,
    this.surfaceAlt,
    this.heading,
    this.body,
    this.accent,
    this.accentContrast,
  });

  factory DeckBrandColors.parse(Object? input) {
    return $ack.parse(input);
  }

  factory DeckBrandColors.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String? background;

  final String? surface;

  final String? surfaceAlt;

  final String? heading;

  final String? body;

  final String? accent;

  final String? accentContrast;

  static final $ack = AckModelAdapter(
    schema: () => deckBrandColorsSchema,
    fromRuntime: DeckBrandColors._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<DeckBrandColors> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  DeckBrandColors copyWith({
    String? background,
    String? surface,
    String? surfaceAlt,
    String? heading,
    String? body,
    String? accent,
    String? accentContrast,
  }) => DeckBrandColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    heading: heading ?? this.heading,
    body: body ?? this.body,
    accent: accent ?? this.accent,
    accentContrast: accentContrast ?? this.accentContrast,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckBrandColors &&
          runtimeType == other.runtimeType &&
          deepEquals(background, other.background) &&
          deepEquals(surface, other.surface) &&
          deepEquals(surfaceAlt, other.surfaceAlt) &&
          deepEquals(heading, other.heading) &&
          deepEquals(body, other.body) &&
          deepEquals(accent, other.accent) &&
          deepEquals(accentContrast, other.accentContrast));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(background),
    deepHashCode(surface),
    deepHashCode(surfaceAlt),
    deepHashCode(heading),
    deepHashCode(body),
    deepHashCode(accent),
    deepHashCode(accentContrast),
  ]);

  @override
  String toString() =>
      'DeckBrandColors(background: $background, surface: $surface, surfaceAlt: $surfaceAlt, heading: $heading, body: $body, accent: $accent, accentContrast: $accentContrast)';

  static DeckBrandColors _fromAckRuntime(Map<String, Object?> value) =>
      _$DeckBrandColorsFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$DeckBrandColorsToJson(this),
  };

  static String? _ackFromRuntimeBackground(Object? value) => value as String?;

  static Object? _ackToRuntimeBackground(String? value) => value;

  static String? _ackFromRuntimeSurface(Object? value) => value as String?;

  static Object? _ackToRuntimeSurface(String? value) => value;

  static String? _ackFromRuntimeSurfaceAlt(Object? value) => value as String?;

  static Object? _ackToRuntimeSurfaceAlt(String? value) => value;

  static String? _ackFromRuntimeHeading(Object? value) => value as String?;

  static Object? _ackToRuntimeHeading(String? value) => value;

  static String? _ackFromRuntimeBody(Object? value) => value as String?;

  static Object? _ackToRuntimeBody(String? value) => value;

  static String? _ackFromRuntimeAccent(Object? value) => value as String?;

  static Object? _ackToRuntimeAccent(String? value) => value;

  static String? _ackFromRuntimeAccentContrast(Object? value) =>
      value as String?;

  static Object? _ackToRuntimeAccentContrast(String? value) => value;
}

/// Immutable model generated from `deckBrandFontsSchema`.
/// Only exact registered font families supplied by the user
@AckInfer.jsonSerializable
final class DeckBrandFonts {
  DeckBrandFonts({this.headline, this.body});

  factory DeckBrandFonts.parse(Object? input) {
    return $ack.parse(input);
  }

  factory DeckBrandFonts.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String? headline;

  final String? body;

  static final $ack = AckModelAdapter(
    schema: () => deckBrandFontsSchema,
    fromRuntime: DeckBrandFonts._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<DeckBrandFonts> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  DeckBrandFonts copyWith({String? headline, String? body}) => DeckBrandFonts(
    headline: headline ?? this.headline,
    body: body ?? this.body,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckBrandFonts &&
          runtimeType == other.runtimeType &&
          deepEquals(headline, other.headline) &&
          deepEquals(body, other.body));

  @override
  int get hashCode =>
      Object.hashAll([runtimeType, deepHashCode(headline), deepHashCode(body)]);

  @override
  String toString() => 'DeckBrandFonts(headline: $headline, body: $body)';

  static DeckBrandFonts _fromAckRuntime(Map<String, Object?> value) =>
      _$DeckBrandFontsFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$DeckBrandFontsToJson(this),
  };

  static String? _ackFromRuntimeHeadline(Object? value) => value as String?;

  static Object? _ackToRuntimeHeadline(String? value) => value;

  static String? _ackFromRuntimeBody(Object? value) => value as String?;

  static Object? _ackToRuntimeBody(String? value) => value;
}

/// Immutable model generated from `deckBrandOverrideSchema`.
/// Validated user-only overrides layered on the selected theme
@AckInfer.jsonSerializable
final class DeckBrandOverride {
  DeckBrandOverride({this.colors, this.fonts});

  factory DeckBrandOverride.parse(Object? input) {
    return $ack.parse(input);
  }

  factory DeckBrandOverride.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final DeckBrandColors? colors;

  final DeckBrandFonts? fonts;

  static final $ack = AckModelAdapter(
    schema: () => deckBrandOverrideSchema,
    fromRuntime: DeckBrandOverride._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<DeckBrandOverride> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  DeckBrandOverride copyWith({
    DeckBrandColors? colors,
    DeckBrandFonts? fonts,
  }) => DeckBrandOverride(
    colors: colors ?? this.colors,
    fonts: fonts ?? this.fonts,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckBrandOverride &&
          runtimeType == other.runtimeType &&
          deepEquals(colors, other.colors) &&
          deepEquals(fonts, other.fonts));

  @override
  int get hashCode =>
      Object.hashAll([runtimeType, deepHashCode(colors), deepHashCode(fonts)]);

  @override
  String toString() => 'DeckBrandOverride(colors: $colors, fonts: $fonts)';

  static DeckBrandOverride _fromAckRuntime(Map<String, Object?> value) =>
      _$DeckBrandOverrideFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$DeckBrandOverrideToJson(this),
  };

  static DeckBrandColors? _ackFromRuntimeColors(Object? value) =>
      switch (value) {
        null => null,
        final fieldValue => DeckBrandColors.$ack.fromRuntime(
          fieldValue as Map<String, Object?>,
        ),
      };

  static Object? _ackToRuntimeColors(DeckBrandColors? value) => switch (value) {
    null => null,
    final fieldValue => DeckBrandColors.$ack.toRuntime(fieldValue),
  };

  static DeckBrandFonts? _ackFromRuntimeFonts(Object? value) => switch (value) {
    null => null,
    final fieldValue => DeckBrandFonts.$ack.fromRuntime(
      fieldValue as Map<String, Object?>,
    ),
  };

  static Object? _ackToRuntimeFonts(DeckBrandFonts? value) => switch (value) {
    null => null,
    final fieldValue => DeckBrandFonts.$ack.toRuntime(fieldValue),
  };
}

/// Immutable model generated from `deckThemeReferenceSchema`.
/// Canonical versioned presentation-theme reference
@AckInfer.jsonSerializable
final class DeckThemeReference {
  DeckThemeReference({
    required this.id,
    required this.version,
    required this.density,
    this.brandOverride,
  });

  factory DeckThemeReference.parse(Object? input) {
    return $ack.parse(input);
  }

  factory DeckThemeReference.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// Stable catalog theme ID
  final String id;

  /// Exact catalog version attached by the application
  final int version;

  /// Resolved deck density supported by the selected theme
  final String density;

  /// Exact user-supplied palette or typography constraints, if any
  final DeckBrandOverride? brandOverride;

  static final $ack = AckModelAdapter(
    schema: () => deckThemeReferenceSchema,
    fromRuntime: DeckThemeReference._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<DeckThemeReference> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  DeckThemeReference copyWith({
    String? id,
    int? version,
    String? density,
    DeckBrandOverride? brandOverride,
  }) => DeckThemeReference(
    id: id ?? this.id,
    version: version ?? this.version,
    density: density ?? this.density,
    brandOverride: brandOverride ?? this.brandOverride,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckThemeReference &&
          runtimeType == other.runtimeType &&
          deepEquals(id, other.id) &&
          deepEquals(version, other.version) &&
          deepEquals(density, other.density) &&
          deepEquals(brandOverride, other.brandOverride));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(id),
    deepHashCode(version),
    deepHashCode(density),
    deepHashCode(brandOverride),
  ]);

  @override
  String toString() =>
      'DeckThemeReference(id: $id, version: $version, density: $density, brandOverride: $brandOverride)';

  static DeckThemeReference _fromAckRuntime(Map<String, Object?> value) =>
      _$DeckThemeReferenceFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$DeckThemeReferenceToJson(this),
  };

  static String _ackFromRuntimeId(Object? value) => value as String;

  static Object? _ackToRuntimeId(String value) => value;

  static int _ackFromRuntimeVersion(Object? value) => value as int;

  static Object? _ackToRuntimeVersion(int value) => value;

  static String _ackFromRuntimeDensity(Object? value) => value as String;

  static Object? _ackToRuntimeDensity(String value) => value;

  static DeckBrandOverride? _ackFromRuntimeBrandOverride(Object? value) =>
      switch (value) {
        null => null,
        final fieldValue => DeckBrandOverride.$ack.fromRuntime(
          fieldValue as Map<String, Object?>,
        ),
      };

  static Object? _ackToRuntimeBrandOverride(DeckBrandOverride? value) =>
      switch (value) {
        null => null,
        final fieldValue => DeckBrandOverride.$ack.toRuntime(fieldValue),
      };
}
