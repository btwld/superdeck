// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'deck_tools_schemas.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for DeckToolSlideOptions
extension type DeckToolSlideOptionsType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckToolSlideOptionsType parse(Object? data) {
    return _deckToolSlideOptionsSchema.parseAs(
      data,
      (validated) =>
          DeckToolSlideOptionsType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckToolSlideOptionsType> safeParse(Object? data) {
    return _deckToolSlideOptionsSchema.safeParseAs(
      data,
      (validated) =>
          DeckToolSlideOptionsType(validated as Map<String, Object?>),
    );
  }

  String? get title => _data['title'] as String?;

  String? get style => _data['style'] as String?;

  String? get template => _data['template'] as String?;

  Map<String, Object?> get args => Map.fromEntries(
    _data.entries.where(
      (e) => e.key != 'title' && e.key != 'style' && e.key != 'template',
    ),
  );
}

/// Extension type for DeckToolBlock
extension type DeckToolBlockType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  String get type => _data['type'] as String;

  static DeckToolBlockType parse(Object? data) {
    return _deckToolBlockSchema.parseAs(data, (validated) {
      final map = validated as Map<String, Object?>;
      return switch (map['type']) {
        'block' => DeckToolContentBlockType(map),
        'widget' => DeckToolWidgetBlockType(map),
        _ => throw StateError('Unknown type: ${map['type']}'),
      };
    });
  }

  static SchemaResult<DeckToolBlockType> safeParse(Object? data) {
    return _deckToolBlockSchema.safeParseAs(data, (validated) {
      final map = validated as Map<String, Object?>;
      return switch (map['type']) {
        'block' => DeckToolContentBlockType(map),
        'widget' => DeckToolWidgetBlockType(map),
        _ => throw StateError('Unknown type: ${map['type']}'),
      };
    });
  }
}

/// Extension type for DeckToolContentBlock
extension type DeckToolContentBlockType(Map<String, Object?> _data)
    implements DeckToolBlockType, Map<String, Object?> {
  String get type => _data['type'] as String;

  static DeckToolContentBlockType parse(Object? data) {
    return _deckToolBlockSchema
        .effectiveBranch('block')
        .parseAs(
          data,
          (validated) =>
              DeckToolContentBlockType(validated as Map<String, Object?>),
        );
  }

  static SchemaResult<DeckToolContentBlockType> safeParse(Object? data) {
    return _deckToolBlockSchema
        .effectiveBranch('block')
        .safeParseAs(
          data,
          (validated) =>
              DeckToolContentBlockType(validated as Map<String, Object?>),
        );
  }

  String? get content => _data['content'] as String?;

  String? get align => _data['align'] as String?;

  int? get flex => _data['flex'] as int?;

  bool? get scrollable => _data['scrollable'] as bool?;

  Map<String, Object?> get args => Map.fromEntries(
    _data.entries.where(
      (e) =>
          e.key != 'type' &&
          e.key != 'content' &&
          e.key != 'align' &&
          e.key != 'flex' &&
          e.key != 'scrollable',
    ),
  );
}

/// Extension type for DeckToolWidgetBlock
extension type DeckToolWidgetBlockType(Map<String, Object?> _data)
    implements DeckToolBlockType, Map<String, Object?> {
  String get type => _data['type'] as String;

  static DeckToolWidgetBlockType parse(Object? data) {
    return _deckToolBlockSchema
        .effectiveBranch('widget')
        .parseAs(
          data,
          (validated) =>
              DeckToolWidgetBlockType(validated as Map<String, Object?>),
        );
  }

  static SchemaResult<DeckToolWidgetBlockType> safeParse(Object? data) {
    return _deckToolBlockSchema
        .effectiveBranch('widget')
        .safeParseAs(
          data,
          (validated) =>
              DeckToolWidgetBlockType(validated as Map<String, Object?>),
        );
  }

  String get name => _data['name'] as String;

  String? get align => _data['align'] as String?;

  int? get flex => _data['flex'] as int?;

  bool? get scrollable => _data['scrollable'] as bool?;

  Map<String, Object?> get args => Map.fromEntries(
    _data.entries.where(
      (e) =>
          e.key != 'type' &&
          e.key != 'name' &&
          e.key != 'align' &&
          e.key != 'flex' &&
          e.key != 'scrollable',
    ),
  );
}

