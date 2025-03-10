import 'package:superdeck_cli/src/parsers/parsers/comment_parser.dart';
import 'package:test/test.dart';

void main() {
  late CommentParser parser;

  setUp(() {
    parser = const CommentParser();
  });

  group('CommentParser', () {
    test('parses single line comment correctly', () {
      final input = '<!-- This is a comment -->';
      final result = parser.parse(input);
      expect(result, ['This is a comment']);
    });

    test('parses multiple single line comments correctly', () {
      final input = '''
<!-- First comment -->
<!-- Second comment -->
<!-- Third comment -->''';
      final result = parser.parse(input);
      expect(result, [
        'First comment',
        'Second comment',
        'Third comment',
      ]);
    });

    test('handles comments with special characters', () {
      final input = '''
<!-- Comment with numbers 123 -->
<!-- Comment with symbols !@#\$% -->
<!-- Comment with Unicode 你好 -->''';
      final result = parser.parse(input);
      expect(result, [
        'Comment with numbers 123',
        'Comment with symbols !@#\$%',
        'Comment with Unicode 你好',
      ]);
    });

    test('ignores invalid comments', () {
      final input = '''
<!-- Valid comment -->
<!- Invalid comment ->
<-- Also invalid -->
<!-- Invalid -- comment -->
Text without comments
<!-- Another valid comment -->''';
      final result = parser.parse(input);
      expect(result, [
        'Valid comment',
        'Another valid comment',
      ]);
    });

    test('handles empty comments', () {
      final input = '''
<!---->
<!-- -->
<!--     -->''';
      final result = parser.parse(input);
      expect(result, ['', '', '']);
    });

    test('handles comments with leading and trailing spaces', () {
      final input = '''
<!--    Spaces before   -->
<!--   Spaces around   -->
<!--Spaces after    -->''';
      final result = parser.parse(input);
      expect(result, [
        'Spaces before',
        'Spaces around',
        'Spaces after',
      ]);
    });

    test('ignores comments without proper spacing', () {
      final input = '''
<!--No space after arrow-->
<!--No space before arrow -->
<!-- Valid comment -->''';
      final result = parser.parse(input);
      expect(result, [
        'No space after arrow',
        'No space before arrow',
        'Valid comment',
      ]);
    });

    test('handles mixed content correctly', () {
      final input = '''
Regular text
<!-- Comment 1 -->
More text
<!-- Comment 2 -->
Final text''';
      final result = parser.parse(input);
      expect(result, [
        'Comment 1',
        'Comment 2',
      ]);
    });

    test('handles multiline comments correctly', () {
      final input = '''
<!--
  Multiline comment
  with multiple lines
  -->''';
      final result = parser.parse(input);
      expect(result, ['Multiline comment with multiple lines']);
    });
  });
}
