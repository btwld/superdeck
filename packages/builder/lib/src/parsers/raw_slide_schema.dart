extension type RawSlideFrontmatterType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  Map<String, Object?> get args => _data;

  Map<String, Object?> toJson() => _data;
}

extension type RawSlideMarkdownType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static RawSlideMarkdownType parse(Map<String, Object?> data) =>
      RawSlideMarkdownType(data);

  Map<String, Object?> toJson() => _data;

  String get key => _data['key'] as String;

  String get content => _data['content'] as String;

  RawSlideFrontmatterType get frontmatter =>
      RawSlideFrontmatterType(_data['frontmatter'] as Map<String, Object?>);

  RawSlideMarkdownType copyWith({
    String? key,
    String? content,
    Map<String, Object?>? frontmatter,
  }) {
    return RawSlideMarkdownType({
      'key': key ?? this.key,
      'content': content ?? this.content,
      'frontmatter': frontmatter ?? this.frontmatter,
    });
  }
}

typedef RawSlideMarkdown = RawSlideMarkdownType;