/// Extension type for DeckToolSlideSection
extension type DeckToolSlideSectionType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckToolSlideSectionType parse(Object? data) {
    return _deckToolSlideSectionSchema.parseAs(
      data,
      (validated) =>
          DeckToolSlideSectionType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckToolSlideSectionType> safeParse(Object? data) {
    return _deckToolSlideSectionSchema.safeParseAs(
      data,
      (validated) =>
          DeckToolSlideSectionType(validated as Map<String, Object?>),
    );
  }

  String? get type => _data['type'] as String?;

  String? get align => _data['align'] as String?;

  int? get flex => _data['flex'] as int?;

  List<DeckToolBlockType>? get blocks => _data['blocks'] != null
      ? (_data['blocks'] as List)
            .map((e) => DeckToolBlockType(e as Map<String, Object?>))
            .toList()
      : null;
}

/// Extension type for DeckToolSlide
extension type DeckToolSlideType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckToolSlideType parse(Object? data) {
    return _deckToolSlideSchema.parseAs(
      data,
      (validated) => DeckToolSlideType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckToolSlideType> safeParse(Object? data) {
    return _deckToolSlideSchema.safeParseAs(
      data,
      (validated) => DeckToolSlideType(validated as Map<String, Object?>),
    );
  }

  DeckToolSlideOptionsType? get options => _data['options'] != null
      ? DeckToolSlideOptionsType(_data['options'] as Map<String, Object?>)
      : null;

  List<String>? get comments => _data['comments'] != null
      ? _$ackListCast<String>(_data['comments'])
      : null;

  List<DeckToolSlideSectionType> get sections => (_data['sections'] as List)
      .map((e) => DeckToolSlideSectionType(e as Map<String, Object?>))
      .toList();
}

/// Extension type for ReadSlideRequest
extension type ReadSlideRequestType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ReadSlideRequestType parse(Object? data) {
    return _readSlideRequestSchema.parseAs(
      data,
      (validated) => ReadSlideRequestType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ReadSlideRequestType> safeParse(Object? data) {
    return _readSlideRequestSchema.safeParseAs(
      data,
      (validated) => ReadSlideRequestType(validated as Map<String, Object?>),
    );
  }

  int get index => _data['index'] as int;
}

/// Extension type for CreateSlideRequest
extension type CreateSlideRequestType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static CreateSlideRequestType parse(Object? data) {
    return _createSlideRequestSchema.parseAs(
      data,
      (validated) => CreateSlideRequestType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<CreateSlideRequestType> safeParse(Object? data) {
    return _createSlideRequestSchema.safeParseAs(
      data,
      (validated) => CreateSlideRequestType(validated as Map<String, Object?>),
    );
  }

  DeckToolSlideType get slide =>
      DeckToolSlideType(_data['slide'] as Map<String, Object?>);

  int? get atIndex => _data['atIndex'] as int?;
}

/// Extension type for UpdateSlideRequest
extension type UpdateSlideRequestType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UpdateSlideRequestType parse(Object? data) {
    return _updateSlideRequestSchema.parseAs(
      data,
      (validated) => UpdateSlideRequestType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<UpdateSlideRequestType> safeParse(Object? data) {
    return _updateSlideRequestSchema.safeParseAs(
      data,
      (validated) => UpdateSlideRequestType(validated as Map<String, Object?>),
    );
  }

  int get index => _data['index'] as int;

  DeckToolSlideType get slide =>
      DeckToolSlideType(_data['slide'] as Map<String, Object?>);
}

/// Extension type for DeleteSlideRequest
extension type DeleteSlideRequestType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeleteSlideRequestType parse(Object? data) {
    return _deleteSlideRequestSchema.parseAs(
      data,
      (validated) => DeleteSlideRequestType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeleteSlideRequestType> safeParse(Object? data) {
    return _deleteSlideRequestSchema.safeParseAs(
      data,
      (validated) => DeleteSlideRequestType(validated as Map<String, Object?>),
    );
  }

  int get index => _data['index'] as int;
}

/// Extension type for MoveSlideRequest
extension type MoveSlideRequestType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static MoveSlideRequestType parse(Object? data) {
    return _moveSlideRequestSchema.parseAs(
      data,
      (validated) => MoveSlideRequestType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<MoveSlideRequestType> safeParse(Object? data) {
    return _moveSlideRequestSchema.safeParseAs(
      data,
      (validated) => MoveSlideRequestType(validated as Map<String, Object?>),
    );
  }

  int get fromIndex => _data['fromIndex'] as int;

  int get toIndex => _data['toIndex'] as int;
}

/// Extension type for UpdateStyleRequest
extension type UpdateStyleRequestType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UpdateStyleRequestType parse(Object? data) {
    return _updateStyleRequestSchema.parseAs(
      data,
      (validated) => UpdateStyleRequestType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<UpdateStyleRequestType> safeParse(Object? data) {
    return _updateStyleRequestSchema.safeParseAs(
      data,
      (validated) => UpdateStyleRequestType(validated as Map<String, Object?>),
    );
  }

  DeckStyleType get style =>
      DeckStyleType(_data['style'] as Map<String, Object?>);
}

/// Extension type for SlideSummary
extension type SlideSummaryType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SlideSummaryType parse(Object? data) {
    return _slideSummarySchema.parseAs(
      data,
      (validated) => SlideSummaryType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SlideSummaryType> safeParse(Object? data) {
    return _slideSummarySchema.safeParseAs(
      data,
      (validated) => SlideSummaryType(validated as Map<String, Object?>),
    );
  }

  int get index => _data['index'] as int;

  String? get title => _data['title'] as String?;
}

/// Extension type for DeckSnapshot
extension type DeckSnapshotType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DeckSnapshotType parse(Object? data) {
    return _deckSnapshotSchema.parseAs(
      data,
      (validated) => DeckSnapshotType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DeckSnapshotType> safeParse(Object? data) {
    return _deckSnapshotSchema.safeParseAs(
      data,
      (validated) => DeckSnapshotType(validated as Map<String, Object?>),
    );
  }

  int get totalSlides => _data['totalSlides'] as int;

  List<SlideSummaryType> get slides => (_data['slides'] as List)
      .map((e) => SlideSummaryType(e as Map<String, Object?>))
      .toList();
}

/// Extension type for ReadSlideResult
extension type ReadSlideResultType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ReadSlideResultType parse(Object? data) {
    return _readSlideResultSchema.parseAs(
      data,
      (validated) => ReadSlideResultType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ReadSlideResultType> safeParse(Object? data) {
    return _readSlideResultSchema.safeParseAs(
      data,
      (validated) => ReadSlideResultType(validated as Map<String, Object?>),
    );
  }

  int get index => _data['index'] as int;

  String? get title => _data['title'] as String?;

  DeckToolSlideType get slide =>
      DeckToolSlideType(_data['slide'] as Map<String, Object?>);

  String get thumbnailBase64 => _data['thumbnailBase64'] as String;

  DeckSnapshotType get deck =>
      DeckSnapshotType(_data['deck'] as Map<String, Object?>);
}

/// Extension type for SlideMutationResult
extension type SlideMutationResultType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SlideMutationResultType parse(Object? data) {
    return _slideMutationResultSchema.parseAs(
      data,
      (validated) => SlideMutationResultType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SlideMutationResultType> safeParse(Object? data) {
    return _slideMutationResultSchema.safeParseAs(
      data,
      (validated) => SlideMutationResultType(validated as Map<String, Object?>),
    );
  }

  int get index => _data['index'] as int;

  DeckToolSlideType get slide =>
      DeckToolSlideType(_data['slide'] as Map<String, Object?>);

  DeckSnapshotType get deck =>
      DeckSnapshotType(_data['deck'] as Map<String, Object?>);
}

/// Extension type for SlideMoveResult
extension type SlideMoveResultType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SlideMoveResultType parse(Object? data) {
    return _slideMoveResultSchema.parseAs(
      data,
      (validated) => SlideMoveResultType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<SlideMoveResultType> safeParse(Object? data) {
    return _slideMoveResultSchema.safeParseAs(
      data,
      (validated) => SlideMoveResultType(validated as Map<String, Object?>),
    );
  }

  int get fromIndex => _data['fromIndex'] as int;

  int get toIndex => _data['toIndex'] as int;

  DeckSnapshotType get deck =>
      DeckSnapshotType(_data['deck'] as Map<String, Object?>);
}

/// Extension type for StyleUpdateResult
extension type StyleUpdateResultType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static StyleUpdateResultType parse(Object? data) {
    return _styleUpdateResultSchema.parseAs(
      data,
      (validated) => StyleUpdateResultType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<StyleUpdateResultType> safeParse(Object? data) {
    return _styleUpdateResultSchema.safeParseAs(
      data,
      (validated) => StyleUpdateResultType(validated as Map<String, Object?>),
    );
  }

  DeckStyleType get style =>
      DeckStyleType(_data['style'] as Map<String, Object?>);

  DeckSnapshotType get deck =>
      DeckSnapshotType(_data['deck'] as Map<String, Object?>);
}
