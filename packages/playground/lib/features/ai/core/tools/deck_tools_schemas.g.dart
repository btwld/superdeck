// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'deck_tools_schemas.dart';

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

  CreateSlideType get schema =>
      CreateSlideType(_data['schema'] as Map<String, Object?>);

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

  CreateSlideType get schema =>
      CreateSlideType(_data['schema'] as Map<String, Object?>);
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

  String get key => _data['key'] as String;

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

  DeckStyleType? get style => _data['style'] != null
      ? DeckStyleType(_data['style'] as Map<String, Object?>)
      : null;
}

/// Extension type for ReadSlidePayload
extension type ReadSlidePayloadType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ReadSlidePayloadType parse(Object? data) {
    return _readSlidePayloadSchema.parseAs(
      data,
      (validated) => ReadSlidePayloadType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ReadSlidePayloadType> safeParse(Object? data) {
    return _readSlidePayloadSchema.safeParseAs(
      data,
      (validated) => ReadSlidePayloadType(validated as Map<String, Object?>),
    );
  }

  int get index => _data['index'] as int;

  String get key => _data['key'] as String;

  SlideType get schema => SlideType(_data['schema'] as Map<String, Object?>);

  String get thumbnail => _data['thumbnail'] as String;
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

  ReadSlidePayloadType get slide =>
      ReadSlidePayloadType(_data['slide'] as Map<String, Object?>);

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

  SlideSummaryType get slide =>
      SlideSummaryType(_data['slide'] as Map<String, Object?>);

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

  SlideSummaryType get slide =>
      SlideSummaryType(_data['slide'] as Map<String, Object?>);

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
