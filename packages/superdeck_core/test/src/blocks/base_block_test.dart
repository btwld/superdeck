import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

// Use concrete implementation for test
void main() {
  group('BaseBlock', () {
    test('should have correct type field', () {
      final block =
          MarkdownBlock(''); // Use MarkdownBlock as concrete implementation
      expect(block.type, 'column');
    });

    test('should handle optional properties correctly', () {
      final block = MarkdownBlock(
        '',
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('should serialize to map correctly', () {
      final block = MarkdownBlock(
        'test content',
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      final map = block.toMap();

      expect(map['type'], 'column');
      expect(map['content'], 'test content');
      expect(map['align'], 'center');
      expect(map['flex'], 2);
      expect(map['scrollable'], true);
    });

    test('schema should validate correct maps', () {
      final validMap = {
        'type': 'column',
        'content': 'test content',
        'align': 'center',
        'flex': 2,
        'scrollable': true,
      };

      // Should not throw
      BaseBlock.schema.validateOrThrow(validMap);
    });

    test('schema should reject invalid maps', () {
      final invalidMap = {
        'align': 'invalid_value',
        'flex': 'not_an_int',
      };

      expect(
          () => BaseBlock.schema.validateOrThrow(invalidMap), throwsException);
    });
  });

  group('ContentAlignment', () {
    test('should have all expected values', () {
      expect(ContentAlignment.values.length, 9);
      expect(ContentAlignment.topLeft, isNotNull);
      expect(ContentAlignment.topCenter, isNotNull);
      expect(ContentAlignment.topRight, isNotNull);
      expect(ContentAlignment.centerLeft, isNotNull);
      expect(ContentAlignment.center, isNotNull);
      expect(ContentAlignment.centerRight, isNotNull);
      expect(ContentAlignment.bottomLeft, isNotNull);
      expect(ContentAlignment.bottomCenter, isNotNull);
      expect(ContentAlignment.bottomRight, isNotNull);
    });
  });

  group('ImageFit', () {
    test('should have all expected values', () {
      expect(ImageFit.values.length, 7);
      expect(ImageFit.fill, isNotNull);
      expect(ImageFit.contain, isNotNull);
      expect(ImageFit.cover, isNotNull);
      expect(ImageFit.fitWidth, isNotNull);
      expect(ImageFit.fitHeight, isNotNull);
      expect(ImageFit.none, isNotNull);
      expect(ImageFit.scaleDown, isNotNull);
    });
  });

  group('DartPadTheme', () {
    test('should have all expected values', () {
      expect(DartPadTheme.values.length, 2);
      expect(DartPadTheme.darkMode, isNotNull);
      expect(DartPadTheme.lightMode, isNotNull);
    });
  });
}
