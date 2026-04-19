extension type RawSlideMarkdown(Map<String, Object?> _data) {
  static RawSlideMarkdown parse(Map<String, Object?> data) =>
      RawSlideMarkdown(data);

  String get key => _data['key'] as String;

  String get content => _data['content'] as String;

  Map<String, Object?> get frontmatter =>
      _data['frontmatter'] as Map<String, Object?>;

  RawSlideMarkdown copyWith({
    String? key,
    String? content,
    Map<String, Object?>? frontmatter,
  }) {
    return RawSlideMarkdown({
      'key': key ?? this.key,
      'content': content ?? this.content,
      'frontmatter': frontmatter ?? this.frontmatter,
    });
  }
}
