import 'package:superdeck_core/src/parsers/block_parser.dart';
import 'package:superdeck_core/src/parsers/fenced_code_parser.dart';
import 'package:test/test.dart';

final List<Map<String, dynamic>> testCaseCodeBlock = [
  {
    'description': 'Test Case 1: Basic js code with options',
    'input': '''
```js {theme: dark, lineNumbers: true}
console.log("Hello, world!");
function greet() {
  return "Hi!";
}
```
''',
    'expectedBlocks': [
      {
        'language': 'js',
        'options': {
          'theme': 'dark',
          'lineNumbers': true,
        },
        'content': '''console.log("Hello, world!");
function greet() {
  return "Hi!";
}''',
      }
    ],
  },
  {
    'description': 'Test Case 2: Python code without options',
    'input': '''
```python
print("Hello, world!")

def greet():
    return "Hi!"
```
''',
    'expectedBlocks': [
      {
        'language': 'python',
        'options': {},
        'content': '''print("Hello, world!")

def greet():
    return "Hi!"''',
      }
    ],
  },
  {
    'description': 'Test Case 3: Ruby code with different options',
    'input': '''
```ruby {author: "Jane Doe", version: 2.0}
puts "Hello, world!"

def greet
  "Hi!"
end
```
''',
    'expectedBlocks': [
      {
        'language': 'ruby',
        'options': {
          'author': 'Jane Doe',
          'version': 2.0,
        },
        'content': '''puts "Hello, world!"

def greet
  "Hi!"
end''',
      }
    ],
  },
  {
    'description': 'Test Case 4: Code content containing ``` inside',
    'input': '''
```js {theme: light}
console.log("Starting code block...");
function greet() {
  console.log("Hi!");
}
```
''',
    'expectedBlocks': [
      {
        'language': 'js',
        'options': {
          'theme': 'light',
        },
        'content': '''console.log("Starting code block...");
function greet() {
  console.log("Hi!");
}''',
      }
    ],
  },
  {
    'description':
        'Test Case 5: Incorrectly formatted code block (missing closing ```',
    'input': '''
```js {theme: dark, lineNumbers: true}
console.log("Hello, world!");
function greet() {
  return "Hi!";
}
```
''',
    'expectedBlocks': [
      {
        'language': 'js',
        'options': {
          'theme': 'dark',
          'lineNumbers': true,
        },
        'content': '''console.log("Hello, world!");
function greet() {
  return "Hi!";
}''',
      }
    ],
  },
  {
    'description': 'Test Case 6: Code block with complex options',
    'input': '''
```dart {theme: "dark mode", showLineNumbers: true, indent: 2}
void main() {
  print("Hello, Dart!");
}
```
''',
    'expectedBlocks': [
      {
        'language': 'dart',
        'options': {
          'theme': 'dark mode',
          'showLineNumbers': true,
          'indent': 2,
        },
        'content': '''void main() {
  print("Hello, Dart!");
}''',
      }
    ],
  },
  {
    'description': 'Test Case 7: Dart code block with no options',
    'input': '''
```dart
void main() {
  print("Hello, Dart!");
}
```
''',
    'expectedBlocks': [
      {
        'language': 'dart',
        'options': {},
        'content': '''void main() {
  print("Hello, Dart!");
}''',
      }
    ],
  }
];

