import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:superdeck/src/utils/asset_cache_store.dart';
import 'package:superdeck_core/superdeck_core.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String applicationCachePath;

  _FakePathProviderPlatform({required this.applicationCachePath});

  @override
  Future<String?> getApplicationCachePath() async => applicationCachePath;
}

class _FlakyPathProviderPlatform extends PathProviderPlatform {
  final String applicationCachePath;
  int calls = 0;

  _FlakyPathProviderPlatform({required this.applicationCachePath});

  @override
  Future<String?> getApplicationCachePath() async {
    calls += 1;
    if (calls == 1) {
      throw Exception('temporary path provider failure');
    }
    return applicationCachePath;
  }
}

void main() {
  group('Asset cache store (io)', () {
    late Directory projectDir;
    late Directory appCacheRoot;
    late DeckWorkspace workspace;
    late AssetCacheStore store;
    late Directory cacheDir;
    late PathProviderPlatform originalPlatform;

    const assetKey = 'thumbnail_intro.png';

    setUp(() async {
      projectDir = await Directory.systemTemp.createTemp('superdeck_asset_');
      appCacheRoot = await Directory.systemTemp.createTemp(
        'superdeck_app_cache_',
      );
      workspace = DeckWorkspace(projectDir: projectDir.path);
      originalPlatform = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _FakePathProviderPlatform(
        applicationCachePath: appCacheRoot.path,
      );

      final cacheScope = generateValueHash(
        workspace.superdeckDir.absolute.path,
      );
      cacheDir = Directory(
        p.join(appCacheRoot.path, 'superdeck', 'asset_cache', cacheScope),
      );

      store = RuntimeAssetCacheStore(workspace: workspace);
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPlatform;
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      if (await appCacheRoot.exists()) {
        await appCacheRoot.delete(recursive: true);
      }
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
      }
    });

    test('returns null when runtime cache is empty', () async {
      final resolved = await store.resolve(assetKey);

      expect(resolved, isNull);
    });

    test('resolves app cache when key has been written', () async {
      final cachedUri = await store.write(assetKey, [9, 9, 9]);

      final resolved = await store.resolve(assetKey);

      expect(cachedUri, isNotNull);
      expect(resolved, cachedUri);
    });

    test('delete removes the cached file for the exact key', () async {
      await store.write(assetKey, [9, 9, 9]);

      await store.delete(assetKey);

      expect(await store.resolve(assetKey), isNull);
    });

    test('writes into the application cache directory', () async {
      final cachedUri = await store.write(assetKey, [1, 2, 3]);

      expect(cachedUri, isNotNull);
      expect(cachedUri!.toFilePath(), startsWith(cacheDir.path));
    });

    test(
      'retries cache store init after a transient path-provider failure',
      () async {
        final flakyPlatform = _FlakyPathProviderPlatform(
          applicationCachePath: appCacheRoot.path,
        );
        PathProviderPlatform.instance = flakyPlatform;
        store = RuntimeAssetCacheStore(workspace: workspace);

        await expectLater(store.resolve(assetKey), throwsA(isA<Exception>()));

        final cachedUri = await store.write(assetKey, [1, 2, 3]);

        expect(flakyPlatform.calls, 2);
        expect(cachedUri, isNotNull);
        expect(await store.resolve(assetKey), cachedUri);
      },
    );
  });
}
