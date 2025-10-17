import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('TagTokenizer', () {
    test('captures newline-separated option blocks', () {
      const text = '@tag\n{foo: bar}';

      final tokens = const TagTokenizer().tokenize(text);

      expect(tokens, hasLength(1));
      final token = tokens.single;

      expect(token.name, 'tag');
      expect(token.options, {'foo': 'bar'});
      expect(token.rawOptions, 'foo: bar');
      expect(token.startIndex, 0);
      expect(
        token.endIndex,
        text.indexOf('}') + 1,
        reason:
            'endIndex should include the closing brace even when the brace is on the next line.',
      );
      expect(token.optionsStartIndex, text.indexOf('{'));
      expect(token.optionsEndIndex, text.indexOf('}') + 1);
    });

    test('ignores braces inside quoted option strings', () {
      const text = "@tag {label: '{value} text'}";

      final tokens = const TagTokenizer().tokenize(text);

      expect(tokens, hasLength(1));
      final token = tokens.single;

      expect(token.options, {'label': '{value} text'});
      expect(token.rawOptions, "label: '{value} text'");
    });

    test('throws DeckFormatException with correct offset on unclosed braces', () {
      const text = 'intro line\n@tag {foo: bar';

      DeckFormatException? thrown;
      try {
        const TagTokenizer().tokenize(text);
      } on DeckFormatException catch (e) {
        thrown = e;
      }

      expect(
        thrown,
        isNotNull,
        reason: 'Expected a DeckFormatException to be thrown.',
      );
      expect(thrown!.message, contains('Unclosed braces in @tag options'));
      expect(
        thrown.source,
        text,
        reason: 'Exception.source should refer to the original buffer.',
      );
      expect(
        thrown.offset,
        text.indexOf('{'),
        reason:
            'Offset should point to the opening brace that could not be closed.',
      );
    });

    test('throws DeckFormatException with precise offset on YAML errors', () {
      const text = '@tag {foo: [bar}';

      DeckFormatException? thrown;
      try {
        const TagTokenizer().tokenize(text);
      } on DeckFormatException catch (e) {
        thrown = e;
      }

      expect(thrown, isNotNull);
      expect(thrown!.message, contains('Invalid options for @tag'));
      expect(
        thrown.offset,
        text.indexOf('}'),
        reason:
            'Offset should highlight where the YAML parser detected the failure.',
      );
    });

    test('ignores tags inside code blocks', () {
      const text = '''
@section

```dart
@AckType
class User {
  final String name;
}
```

@column
''';

      final tokens = const TagTokenizer().tokenize(text);

      expect(tokens, hasLength(2));
      expect(tokens[0].name, 'section');
      expect(tokens[1].name, 'column');
      // @AckType should be ignored because it's inside the code block
    });

    test('ignores tags with spread syntax inside code blocks', () {
      const text = '''
```dart
return {...data, 'age': age};
```
''';

      final tokens = const TagTokenizer().tokenize(text);

      expect(
        tokens,
        isEmpty,
        reason: 'No @ tags should be detected inside code blocks',
      );
    });
  });
}
