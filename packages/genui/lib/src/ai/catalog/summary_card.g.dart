// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'summary_card.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for SummaryItem
extension type SummaryItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SummaryItemType parse(Object? data) {
    return _summaryItemSchema.parseAs(
      data,
      (validated) => SummaryItemType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SummaryItemType> safeParse(Object? data) {
    return _summaryItemSchema.safeParseAs(
      data,
      (validated) => SummaryItemType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  SummaryItemKind? get kind => _data['kind'] as SummaryItemKind?;

  String get label => _data['label'] as String;

  String? get title => _data['title'] as String?;

  String? get description => _data['description'] as String?;

  String? get text => _data['text'] as String?;

  List<String>? get colors =>
      _data['colors'] != null ? _$ackListCast<String>(_data['colors']) : null;

  HeadlineFont? get headlineFont => _data['headlineFont'] as HeadlineFont?;

  BodyFont? get bodyFont => _data['bodyFont'] as BodyFont?;

  ImageStyle? get imageStyleId => _data['imageStyleId'] as ImageStyle?;

  SummaryItemType copyWith({
    SummaryItemKind? kind,
    String? label,
    String? title,
    String? description,
    String? text,
    List<String>? colors,
    HeadlineFont? headlineFont,
    BodyFont? bodyFont,
    ImageStyle? imageStyleId,
  }) {
    return SummaryItemType.parse({
      'kind': kind ?? this.kind,
      'label': label ?? this.label,
      'title': title ?? this.title,
      'description': description ?? this.description,
      'text': text ?? this.text,
      'colors': colors ?? this.colors,
      'headlineFont': headlineFont ?? this.headlineFont,
      'bodyFont': bodyFont ?? this.bodyFont,
      'imageStyleId': imageStyleId ?? this.imageStyleId,
    });
  }
}

/// Extension type for SummaryCard
extension type SummaryCardType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SummaryCardType parse(Object? data) {
    return _summaryCardSchema.parseAs(
      data,
      (validated) => SummaryCardType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SummaryCardType> safeParse(Object? data) {
    return _summaryCardSchema.safeParseAs(
      data,
      (validated) => SummaryCardType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get title => _data['title'] as String;

  List<SummaryItemType> get items => (_data['items'] as List)
      .map((e) => SummaryItemType(e as Map<String, Object?>))
      .toList();

  ActionType get generateSlidesAction =>
      ActionType(_data['generateSlidesAction'] as Map<String, Object?>);

  SummaryCardType copyWith({
    String? title,
    List<SummaryItemType>? items,
    Map<String, dynamic>? generateSlidesAction,
  }) {
    return SummaryCardType.parse({
      'title': title ?? this.title,
      'items': items ?? this.items,
      'generateSlidesAction': generateSlidesAction ?? this.generateSlidesAction,
    });
  }
}
