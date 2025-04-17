import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('WidgetBlock', () {
    test('should initialize with required properties', () {
      final block = WidgetBlock(id: 'test_widget');
      expect(block.id, 'test_widget');
      expect(block.type, 'widget');
      expect(block.props, isNull);
    });

    test('should handle all optional properties correctly', () {
      final props = {'color': 'blue', 'size': 42};
      final block = WidgetBlock(
        id: 'test_widget',
        props: props,
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      expect(block.id, 'test_widget');
      expect(block.props, props);
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('should serialize to map correctly', () {
      final props = {'color': 'blue', 'size': 42};
      final block = WidgetBlock(
        id: 'test_widget',
        props: props,
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      final map = block.toMap();

      expect(map['type'], 'widget');
      expect(map['id'], 'test_widget');
      expect(map['props'], props);
      expect(map['align'], 'center');
      expect(map['flex'], 2);
      expect(map['scrollable'], true);
    });

    test('should handle props with nested objects', () {
      final props = {
        'color': 'blue',
        'size': 42,
        'nested': {
          'inner': 'value',
          'items': [1, 2, 3]
        }
      };

      final block = WidgetBlock(
        id: 'test_widget',
        props: props,
      );

      final map = block.toMap();
      expect(map['props'], props);

      // Test that nested objects are preserved
      expect(map['props']['nested']['inner'], 'value');
      expect(map['props']['nested']['items'], [1, 2, 3]);
    });

    test('should be deserializable from map', () {
      final map = {
        'type': 'widget',
        'id': 'test_widget',
        'props': {
          'color': 'blue',
          'size': 42,
        },
        'align': 'center',
        'flex': 2,
        'scrollable': true,
      };

      final block = BaseBlockMapper.fromMap(map) as WidgetBlock;

      expect(block.id, 'test_widget');
      expect(block.props, {
        'color': 'blue',
        'size': 42,
      });
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('schema should validate correct maps', () {
      final validMap = {
        'type': 'widget',
        'id': 'test_widget',
      };

      // Should not throw
      WidgetBlock.schema.validateOrThrow(validMap);
    });

    test('schema should validate maps with additional properties', () {
      final validMap = {
        'type': 'widget',
        'id': 'test_widget',
        'props': {
          'color': 'blue',
          'custom': [
            1,
            2,
            {'nested': true}
          ],
        },
      };

      // Should not throw
      WidgetBlock.schema.validateOrThrow(validMap);
    });

    test('schema should reject maps missing required fields', () {
      final invalidMap = {
        'type': 'widget',
        // Missing id field
      };

      expect(() => WidgetBlock.schema.validateOrThrow(invalidMap),
          throwsException);
    });
  });
}
