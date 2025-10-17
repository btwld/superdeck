import 'package:superdeck_builder/src/fenced_code_block_transformer.dart';
import 'package:test/test.dart';

void main() {
  group('FencedCodeBlockTransformer', () {
    late FencedCodeBlockTransformer transformer;

    setUp(() {
      transformer = const FencedCodeBlockTransformer();
    });

    group('processBlocks', () {
      test('returns content unchanged when no blocks match filter', () async {
        const content = '''
# Title

```dart
some code
```

More text
''';

        final result = await transformer.processBlocks(
          content,
          filter: (block) => block.language == 'python',
          transform: (block) async => 'TRANSFORMED',
        );

        expect(result, equals(content));
      });

      test('transforms matching blocks', () async {
        const content = '''
```dart
original
```
''';

        final result = await transformer.processBlocks(
          content,
          filter: (block) => block.language == 'dart',
          transform: (block) async => '```dart\nTRANSFORMED\n```',
        );

        expect(result, contains('TRANSFORMED'));
        expect(result, isNot(contains('original')));
      });

      test('skips blocks when transform returns null', () async {
        const content = '''
```dart
code
```
''';

        final result = await transformer.processBlocks(
          content,
          filter: (block) => block.language == 'dart',
          transform: (block) async => null,
        );

        expect(result, equals(content));
      });

      test('processes multiple blocks in correct order', () async {
        const content = '''
```dart
first
```

Some text

```dart
second
```

More text

```dart
third
```
''';

        var callCount = 0;
        final result = await transformer.processBlocks(
          content,
          filter: (block) => block.language == 'dart',
          transform: (block) async {
            callCount++;
            return '```dart\ntransformed_$callCount\n```';
          },
        );

        expect(result, contains('transformed_1'));
        expect(result, contains('transformed_2'));
        expect(result, contains('transformed_3'));
        expect(callCount, equals(3));
      });

      test('filters blocks correctly', () async {
        const content = '''
```dart
dart code
```

```python
python code
```

```dart
more dart
```
''';

        var dartCount = 0;
        final result = await transformer.processBlocks(
          content,
          filter: (block) => block.language == 'dart',
          transform: (block) async {
            dartCount++;
            return '```dart\nformatted\n```';
          },
        );

        expect(dartCount, equals(2));
        expect(result, contains('python code')); // Python block unchanged
      });

      test('handles transformation errors gracefully', () async {
        const content = '''
```dart
code
```
''';

        expect(
          () async => await transformer.processBlocks(
            content,
            filter: (block) => block.language == 'dart',
            transform: (block) async => throw Exception('Transform failed'),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('preserves content structure during replacement', () async {
        const content = '''
# Header

```dart
code1
```

Middle text

```dart
code2
```

End text
''';

        final result = await transformer.processBlocks(
          content,
          filter: (block) => block.language == 'dart',
          transform: (block) async => '```dart\nX\n```',
        );

        expect(result, contains('# Header'));
        expect(result, contains('Middle text'));
        expect(result, contains('End text'));
      });
    });

    group('edge cases', () {
      test('handles empty content', () async {
        const content = '';

        final result = await transformer.processBlocks(
          content,
          filter: (block) => true,
          transform: (block) async => 'TRANSFORMED',
        );

        expect(result, equals(''));
      });

      test('handles content with no code blocks', () async {
        const content = '''
Just regular markdown text.
No code blocks here.
''';

        final result = await transformer.processBlocks(
          content,
          filter: (block) => true,
          transform: (block) async => 'TRANSFORMED',
        );

        expect(result, equals(content));
      });

      test('handles nested backticks in content', () async {
        const content = '''
```dart
String code = "```";
```
''';

        final result = await transformer.processBlocks(
          content,
          filter: (block) => block.language == 'dart',
          transform: (block) async => '```dart\nprocessed\n```',
        );

        expect(result, contains('processed'));
      });
    });
  });
}
