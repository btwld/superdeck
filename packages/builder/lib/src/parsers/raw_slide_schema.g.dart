// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raw_slide_schema.dart';

/// Extension type for RawSlideMarkdown
extension type RawSlideMarkdownType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static RawSlideMarkdownType parse(Object? data) {
    final validated = rawSlideMarkdownSchema.parse(data);
    return RawSlideMarkdownType(validated as Map<String, Object?>);
  }

  static SchemaResult<RawSlideMarkdownType> safeParse(Object? data) {
    final result = rawSlideMarkdownSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(
        RawSlideMarkdownType(validated as Map<String, Object?>),
      ),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get key => _data['key'] as String;

  String get content => _data['content'] as String;

  Map<String, Object?> get frontmatter =>
      _data['frontmatter'] as Map<String, Object?>;

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
