import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownBlock', () {
    test('should initialize with content', () {
      final block = MarkdownBlock('Test content');
      expect(block.content, 'Test content');
      expect(block.type, 'column');
    });

    test('should handle null content as empty string', () {
      final block = MarkdownBlock(null);
      expect(block.content, '');
    });

    test('should handle optional properties correctly', () {
      final block = MarkdownBlock(
        'Test content',
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      expect(block.content, 'Test content');
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('should serialize to map correctly', () {
      final block = MarkdownBlock(
        'Test content',
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      final map = block.toMap();

      expect(map['type'], 'column');
      expect(map['content'], 'Test content');
      expect(map['align'], 'center');
      expect(map['flex'], 2);
      expect(map['scrollable'], true);
    });

    test('should be deserializable from map', () {
      final map = {
        'type': 'column',
        'content': 'Test content',
        'align': 'center',
        'flex': 2,
        'scrollable': true,
      };

      final block = BaseBlockMapper.fromMap(map) as MarkdownBlock;

      expect(block.content, 'Test content');
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('schema should validate correct maps', () {
      final validMap = {
        'type': 'column',
        'content': 'Test content',
      };

      // Should not throw
      MarkdownBlock.schema.validateOrThrow(validMap);
    });

    test('schema should require content field', () {
      final invalidMap = {
        'type': 'column',
      };

      expect(() => MarkdownBlock.schema.validateOrThrow(invalidMap),
          throwsException);
    });
  });
}