final List<Map<String, dynamic>> testCaseTagBlock = [
  {
    'description': 'Test Case 1: Basic tag block',
    'input': '''
@tag
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag',
        data: {},
        startIndex: 0,
        endIndex: 4,
      )
    ],
  },
  {
    'description': 'Test Case 2: Tag block with options',
    'input': '''
@tag {key: value}
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag',
        data: {'key': 'value'},
        startIndex: 0,
        endIndex: 17,
      )
    ],
  },
  {
    'description': 'Test Case 3: Tag block with multiple options',
    'input': '''
@tag {
  key: value
  key2: value2
}
Test content
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag',
        data: {'key': 'value', 'key2': 'value2'},
        startIndex: 0,
        endIndex: 36,
      )
    ],
  },
  {
    'description':
        'Test Case 4: Tag block with no space between tag and options',
    'input': '''
@tag{key: value}
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag',
        data: {'key': 'value'},
        startIndex: 0,
        endIndex: 16,
      )
    ],
  },
  {
    'description': 'Test Case 5: Tag block with options across multiple lines',
    'input': '''
@tag{
  key: value
  key2: value2
}

# Test content
## Test content 2
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag',
        data: {'key': 'value', 'key2': 'value2'},
        startIndex: 0,
        endIndex: 35,
      ),
    ],
  },
  {
    'description':
        'Test Case 6: Tag block with multiple lines and space between tag and options',
    'input': '''
@tag {
  key: value
  key2: value2
}
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag',
        data: {'key': 'value', 'key2': 'value2'},
        startIndex: 0,
        endIndex: 36,
      )
    ],
  },
  {
    'description':
        'Test Case 7: Tag block with different values like int, dboules, and bool',
    'input': '''
@tag {
  key: 1
  key2: 2.0
  key3: true
}
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag',
        data: {'key': 1, 'key2': 2.0, 'key3': true},
        startIndex: 0,
        endIndex: 42,
      ),
    ],
  },
  // multiple tags
  {
    'description': 'Test Case 8: Multiple tags',
    'input': '''
@tag1 {key: value}

Test content 1
@tag2 {key2: value2}

Test content 2
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag1',
        data: {'key': 'value'},
        startIndex: 0,
        endIndex: 18,
      ),
      ParsedBlock(
        type: 'tag2',
        data: {'key2': 'value2'},
        startIndex: 35,
        endIndex: 55,
      )
    ],
  },

  {
    'description': 'Test Case 9: Multiple tags in different lines',
    'input': '''
@tag1 {key: value}
@tag2 {key2: value2}
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag1',
        data: {'key': 'value'},
        startIndex: 0,
        endIndex: 18,
      ),
      ParsedBlock(
        type: 'tag2',
        data: {'key2': 'value2'},
        startIndex: 19,
        endIndex: 39,
      )
    ],
  },
  // does not match {@column}
  {
    'description': 'Test Case 10: Does not match @column',
    'input': '''
{@column}
''',
    'expectedBlocks': [],
  }
];

void main() {
  group('parseFencedCode', () {
    final fencedCodeParser = const FencedCodeParser();
    for (final testCase in testCaseCodeBlock) {
      test(testCase['description'], () {
        final blocks = fencedCodeParser.parse(testCase['input']);
        expect(blocks.length, testCase['expectedBlocks'].length,
            reason: 'Number of parsed blocks does not match expected.');

        for (int i = 0; i < testCase['expectedBlocks'].length; i++) {
          final expected = testCase['expectedBlocks'][i];
          final actual = blocks[i];

          expect(actual.language, expected['language'],
              reason: 'Block \${i + 1}: Language mismatch.');
          expect(actual.options, expected['options'],
              reason: 'Block \${i + 1}: Options mismatch.');
          expect(actual.content.trim(), expected['content'].trim(),
              reason: 'Block \${i + 1}: Content mismatch.');
        }
      });
    }
  });

  group('parseTagBlocks', () {
    for (final testCase in testCaseTagBlock) {
      final description = testCase['description'];
      test(description, () {
        final blocks = const BlockParser().parse(testCase['input']);
        expect(blocks.length, testCase['expectedBlocks'].length,
            reason:
                '$description - Number of parsed blocks does not match expected.');

        for (int i = 0; i < testCase['expectedBlocks'].length; i++) {
          final expected = testCase['expectedBlocks'][i] as ParsedBlock;
          final actual = blocks[i];

          expect(actual.type, expected.type,
              reason: '$description - Block ${i + 1}: Tag mismatch.');
          expect(actual.data, expected.data,
              reason: '$description - Block ${i + 1}: Options mismatch.');
          expect(actual.startIndex, expected.startIndex,
              reason: '$description - Block ${i + 1}: Start index mismatch.');
          expect(actual.endIndex, expected.endIndex,
              reason: '$description - Block ${i + 1}: End index mismatch.');
        }
      });
    }
  });
}
