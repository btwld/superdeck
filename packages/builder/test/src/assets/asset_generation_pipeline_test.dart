import 'dart:io';

import 'package:superdeck_builder/src/assets/asset_generation_pipeline.dart';
import 'package:superdeck_builder/src/assets/asset_generator.dart';
import 'package:superdeck_core/asset_cache_store_io.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

/// Mock AssetGenerator for testing
class MockAssetGenerator implements AssetGenerator {
  final String _type;
  final List<int> _mockData;
  int generateCallCount = 0;
  String? lastAssetPath;

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
    generateCallCount++;
    lastAssetPath = assetPath;
    return _mockData;
  }

  @override
  Future<void> dispose() async {}
}

/// Mock DeckService for testing
class MockDeckService extends DeckService {
  final Directory _tempDir;
  final Map<String, String> _assetPaths = {};

  MockDeckService(this._tempDir) : super(configuration: DeckConfiguration());

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

class InMemoryAssetCacheStore implements AssetCacheStore {
  final Directory _cacheDir;
  final Map<String, List<int>> _bytesByKey = {};
  int resolveCallCount = 0;
  int writeCallCount = 0;
  String? lastResolvedKey;
  String? lastWrittenKey;

  InMemoryAssetCacheStore(this._cacheDir);

  @override
  Future<Uri?> resolve(String assetKey) async {
    resolveCallCount++;
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    lastResolvedKey = normalizedKey;
    final bytes = _bytesByKey[normalizedKey];
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    return File('${_cacheDir.path}/$normalizedKey').uri;
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    writeCallCount++;
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    lastWrittenKey = normalizedKey;
    if (bytes.isEmpty) {
      return null;
    }
    _bytesByKey[normalizedKey] = bytes;
    return File('${_cacheDir.path}/$normalizedKey').uri;
  }

  @override
  Future<void> delete(String assetKey) async {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    _bytesByKey.remove(normalizedKey);
  }
}

void main() {
  group('AssetGenerationPipeline', () {
    late AssetGenerationPipeline pipeline;
    late MockDeckService mockStore;
    late MockAssetGenerator mockGenerator;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asset_pipeline_test');
      mockStore = MockDeckService(tempDir);
      mockGenerator = MockAssetGenerator('mermaid', [1, 2, 3, 4, 5]);
      pipeline = AssetGenerationPipeline(
        generators: [mockGenerator],
        store: mockStore,
        cacheStore: IoAssetCacheStore(
          cacheDir: Directory('${tempDir.path}/assets'),
        ),
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

    test('writes generated asset bytes to expected asset path', () async {
      const content = '''
```mermaid
graph TD
  A --> B
```
''';

      final result = await pipeline.processSlideContent(content, 0);
      final generatedPath =
          '${tempDir.path}/assets/${result.generatedAssets.first.fileName}';
      final generatedFile = File(generatedPath);

      expect(await generatedFile.exists(), isTrue);
      expect(await generatedFile.readAsBytes(), equals([1, 2, 3, 4, 5]));
      expect(mockGenerator.lastAssetPath, equals(generatedPath));
      expect(mockGenerator.generateCallCount, equals(1));
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

    test('skips regeneration when cached asset already exists', () async {
      const content = '''
```mermaid
graph TD
  A --> B
```
''';

      await pipeline.processSlideContent(content, 0);
      await pipeline.processSlideContent(content, 1);

      expect(mockGenerator.generateCallCount, equals(1));
    });

    test(
      'writes generated assets through injected cache store on cache miss',
      () async {
        final cacheStore = InMemoryAssetCacheStore(
          Directory('${tempDir.path}/assets'),
        );
        final customPipeline = AssetGenerationPipeline(
          generators: [mockGenerator],
          store: mockStore,
          cacheStore: cacheStore,
        );

        const content = '''
```mermaid
graph TD
  A --> B
```
''';

        await customPipeline.processSlideContent(content, 0);

        expect(cacheStore.resolveCallCount, equals(1));
        expect(cacheStore.writeCallCount, equals(1));
        expect(cacheStore.lastResolvedKey, isNotNull);
        expect(cacheStore.lastWrittenKey, equals(cacheStore.lastResolvedKey));
      },
    );

    test(
      'uses injected cache store to skip regeneration on cache hit',
      () async {
        final cacheStore = InMemoryAssetCacheStore(
          Directory('${tempDir.path}/assets'),
        );
        final customPipeline = AssetGenerationPipeline(
          generators: [mockGenerator],
          store: mockStore,
          cacheStore: cacheStore,
        );

        const content = '''
```mermaid
graph TD
  A --> B
```
''';

        await customPipeline.processSlideContent(content, 0);
        await customPipeline.processSlideContent(content, 1);

        expect(cacheStore.resolveCallCount, equals(2));
        expect(cacheStore.writeCallCount, equals(1));
        expect(mockGenerator.generateCallCount, equals(1));
      },
    );

    test(
      'throws when cache resolves to a different path than deck assets',
      () async {
        final mismatchedCache = InMemoryAssetCacheStore(
          Directory('${tempDir.path}/external-cache'),
        );
        final mismatchedPipeline = AssetGenerationPipeline(
          generators: [mockGenerator],
          store: mockStore,
          cacheStore: mismatchedCache,
        );

        const content = '''
```mermaid
graph TD
  A --> B
```
''';

        await expectLater(
          mismatchedPipeline.processSlideContent(content, 0),
          throwsA(isA<Exception>()),
        );
      },
    );

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
