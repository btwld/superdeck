import 'package:superdeck_builder/src/parsers/note_parser.dart';
import 'package:test/test.dart';

void main() {
  late NoteParser parser;

  setUp(() {
    parser = const NoteParser();
  });

  group('NoteParser', () {
    test('parses single line note correctly', () {
      final input = '<!-- This is a note -->';
      final result = parser.parse(input);
      expect(result, ['This is a note']);
    });

    test('parses multiple single line notes correctly', () {
      final input = '''
<!-- First note -->
<!-- Second note -->
<!-- Third note -->''';
      final result = parser.parse(input);
      expect(result, ['First note', 'Second note', 'Third note']);
    });

    test('handles notes with special characters', () {
      final input = '''
<!-- Note with numbers 123 -->
<!-- Note with symbols !@#\$% -->
<!-- Note with Unicode 你好 -->''';
      final result = parser.parse(input);
      expect(result, [
        'Note with numbers 123',
        'Note with symbols !@#\$%',
        'Note with Unicode 你好',
      ]);
    });

    test('ignores invalid note delimiters', () {
      final input = '''
<!-- Valid note -->
<!- Invalid note ->
<-- Also invalid -->
<!-- Invalid -- note -->
Text without notes
<!-- Another valid note -->''';
      final result = parser.parse(input);
      expect(result, ['Valid note', 'Another valid note']);
    });

    test('handles empty note delimiters', () {
      final input = '''
<!---->
<!-- -->
<!--     -->''';
      final result = parser.parse(input);
      expect(result, ['', '', '']);
    });

    test('handles notes with leading and trailing spaces', () {
      final input = '''
<!--    Spaces before   -->
<!--   Spaces around   -->
<!--Spaces after    -->''';
      final result = parser.parse(input);
      expect(result, ['Spaces before', 'Spaces around', 'Spaces after']);
    });

    test('parses notes without requiring surrounding spaces', () {
      final input = '''
<!--No space after arrow-->
<!--No space before arrow -->
<!-- Valid note -->''';
      final result = parser.parse(input);
      expect(result, [
        'No space after arrow',
        'No space before arrow',
        'Valid note',
      ]);
    });

    test('extracts notes from mixed content', () {
      final input = '''
Regular text
<!-- Note 1 -->
More text
<!-- Note 2 -->
Final text''';
      final result = parser.parse(input);
      expect(result, ['Note 1', 'Note 2']);
    });

    test('handles multiline notes correctly', () {
      final input = '''
<!--
  Multiline note
  with multiple lines
  -->''';
      final result = parser.parse(input);
      expect(result, ['Multiline note with multiple lines']);
    });
  });
}
