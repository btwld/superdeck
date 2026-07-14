// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'outline_schema.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for DeckPlanSection
extension type DeckPlanSectionType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckPlanSectionType parse(Object? data) {
    return deckPlanSectionSchema.parseAs(
      data,
      (validated) => DeckPlanSectionType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckPlanSectionType> safeParse(Object? data) {
    return deckPlanSectionSchema.safeParseAs(
      data,
      (validated) => DeckPlanSectionType(validated as Map<String, Object?>),
    );
  }

  String get key => _data['key'] as String;

  String get title => _data['title'] as String;

  String get purpose => _data['purpose'] as String;

  String get transition => _data['transition'] as String;

  List<String> get slideKeys => _$ackListCast<String>(_data['slideKeys']);
}

/// Extension type for DeckPlanElement
extension type DeckPlanElementType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckPlanElementType parse(Object? data) {
    return deckPlanElementSchema.parseAs(
      data,
      (validated) => DeckPlanElementType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckPlanElementType> safeParse(Object? data) {
    return deckPlanElementSchema.safeParseAs(
      data,
      (validated) => DeckPlanElementType(validated as Map<String, Object?>),
    );
  }

  String get type => _data['type'] as String;

  String get purpose => _data['purpose'] as String;

  String? get source => _data['source'] as String?;

  String? get widgetName => _data['widgetName'] as String?;
}

/// Extension type for DeckPlanSlide
extension type DeckPlanSlideType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckPlanSlideType parse(Object? data) {
    return deckPlanSlideSchema.parseAs(
      data,
      (validated) => DeckPlanSlideType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckPlanSlideType> safeParse(Object? data) {
    return deckPlanSlideSchema.safeParseAs(
      data,
      (validated) => DeckPlanSlideType(validated as Map<String, Object?>),
    );
  }

  String get key => _data['key'] as String;

  String get title => _data['title'] as String;

  String get purpose => _data['purpose'] as String;

  String get sectionKey => _data['sectionKey'] as String;

  String get assertion => _data['assertion'] as String;

  List<String> get contentUnits => _$ackListCast<String>(_data['contentUnits']);

  String get narrativeRole => _data['narrativeRole'] as String;

  String get contentBrief => _data['contentBrief'] as String;

  String get continuity => _data['continuity'] as String;

  String get composition => _data['composition'] as String;

  String get treatment => _data['treatment'] as String;

  String get density => _data['density'] as String;

  List<DeckPlanElementType>? get elements => _data['elements'] != null
      ? (_data['elements'] as List)
            .map((e) => DeckPlanElementType(e as Map<String, Object?>))
            .toList()
      : null;
}

/// Extension type for DeckPlan
extension type DeckPlanType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckPlanType parse(Object? data) {
    return deckPlanSchema.parseAs(
      data,
      (validated) => DeckPlanType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckPlanType> safeParse(Object? data) {
    return deckPlanSchema.safeParseAs(
      data,
      (validated) => DeckPlanType(validated as Map<String, Object?>),
    );
  }

  String get topic => _data['topic'] as String;

  String get story => _data['story'] as String;

  DeckThemeReferenceType get theme =>
      DeckThemeReferenceType(_data['theme'] as Map<String, Object?>);

  List<DeckPlanSectionType> get sections => (_data['sections'] as List)
      .map((e) => DeckPlanSectionType(e as Map<String, Object?>))
      .toList();

  List<DeckPlanSlideType> get slides => (_data['slides'] as List)
      .map((e) => DeckPlanSlideType(e as Map<String, Object?>))
      .toList();
}
