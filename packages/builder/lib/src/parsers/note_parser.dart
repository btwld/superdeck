/// Extracts speaker notes written with HTML comment delimiters.
///
/// Example:
/// `<!-- Mention migration risks here -->`
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
