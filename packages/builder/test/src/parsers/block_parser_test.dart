import 'package:superdeck_builder/src/parsers/block_parser.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

final List<Map<String, dynamic>> testCaseTagBlock = [
  {
    'description': 'Test Case 1: Basic tag block',
    'input': '''
@tag
''',
    'expectedBlocks': [
      ParsedBlock(type: 'tag', data: {}, startIndex: 0, endIndex: 4),
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
      ),
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
      ),
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
      ),
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
      ),
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
  {
    'description':
        'Test Case 7b: Tag block with brace on next line before options',
    'input': '''
@tag
{ key: value }
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag',
        data: {'key': 'value'},
        startIndex: 0,
        endIndex: 19,
      ),
    ],
  },
  {
    'description':
        'Test Case 7c: Tag block with braces inside quoted string value',
    'input': '''
@tag {label: "{value} text"}
''',
    'expectedBlocks': [
      ParsedBlock(
        type: 'tag',
        data: {'label': '{value} text'},
        startIndex: 0,
        endIndex: 28,
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
      ),
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
      ),
    ],
  },
  // does not match {@block}
  {
    'description': 'Test Case 10: Does not match @block',
    'input': '''
{@block}
''',
    'expectedBlocks': [],
  },
];

void main() {
  group('parseTagBlocks', () {
    for (final testCase in testCaseTagBlock) {
      final description = testCase['description'];
      test(description, () {
        final blocks = const BlockParser().parse(testCase['input']);
        expect(
          blocks.length,
          testCase['expectedBlocks'].length,
          reason:
              '$description - Number of parsed blocks does not match expected.',
        );

        for (int i = 0; i < testCase['expectedBlocks'].length; i++) {
          final expected = testCase['expectedBlocks'][i] as ParsedBlock;
          final actual = blocks[i];

          expect(
            actual.type,
            expected.type,
            reason: '$description - Block ${i + 1}: Tag mismatch.',
          );
          expect(
            actual.data,
            expected.data,
            reason: '$description - Block ${i + 1}: Options mismatch.',
          );
          expect(
            actual.startIndex,
            expected.startIndex,
            reason: '$description - Block ${i + 1}: Start index mismatch.',
          );
          expect(
            actual.endIndex,
            expected.endIndex,
            reason: '$description - Block ${i + 1}: End index mismatch.',
          );
        }
      });
    }

    test('throws DeckFormatException on invalid YAML options', () {
      const text = '@tag {foo: [bar}';

      expect(
        () => const BlockParser().parse(text),
        throwsA(
          isA<DeckFormatException>()
              .having(
                (e) => e.message,
                'message',
                contains('Invalid options for @tag'),
              )
              .having((e) => e.offset, 'offset', text.indexOf('}')),
        ),
      );
    });

    test('@block produces a ContentBlock', () {
      const text = '''
@block
Some markdown content

@block{
  align: center
  flex: 2
}
More content
''';

      final blocks = const BlockParser().parse(text);

      expect(blocks.length, 2);

      expect(blocks[0].type, 'block');
      expect(blocks[0].data['type'], 'block');
      expect(blocks[1].type, 'block');
      expect(blocks[1].data['type'], 'block');
      expect(blocks[1].data['align'], 'center');
      expect(blocks[1].data['flex'], 2);
    });

    test('@block preserves structured padding input', () {
      const text = '''
@block {
  padding: {horizontal: 24, vertical: 16}
}
Content
''';

      final block = const BlockParser().parse(text).single;

      expect(block.data['padding'], {'horizontal': 24, 'vertical': 16});
    });

    test('rejects unsupported @column directives', () {
      const text = '@column{flex: 1}';

      expect(
        () => const BlockParser().parse(text),
        throwsA(
          isA<DeckFormatException>()
              .having(
                (e) => e.message,
                'message',
                contains('Unsupported @column directive'),
              )
              .having((e) => e.offset, 'offset', 0),
        ),
      );
    });
  });
}
