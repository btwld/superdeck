// Manual test to verify error output formatting
// Run with: cd packages/builder && flutter test test/manual_error_output_test.dart

import 'package:logging/logging.dart';
import 'package:superdeck_builder/src/parsers/fenced_code_parser.dart';
import 'package:superdeck_builder/src/markdown_utils.dart';
import 'package:test/test.dart';

void main() {
  // Setup logging to capture all messages
  Logger.root.level = Level.ALL;
  final logMessages = <LogRecord>[];

  setUp(() {
    logMessages.clear();
    Logger.root.onRecord.listen(logMessages.add);
  });

  group('Error Output Verification', () {
    test('Invalid YAML in code block options shows clear error', () {
      const invalidYamlContent = '''
```dart {lineLength 80, invalid: [unclosed}
print('hello');
```
''';

      const parser = FencedCodeParser();

      expect(
        () => parser.parse(invalidYamlContent),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf([
              contains('Failed to parse options'),
              contains('position'),
              contains('Language: dart'),
              contains('Options:'),
              contains('lineLength 80'),
            ]),
          ),
        ),
      );

      print('\n' + '=' * 80);
      print('TEST 1: Invalid YAML in code block options');
      print('=' * 80);
      print(
        'Expected output: Error should mention position, language, and show options',
      );
      print('✓ Test passed - error format validated');
    });

    test('Transform error includes position and content preview', () async {
      const transformContent = '''
```dart
print('test 1');
```

```python
print('test 2 with more content to trigger preview truncation - adding lots of text here to make it exceed 200 characters so we can verify the preview truncation is working correctly in our error messages')
```
''';

      try {
        await processFencedCodeBlocks(
          transformContent,
          filter: (block) => block.language == 'python',
          transform: (block) async {
            throw Exception('Simulated transform failure!');
          },
        );
        fail('Should have thrown exception');
      } catch (e) {
        final errorMessage = e.toString();

        expect(errorMessage, contains('Failed to transform fenced code block'));
        expect(errorMessage, contains('position'));
        expect(errorMessage, contains('Language: python'));
        expect(errorMessage, contains('Content length:'));
        expect(errorMessage, contains('Content preview:'));
        expect(errorMessage, contains('Simulated transform failure'));

        print('\n' + '=' * 80);
        print('TEST 2: Transform error with detailed context');
        print('=' * 80);
        print('Error message:');
        print(errorMessage);
        print('\n✓ Test passed - error includes all context');
      }
    });

    test(
      'YAML parsing warning logs are captured (non-strict mode)',
      () {},
      skip:
          'Non-strict YAML parsing is not exposed here; covered by unit tests.',
    );
  });
}
