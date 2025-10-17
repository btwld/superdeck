import 'package:superdeck_builder/src/assets/asset_generator.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

/// Mock implementation of AssetGenerator for testing
class MockAssetGenerator implements AssetGenerator {
  @override
  String get type => 'mock';

  @override
  Map<String, dynamic> get configuration => const {'test': true};

  @override
  bool canProcess(String contentType) => contentType == 'mock';

  @override
  GeneratedAsset createAssetReference(String content) {
    return GeneratedAsset.mermaid(content);
  }

  @override
  Future<List<int>> generateAsset(String content, String assetPath) async {
    // Return mock asset data
    return [1, 2, 3, 4, 5];
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('AssetGenerator', () {
    late MockAssetGenerator generator;

    setUp(() {
      generator = MockAssetGenerator();
    });

    test('has correct type', () {
      expect(generator.type, equals('mock'));
    });

    test('has configuration', () {
      expect(generator.configuration, isA<Map<String, dynamic>>());
      expect(generator.configuration['test'], isTrue);
    });

    test('canProcess returns true for matching content type', () {
      expect(generator.canProcess('mock'), isTrue);
    });

    test('canProcess returns false for non-matching content type', () {
      expect(generator.canProcess('other'), isFalse);
    });

    test('generateAsset returns asset data', () async {
      final result = await generator.generateAsset(
        'test content',
        '/path/to/asset',
      );
      expect(result, equals([1, 2, 3, 4, 5]));
    });

    test('dispose completes without error', () async {
      await expectLater(generator.dispose(), completes);
    });
  });
}
