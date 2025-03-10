import 'base_parser.dart';

class CommentParser extends BaseParser<List<String>> {
  const CommentParser();

  @override
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
