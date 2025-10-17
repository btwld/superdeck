class CommentParser {
  const CommentParser();

  List<String> parse(String content) {
    final comments = <String>[];
    final pattern = RegExp(r'<!--((?:(?!--).)*?)-->', dotAll: true);

    for (final match in pattern.allMatches(content)) {
      final comment = match.group(1)!.trim();
      final normalized = comment
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .join(' ');
      comments.add(normalized);
    }

    return comments;
  }
}
