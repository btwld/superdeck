import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('DartPadBlock', () {
    test('should initialize with required properties', () {
      final block = DartPadBlock(id: 'test_id');
      expect(block.id, 'test_id');
      expect(block.type, 'dartpad');
      expect(block.theme, isNull);
      expect(block.embed, isNull);
      expect(block.run, isNull);
    });

    test('should handle all optional properties correctly', () {
      final block = DartPadBlock(
        id: 'test_id',
        theme: DartPadTheme.darkMode,
        embed: true,
        run: true,
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      expect(block.id, 'test_id');
      expect(block.theme, DartPadTheme.darkMode);
      expect(block.embed, true);
      expect(block.run, true);
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('should serialize to map correctly', () {
      final block = DartPadBlock(
        id: 'test_id',
        theme: DartPadTheme.darkMode,
        embed: true,
        run: true,
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      final map = block.toMap();

      expect(map['type'], 'dartpad');
      expect(map['id'], 'test_id');
      expect(map['theme'], 'dark_mode');
      expect(map['embed'], true);
      expect(map['run'], true);
      expect(map['align'], 'center');
      expect(map['flex'], 2);
      expect(map['scrollable'], true);
    });

    test('should be deserializable from map', () {
      final map = {
        'type': 'dartpad',
        'id': 'test_id',
        'theme': 'dark_mode',
        'embed': true,
        'run': true,
        'align': 'center',
        'flex': 2,
        'scrollable': true,
      };

      final block = BaseBlockMapper.fromMap(map) as DartPadBlock;

      expect(block.id, 'test_id');
      expect(block.theme, DartPadTheme.darkMode);
      expect(block.embed, true);
      expect(block.run, true);
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('schema should validate correct maps', () {
      final validMap = {
        'type': 'dartpad',
        'id': 'test_id',
      };

      // Should not throw
      DartPadBlock.schema.validateOrThrow(validMap);
    });

    test('schema should reject maps missing required fields', () {
      final invalidMap = {
        'type': 'dartpad',
        // Missing id field
      };

      expect(() => DartPadBlock.schema.validateOrThrow(invalidMap),
          throwsException);
    });

    test('should generate correct DartPad URL', () {
      final block = DartPadBlock(
        id: 'test_id',
        theme: DartPadTheme.darkMode,
        embed: true,
        run: true,
      );

      final url = block.getDartPadUrl();

      expect(url, contains('https://dartpad.dev/?'));
      expect(url, contains('id=test_id'));
      expect(url, contains('theme=darkMode'));
      expect(url, contains('embed=true'));
      expect(url, contains('run=true'));
    });
  });
}
