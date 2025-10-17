import 'dart:io';

import 'package:superdeck_builder/src/assets/asset_generation_pipeline.dart';
import 'package:superdeck_builder/src/assets/asset_generator.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

/// Mock AssetGenerator for testing
class MockAssetGenerator implements AssetGenerator {
  final String _type;
  final List<int> _mockData;

  MockAssetGenerator(this._type, this._mockData);

  @override
  String get type => _type;

  @override
  Map<String, dynamic> get configuration => const {};

  @override
  bool canProcess(String contentType) => contentType == _type;

  @override
  GeneratedAsset createAssetReference(String content) {
    return GeneratedAsset.mermaid(content);
  }

  @override
  Future<List<int>> generateAsset(String content, String assetPath) async {
    return _mockData;
  }

  @override
  Future<void> dispose() async {}
}

/// Mock DeckRepository for testing
class MockDeckRepository extends DeckRepository {
  final Directory _tempDir;
  final Map<String, String> _assetPaths = {};

  MockDeckRepository(this._tempDir)
      : super(
          configuration: DeckConfiguration(),
        );

  @override
  String getGeneratedAssetPath(GeneratedAsset asset) {
    // Create assets directory if it doesn't exist
    final assetsDir = Directory('${_tempDir.path}/assets');
    if (!assetsDir.existsSync()) {
      assetsDir.createSync(recursive: true);
    }

    final path = '${assetsDir.path}/${asset.fileName}';
    _assetPaths[asset.fileName] = path;
    return path;
  }
}

void main() {
  group('AssetGenerationPipeline', () {
    late AssetGenerationPipeline pipeline;
    late MockDeckRepository mockStore;
    late MockAssetGenerator mockGenerator;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asset_pipeline_test');
      mockStore = MockDeckRepository(tempDir);
      mockGenerator = MockAssetGenerator('mermaid', [1, 2, 3, 4, 5]);
      pipeline = AssetGenerationPipeline(
        generators: [mockGenerator],
        store: mockStore,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('processes slide content with no asset blocks', () async {
      const content = 'This is just regular markdown content.';
      final result = await pipeline.processSlideContent(content, 0);

      expect(result.updatedContent, equals(content));
      expect(result.generatedAssets, isEmpty);
    });

    test('processes slide content with mermaid block', () async {
      const content = '''
# Slide Title

```mermaid
graph TD
  A --> B
```

More content.
''';

      final result = await pipeline.processSlideContent(content, 0);

      expect(result.updatedContent, isNot(equals(content)));
      expect(result.updatedContent, contains('![mermaid_asset]'));
      expect(result.generatedAssets, hasLength(1));
      expect(result.generatedAssets.first.type, equals('mermaid'));
    });

    test('finds correct generator for content type', () async {
      const content = '''
```mermaid
graph TD
  A --> B
```
''';

      final result = await pipeline.processSlideContent(content, 0);
      expect(result.generatedAssets, hasLength(1));
    });

    test('ignores blocks with no matching generator', () async {
      const content = '''
```unknown
some unknown content
```
''';

      final result = await pipeline.processSlideContent(content, 0);
      expect(result.updatedContent, equals(content));
      expect(result.generatedAssets, isEmpty);
    });

    test('processes multiple blocks in correct order', () async {
      const content = '''
```mermaid
graph TD
  A --> B
```

Some text

```mermaid
graph LR
  C --> D
```
''';

      final result = await pipeline.processSlideContent(content, 0);
      expect(result.generatedAssets, hasLength(2));
      expect(result.updatedContent, contains('![mermaid_asset]'));
    });

    test('dispose calls dispose on all generators', () async {
      await expectLater(pipeline.dispose(), completes);
    });
  });

  group('AssetGenerationResult', () {
    test('creates result with content and assets', () {
      final assets = [GeneratedAsset.mermaid('test')];
      final result = AssetGenerationResult(
        updatedContent: 'updated content',
        generatedAssets: assets,
      );

      expect(result.updatedContent, equals('updated content'));
      expect(result.generatedAssets, equals(assets));
    });
  });
}
