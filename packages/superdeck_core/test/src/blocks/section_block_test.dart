import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('SectionBlock', () {
    test('should initialize with empty blocks list', () {
      final block = SectionBlock([]);
      expect(block.blocks, isEmpty);
      expect(block.type, 'section');
    });

    test('should initialize with provided blocks', () {
      final childBlocks = [
        MarkdownBlock('Block 1'),
        MarkdownBlock('Block 2'),
      ];

      final block = SectionBlock(childBlocks);
      expect(block.blocks, hasLength(2));
      expect(block.blocks[0], isA<MarkdownBlock>());
      expect(block.blocks[1], isA<MarkdownBlock>());
      expect((block.blocks[0] as MarkdownBlock).content, 'Block 1');
      expect((block.blocks[1] as MarkdownBlock).content, 'Block 2');
    });

    test('should handle optional properties correctly', () {
      final childBlocks = [MarkdownBlock('Test')];
      final block = SectionBlock(
        childBlocks,
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      expect(block.blocks, hasLength(1));
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('should serialize to map correctly', () {
      final childBlocks = [
        MarkdownBlock('Block 1'),
        MarkdownBlock('Block 2'),
      ];

      final block = SectionBlock(
        childBlocks,
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      final map = block.toMap();

      expect(map['type'], 'section');
      expect(map['blocks'], isA<List>());
      expect(map['blocks'], hasLength(2));
      expect(map['align'], 'center');
      expect(map['flex'], 2);
      expect(map['scrollable'], true);

      // Verify child blocks are serialized correctly
      final blocksList = map['blocks'] as List;
      expect(blocksList[0]['type'], 'column');
      expect(blocksList[0]['content'], 'Block 1');
      expect(blocksList[1]['type'], 'column');
      expect(blocksList[1]['content'], 'Block 2');
    });

    test('should be deserializable from map', () {
      final map = {
        'type': 'section',
        'blocks': [
          {
            'type': 'column',
            'content': 'Block 1',
          },
          {
            'type': 'column',
            'content': 'Block 2',
          },
        ],
        'align': 'center',
        'flex': 2,
        'scrollable': true,
      };

      final block = BaseBlockMapper.fromMap(map) as SectionBlock;

      expect(block.blocks, hasLength(2));
      expect(block.blocks[0], isA<MarkdownBlock>());
      expect(block.blocks[1], isA<MarkdownBlock>());
      expect((block.blocks[0] as MarkdownBlock).content, 'Block 1');
      expect((block.blocks[1] as MarkdownBlock).content, 'Block 2');
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('schema should validate correct maps', () {
      final validMap = {
        'type': 'section',
        'blocks': [
          {
            'type': 'column',
            'content': 'Block 1',
          },
        ],
      };

      // Should not throw
      SectionBlock.schema.validateOrThrow(validMap);
    });

    test('schema should reject maps with invalid blocks', () {
      final invalidMap = {
        'type': 'section',
        'blocks': 'not an array', // Should be array
      };

      expect(() => SectionBlock.schema.validateOrThrow(invalidMap),
          throwsException);
    });

    test('should calculate total flex correctly', () {
      final blocks = [
        MarkdownBlock('Block 1', flex: 1),
        MarkdownBlock('Block 2', flex: 2),
        MarkdownBlock('Block 3', flex: null), // Default to 1
      ];

      final section = SectionBlock(blocks);

      expect(section.totalBlockFlex, 4); // 1 + 2 + 1(default)
    });

    test('should create with text block correctly', () {
      final section = SectionBlock.text('Test content');

      expect(section.blocks, hasLength(1));
      expect(section.blocks[0], isA<MarkdownBlock>());
      expect((section.blocks[0] as MarkdownBlock).content, 'Test content');
    });

    test('should parse from map correctly', () {
      final map = {
        'type': 'section',
        'blocks': [
          {
            'type': 'column',
            'content': 'Test content',
          },
        ],
      };

      final section = SectionBlock.parse(map);

      expect(section.blocks, hasLength(1));
      expect(section.blocks[0], isA<MarkdownBlock>());
      expect((section.blocks[0] as MarkdownBlock).content, 'Test content');
    });
  });
}
