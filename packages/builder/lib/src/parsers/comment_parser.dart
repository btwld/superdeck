class NoteParser {
  const NoteParser();

  List<String> parse(String content) {
    final notes = <String>[];
    final pattern = RegExp(r'<!--((?:(?!--).)*?)-->', dotAll: true);

    for (final match in pattern.allMatches(content)) {
      final note = match.group(1)!.trim();
      final normalized = note
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .join(' ');
      notes.add(normalized);
    }

    return notes;
  }
}

typedef CommentParser = NoteParser;
