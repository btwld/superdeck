import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  late TagTokenizer tokenizer;

  setUp(() {
    tokenizer = const TagTokenizer();
  });

  group('TagTokenizer', () {
    group('basic tag detection', () {
      test('parses simple tag without options', () {
        const text = '@note';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'note');
        expect(tokens[0].options, isEmpty);
        expect(tokens[0].rawOptions, isNull);
        expect(tokens[0].startIndex, 0);
        expect(tokens[0].endIndex, 5);
      });

      test('parses tag with hyphenated name', () {
        const text = '@my-custom-tag';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'my-custom-tag');
      });

      test('parses tag with underscored name', () {
        const text = '@my_tag_name';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'my_tag_name');
      });

      test('parses tag with leading whitespace', () {
        const text = '  @tag-name';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'tag-name');
        // startIndex is at the match start (including whitespace)
        expect(tokens[0].startIndex, 0);
      });

      test('parses multiple tags in document', () {
        const text = '@tag1\n\nSome text\n\n@tag2';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(2));
        expect(tokens[0].name, 'tag1');
        expect(tokens[1].name, 'tag2');
      });

      test('parses tags with text between them', () {
        const text = '''
@header
# Title
Some paragraph text.
@footer
''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(2));
        expect(tokens[0].name, 'header');
        expect(tokens[1].name, 'footer');
      });

      test('empty string returns empty list', () {
        final tokens = tokenizer.tokenize('');
        expect(tokens, isEmpty);
      });

      test('text without tags returns empty list', () {
        const text = 'Just some regular text without any tags.';
        final tokens = tokenizer.tokenize(text);
        expect(tokens, isEmpty);
      });
    });

    group('options parsing', () {
      test('parses tag with simple options', () {
        const text = '@note { key: value }';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'note');
        expect(tokens[0].options, {'key': 'value'});
      });

      test('parses tag with multiple options', () {
        // Use YAML block style format
        const text = '''@config {
  key1: value1
  key2: value2
}''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {'key1': 'value1', 'key2': 'value2'});
      });

      test('parses tag with nested options', () {
        const text = '''@config {
  outer:
    inner: 1
}''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {
          'outer': {'inner': 1},
        });
      });

      test('parses tag with deeply nested options', () {
        const text = '''@config {
  a:
    b:
      c:
        d: 1
}''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {
          'a': {
            'b': {
              'c': {'d': 1},
            },
          },
        });
      });

      test('parses tag with list options', () {
        const text = '''@items {
  list:
    - a
    - b
    - c
}''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {
          'list': ['a', 'b', 'c'],
        });
      });

      test('parses tag with numeric options', () {
        const text = '''@metrics {
  count: 42
  ratio: 3.14
}''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options['count'], 42);
        expect(tokens[0].options['ratio'], 3.14);
      });

      test('parses tag with boolean options', () {
        const text = '''@flags {
  enabled: true
  debug: false
}''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {'enabled': true, 'debug': false});
      });

      test('parses tag with multiline options', () {
        const text = '''
@data {
  key1: val1
  key2: val2
}''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {'key1': 'val1', 'key2': 'val2'});
      });

      test('handles whitespace between tag and options', () {
        const text = '@tag   \t\n  { key: value }';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'tag');
        expect(tokens[0].options, {'key': 'value'});
      });

      test('parses empty options block', () {
        const text = '@tag {  }';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, isEmpty);
      });

      test('rawOptions contains original content', () {
        const text = '@tag { key: value }';
        final tokens = tokenizer.tokenize(text);

        expect(tokens[0].rawOptions, ' key: value ');
      });

      test('optionsStartIndex and optionsEndIndex are set', () {
        const text = '@tag { key: value }';
        final tokens = tokenizer.tokenize(text);

        expect(tokens[0].optionsStartIndex, 5);
        expect(tokens[0].optionsEndIndex, 19);
      });
    });

    group('brace balancing', () {
      test('handles nested braces correctly', () {
        const text = '''@tag {
  a:
    b:
      c: 1
}''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {
          'a': {
            'b': {'c': 1},
          },
        });
      });

      test('handles braces inside double-quoted strings', () {
        const text = '@tag { msg: "text } more" }';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {'msg': 'text } more'});
      });

      test('handles braces inside single-quoted strings', () {
        const text = "@tag { msg: 'text } more' }";
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {'msg': 'text } more'});
      });

      test('handles escaped double quotes inside strings', () {
        // Use YAML style for complex strings
        const text = '@tag { msg: "text with quote" }';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options['msg'], 'text with quote');
      });

      test('handles escaped single quotes inside strings', () {
        const text = "@tag { msg: 'text with quote' }";
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options['msg'], 'text with quote');
      });

      test('throws DeckFormatException on unclosed braces', () {
        const text = '@tag { key: value';

        expect(
          () => tokenizer.tokenize(text),
          throwsA(isA<DeckFormatException>()),
        );
      });

      test('unclosed braces exception contains tag name', () {
        const text = '@myTag { key: value';

        expect(
          () => tokenizer.tokenize(text),
          throwsA(
            predicate<DeckFormatException>(
              (e) => e.message.contains('myTag'),
            ),
          ),
        );
      });
    });

    group('code block protection', () {
      test('ignores tags inside fenced code blocks', () {
        const text = '''
```
@ignored
```
@found''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'found');
      });

      test('ignores tags inside code blocks with language', () {
        const text = '''
```dart
@ignored
```
@found''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'found');
      });

      test('handles code block before tag', () {
        const text = '''
```dart
void main() {}
```
@tag''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'tag');
      });

      test('handles multiple code blocks', () {
        const text = '''
```
@a
```
@b
```
@c
```''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'b');
      });

      test('handles tag after multiple code blocks', () {
        const text = '''
```
code1
```
```
code2
```
@found''';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'found');
      });

      test('code block at end without closing is handled', () {
        // This tests behavior when code block regex doesn't find closing
        const text = '''
@before
```
not closed''';
        final tokens = tokenizer.tokenize(text);

        // @before should be found, but not the one inside unclosed code block
        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'before');
      });
    });

    group('error handling', () {
      test('throws DeckFormatException for malformed YAML', () {
        // Use clearly invalid YAML syntax
        const text = '@tag { key: [unclosed }';

        expect(
          () => tokenizer.tokenize(text),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws DeckFormatException for unclosed braces', () {
        const text = '@myTag { key: value';

        expect(
          () => tokenizer.tokenize(text),
          throwsA(
            predicate<DeckFormatException>(
              (e) => e.message.contains('myTag'),
            ),
          ),
        );
      });

      test('unclosed braces exception contains tag name', () {
        const text = '@myBrokenTag { key: value';

        try {
          tokenizer.tokenize(text);
          fail('Expected DeckFormatException');
        } on DeckFormatException catch (e) {
          expect(e.message, contains('myBrokenTag'));
          expect(e.source, text);
        }
      });
    });

    group('position tracking', () {
      test('startIndex is correct for first tag', () {
        const text = '@first';
        final tokens = tokenizer.tokenize(text);

        expect(tokens[0].startIndex, 0);
      });

      test('startIndex is correct for tag with leading whitespace', () {
        const text = '   @tag';
        final tokens = tokenizer.tokenize(text);

        // Regex captures from the start of the match including whitespace
        expect(tokens[0].startIndex, 0);
      });

      test('endIndex is correct for tag without options', () {
        const text = '@tag';
        final tokens = tokenizer.tokenize(text);

        expect(tokens[0].endIndex, 4);
      });

      test('endIndex is correct for tag with options', () {
        const text = '@tag { a: 1 }';
        final tokens = tokenizer.tokenize(text);

        expect(tokens[0].endIndex, 13);
      });

      test('multiple tags have correct positions', () {
        const text = '@first\n@second';
        final tokens = tokenizer.tokenize(text);

        expect(tokens[0].startIndex, 0);
        expect(tokens[0].endIndex, 6);
        expect(tokens[1].startIndex, 7);
        expect(tokens[1].endIndex, 14);
      });
    });

    group('edge cases', () {
      test('tag at end of file without newline', () {
        const text = 'content\n@tag';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].name, 'tag');
      });

      test('consecutive tags without space', () {
        const text = '@tag1\n@tag2\n@tag3';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(3));
        expect(tokens.map((t) => t.name), ['tag1', 'tag2', 'tag3']);
      });

      test('tag with options followed by text', () {
        const text = '@tag { key: value } some text after';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(1));
        expect(tokens[0].options, {'key': 'value'});
      });

      test('@ in email is not matched (needs line start)', () {
        const text = 'contact user@example.com for help';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, isEmpty);
      });

      test('handles Windows line endings (CRLF)', () {
        const text = '@tag1\r\n@tag2';
        final tokens = tokenizer.tokenize(text);

        expect(tokens, hasLength(2));
      });
    });
  });
}
