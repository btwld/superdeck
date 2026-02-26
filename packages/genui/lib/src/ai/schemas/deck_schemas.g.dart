// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'deck_schemas.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

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

  Map<String, Object?> toJson() => _data;

  String get background => _data['background'] as String;

  String get heading => _data['heading'] as String;

  String get body => _data['body'] as String;

  DeckColorsType copyWith({String? background, String? heading, String? body}) {
    return DeckColorsType.parse({
      'background': background ?? this.background,
      'heading': heading ?? this.heading,
      'body': body ?? this.body,
    });
  }
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

  Map<String, Object?> toJson() => _data;

  HeadlineFont get headline => _data['headline'] as HeadlineFont;

  BodyFont get body => _data['body'] as BodyFont;

  DeckFontsType copyWith({HeadlineFont? headline, BodyFont? body}) {
    return DeckFontsType.parse({
      'headline': headline ?? this.headline,
      'body': body ?? this.body,
    });
  }
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

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  DeckColorsType get colors =>
      DeckColorsType(_data['colors'] as Map<String, Object?>);

  DeckFontsType get fonts =>
      DeckFontsType(_data['fonts'] as Map<String, Object?>);

  DeckStyleType copyWith({
    String? name,
    Map<String, dynamic>? colors,
    Map<String, dynamic>? fonts,
  }) {
    return DeckStyleType.parse({
      'name': name ?? this.name,
      'colors': colors ?? this.colors,
      'fonts': fonts ?? this.fonts,
    });
  }
}

/// Extension type for SlideBlock
extension type SlideBlockType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SlideBlockType parse(Object? data) {
    return _slideBlockSchema.parseAs(
      data,
      (validated) => SlideBlockType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SlideBlockType> safeParse(Object? data) {
    return _slideBlockSchema.safeParseAs(
      data,
      (validated) => SlideBlockType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get type => _data['type'] as String;

  String? get content => _data['content'] as String?;

  String? get name => _data['name'] as String?;

  int? get flex => _data['flex'] as int?;

  String? get align => _data['align'] as String?;

  bool? get scrollable => _data['scrollable'] as bool?;

  SlideBlockType copyWith({
    String? type,
    String? content,
    String? name,
    int? flex,
    String? align,
    bool? scrollable,
  }) {
    return SlideBlockType.parse({
      'type': type ?? this.type,
      'content': content ?? this.content,
      'name': name ?? this.name,
      'flex': flex ?? this.flex,
      'align': align ?? this.align,
      'scrollable': scrollable ?? this.scrollable,
    });
  }
}

/// Extension type for SlideSection
extension type SlideSectionType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SlideSectionType parse(Object? data) {
    return _slideSectionSchema.parseAs(
      data,
      (validated) => SlideSectionType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SlideSectionType> safeParse(Object? data) {
    return _slideSectionSchema.safeParseAs(
      data,
      (validated) => SlideSectionType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get type => _data['type'] as String;

  int? get flex => _data['flex'] as int?;

  String? get align => _data['align'] as String?;

  bool? get scrollable => _data['scrollable'] as bool?;

  List<SlideBlockType> get blocks => (_data['blocks'] as List)
      .map((e) => SlideBlockType(e as Map<String, Object?>))
      .toList();

  SlideSectionType copyWith({
    String? type,
    int? flex,
    String? align,
    bool? scrollable,
    List<SlideBlockType>? blocks,
  }) {
    return SlideSectionType.parse({
      'type': type ?? this.type,
      'flex': flex ?? this.flex,
      'align': align ?? this.align,
      'scrollable': scrollable ?? this.scrollable,
      'blocks': blocks ?? this.blocks,
    });
  }
}

/// Extension type for SlideOptions
extension type SlideOptionsType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SlideOptionsType parse(Object? data) {
    return _slideOptionsSchema.parseAs(
      data,
      (validated) => SlideOptionsType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SlideOptionsType> safeParse(Object? data) {
    return _slideOptionsSchema.safeParseAs(
      data,
      (validated) => SlideOptionsType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String? get title => _data['title'] as String?;

  String? get style => _data['style'] as String?;

  SlideOptionsType copyWith({String? title, String? style}) {
    return SlideOptionsType.parse({
      'title': title ?? this.title,
      'style': style ?? this.style,
    });
  }
}

/// Extension type for Slide
extension type SlideType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SlideType parse(Object? data) {
    return slideSchema.parseAs(
      data,
      (validated) => SlideType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SlideType> safeParse(Object? data) {
    return slideSchema.safeParseAs(
      data,
      (validated) => SlideType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get key => _data['key'] as String;

  SlideOptionsType? get options => _data['options'] != null
      ? SlideOptionsType(_data['options'] as Map<String, Object?>)
      : null;

  List<String>? get comments => _data['comments'] != null
      ? _$ackListCast<String>(_data['comments'])
      : null;

  List<SlideSectionType> get sections => (_data['sections'] as List)
      .map((e) => SlideSectionType(e as Map<String, Object?>))
      .toList();

  SlideType copyWith({
    String? key,
    Map<String, dynamic>? options,
    List<String>? comments,
    List<SlideSectionType>? sections,
  }) {
    return SlideType.parse({
      'key': key ?? this.key,
      'options': options ?? this.options,
      'comments': comments ?? this.comments,
      'sections': sections ?? this.sections,
    });
  }
}

/// Extension type for CreateSlide
extension type CreateSlideType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static CreateSlideType parse(Object? data) {
    return createSlideSchema.parseAs(
      data,
      (validated) => CreateSlideType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<CreateSlideType> safeParse(Object? data) {
    return createSlideSchema.safeParseAs(
      data,
      (validated) => CreateSlideType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String? get key => _data['key'] as String?;

  SlideOptionsType? get options => _data['options'] != null
      ? SlideOptionsType(_data['options'] as Map<String, Object?>)
      : null;

  List<String>? get comments => _data['comments'] != null
      ? _$ackListCast<String>(_data['comments'])
      : null;

  List<SlideSectionType> get sections => (_data['sections'] as List)
      .map((e) => SlideSectionType(e as Map<String, Object?>))
      .toList();

  CreateSlideType copyWith({
    String? key,
    Map<String, dynamic>? options,
    List<String>? comments,
    List<SlideSectionType>? sections,
  }) {
    return CreateSlideType.parse({
      'key': key ?? this.key,
      'options': options ?? this.options,
      'comments': comments ?? this.comments,
      'sections': sections ?? this.sections,
    });
  }
}

/// Extension type for SlideGeneration
extension type SlideGenerationType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SlideGenerationType parse(Object? data) {
    return _slideGenerationSchema.parseAs(
      data,
      (validated) => SlideGenerationType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SlideGenerationType> safeParse(Object? data) {
    return _slideGenerationSchema.safeParseAs(
      data,
      (validated) => SlideGenerationType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  List<SlideType> get slides => (_data['slides'] as List)
      .map((e) => SlideType(e as Map<String, Object?>))
      .toList();

  DeckStyleType get style =>
      DeckStyleType(_data['style'] as Map<String, Object?>);

  SlideGenerationType copyWith({
    List<SlideType>? slides,
    Map<String, dynamic>? style,
  }) {
    return SlideGenerationType.parse({
      'slides': slides ?? this.slides,
      'style': style ?? this.style,
    });
  }
}
