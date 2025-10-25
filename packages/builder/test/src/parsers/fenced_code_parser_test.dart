import 'package:superdeck_builder/src/parsers/fenced_code_parser.dart';
import 'package:test/test.dart';

void main() {
  group('FencedCodeParser', () {
    const parser = FencedCodeParser();

    group('basic parsing', () {
      test('parses simple code block with language', () {
        const content = '''
```dart
code here
```
''';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(1));
        expect(blocks[0].language, equals('dart'));
        expect(blocks[0].content, equals('code here'));
      });

      test('extracts correct start and end indices', () {
        const content = 'text\n```dart\ncode\n```\nmore';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(1));
        expect(blocks[0].startIndex, equals(5));
        expect(blocks[0].endIndex, equals(21));
      });

      test('parses multiple code blocks', () {
        const content = '''
```dart
first
```

```python
second
```
''';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(2));
        expect(blocks[0].language, equals('dart'));
        expect(blocks[0].content, equals('first'));
        expect(blocks[1].language, equals('python'));
        expect(blocks[1].content, equals('second'));
      });
    });

    group('options parsing', () {
      test('parses YAML options in braces', () {
        const content = '''
```dart {lineLength: 80, foo: bar}
code
```
''';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(1));
        expect(blocks[0].options['lineLength'], equals(80));
        expect(blocks[0].options['foo'], equals('bar'));
      });

      test('handles code block without options', () {
        const content = '''
```dart
code
```
''';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(1));
        expect(blocks[0].options, isEmpty);
      });

      test('handles empty options braces', () {
        const content = '''
```dart {}
code
```
''';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(1));
        expect(blocks[0].options, isEmpty);
      });

      test('throws on invalid YAML options', () {
        const content = '''
```dart {invalid yaml: [unclosed}
code
```
''';

        expect(
          () => parser.parse(content),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to parse options'),
            ),
          ),
        );
      });
    });

    group('edge cases', () {
      test('handles nested backticks in content', () {
        const content = '''
```dart
String s = "backticks";
```
''';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(1));
        expect(blocks[0].content, contains('String'));
        expect(blocks[0].language, equals('dart'));
      });

      test('handles empty code blocks', () {
        const content = '''
```dart
```
''';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(1));
        expect(blocks[0].content, isEmpty);
      });

      test('handles code block without language', () {
        const content = '''
```
code
```
''';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(1));
        expect(blocks[0].language, isEmpty);
      });

      test('returns empty list for content without code blocks', () {
        const content = 'Just regular text';
        final blocks = parser.parse(content);

        expect(blocks, isEmpty);
      });

      test('handles whitespace in content', () {
        const content = '''
```dart

  code with leading/trailing whitespace

```
''';
        final blocks = parser.parse(content);

        expect(blocks, hasLength(1));
        expect(blocks[0].content, equals('code with leading/trailing whitespace'));
      });

      test('handles unclosed code fence', () {
        const content = '''
```dart
code without closing fence
''';

        final blocks = parser.parse(content);

        // Should not match unclosed fence
        expect(blocks, isEmpty);
      });
    });

    group('sortedForReplacement', () {
      test('sorts blocks by startIndex in descending order', () {
        const content = '''
```dart
first
```

```python
second
```

```rust
third
```
''';
        final blocks = parser.parse(content);
        final sorted = blocks.sortedForReplacement();

        expect(sorted, hasLength(3));
        expect(sorted[0].startIndex > sorted[1].startIndex, isTrue);
        expect(sorted[1].startIndex > sorted[2].startIndex, isTrue);

        // Verify the last block in content becomes first in sorted list
        expect(sorted[0].language, equals('rust'));
        expect(sorted[1].language, equals('python'));
        expect(sorted[2].language, equals('dart'));
      });

      test('handles single block', () {
        const content = '```dart\ncode\n```';
        final blocks = parser.parse(content);
        final sorted = blocks.sortedForReplacement();

        expect(sorted, hasLength(1));
      });

      test('handles empty list', () {
        final blocks = <ParsedFencedCode>[];
        final sorted = blocks.sortedForReplacement();

        expect(sorted, isEmpty);
      });
    });
  });
}
