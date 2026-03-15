// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'raw_slide_schema.dart';

T _$ackParse<T extends Object>(
  dynamic schema,
  Object? data,
  T Function(Object?) wrap,
) {
  final validated = schema.parse(data);
  return wrap(validated);
}

SchemaResult<T> _$ackSafeParse<T extends Object>(
  dynamic schema,
  Object? data,
  T Function(Object?) wrap,
) {
  final result = schema.safeParse(data);
  if (result.isOk) {
    return SchemaResult.ok(wrap(result.getOrNull()));
  }
  return SchemaResult.fail(result.getError()!);
}

/// Extension type for RawSlideFrontmatter
extension type RawSlideFrontmatterType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static RawSlideFrontmatterType parse(Object? data) {
    return _$ackParse<RawSlideFrontmatterType>(
      rawSlideFrontmatterSchema,
      data,
      (validated) => RawSlideFrontmatterType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<RawSlideFrontmatterType> safeParse(Object? data) {
    return _$ackSafeParse<RawSlideFrontmatterType>(
      rawSlideFrontmatterSchema,
      data,
      (validated) => RawSlideFrontmatterType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  Map<String, Object?> get args => _data;
}

/// Extension type for RawSlideMarkdown
extension type RawSlideMarkdownType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static RawSlideMarkdownType parse(Object? data) {
    return _$ackParse<RawSlideMarkdownType>(
      rawSlideMarkdownSchema,
      data,
      (validated) => RawSlideMarkdownType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<RawSlideMarkdownType> safeParse(Object? data) {
    return _$ackSafeParse<RawSlideMarkdownType>(
      rawSlideMarkdownSchema,
      data,
      (validated) => RawSlideMarkdownType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get key => _data['key'] as String;

  String get content => _data['content'] as String;

  RawSlideFrontmatterType get frontmatter =>
      RawSlideFrontmatterType(_data['frontmatter'] as Map<String, Object?>);

  RawSlideMarkdownType copyWith({
    String? key,
    String? content,
    Map<String, dynamic>? frontmatter,
  }) {
    return RawSlideMarkdownType.parse({
      'key': key ?? this.key,
      'content': content ?? this.content,
      'frontmatter': frontmatter ?? this.frontmatter,
    });
  }
}
