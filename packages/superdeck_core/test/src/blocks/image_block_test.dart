import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('ImageBlock', () {
    final testAsset = Asset(
      id: 'test_id',
      extension: AssetExtension.png,
      type: AssetType.image,
    );

    test('should initialize with required properties', () {
      final block = ImageBlock(
        asset: testAsset,
      );
      expect(block.asset, testAsset);
      expect(block.type, 'image');
      expect(block.fit, isNull);
      expect(block.width, isNull);
      expect(block.height, isNull);
    });

    test('should handle all optional properties correctly', () {
      final block = ImageBlock(
        asset: testAsset,
        fit: ImageFit.cover,
        width: 300,
        height: 200,
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      expect(block.asset, testAsset);
      expect(block.fit, ImageFit.cover);
      expect(block.width, 300);
      expect(block.height, 200);
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('should serialize to map correctly', () {
      final block = ImageBlock(
        asset: testAsset,
        fit: ImageFit.cover,
        width: 300,
        height: 200,
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      final map = block.toMap();

      expect(map['type'], 'image');
      expect(map['asset'], {
        'id': 'test_id',
        'extension': 'png',
        'type': 'image',
      });
      expect(map['fit'], 'cover');
      expect(map['width'], 300);
      expect(map['height'], 200);
      expect(map['align'], 'center');
      expect(map['flex'], 2);
      expect(map['scrollable'], true);
    });

    test('should be deserializable from map', () {
      final map = {
        'type': 'image',
        'asset': {
          'id': 'test_id',
          'extension': 'png',
          'type': 'image',
        },
        'fit': 'cover',
        'width': 300,
        'height': 200,
        'align': 'center',
        'flex': 2,
        'scrollable': true,
      };

      final block = BaseBlockMapper.fromMap(map) as ImageBlock;

      expect(block.asset.id, 'test_id');
      expect(block.asset.extension, AssetExtension.png);
      expect(block.asset.type, AssetType.image);
      expect(block.fit, ImageFit.cover);
      expect(block.width, 300);
      expect(block.height, 200);
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });

    test('schema should validate correct maps', () {
      final validMap = {
        'type': 'image',
        'asset': {
          'id': 'test_id',
          'extension': 'png',
          'type': 'image',
        },
      };

      // Should not throw
      ImageBlock.schema.validateOrThrow(validMap);
    });

    test('schema should reject maps missing required fields', () {
      final invalidMap = {
        'type': 'image',
        // Missing asset field
      };

      expect(
          () => ImageBlock.schema.validateOrThrow(invalidMap), throwsException);
    });
  });
}
