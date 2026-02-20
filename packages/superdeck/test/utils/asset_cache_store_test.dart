import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck/src/utils/asset_cache_store.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('Asset cache store (io)', () {
    late Directory projectDir;
    late DeckConfiguration configuration;
    late AssetCacheStore store;
    late Directory cacheDir;

    const assetKey = 'thumbnail_intro.png';

    setUp(() async {
      projectDir = await Directory.systemTemp.createTemp('superdeck_asset_');
      configuration = DeckConfiguration(projectDir: projectDir.path);
      await configuration.assetsDir.create(recursive: true);

      final cacheScope = GeneratedAsset.buildKey(
        configuration.superdeckDir.absolute.path,
      );
      cacheDir = Directory(
        p.join(
          Directory.systemTemp.path,
          'superdeck',
          'asset_cache',
          cacheScope,
        ),
      );

      store = createAssetCacheStore(configuration: configuration);
    });

    tearDown(() async {
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
      }
    });

    test('resolves bundled asset when app cache is empty', () async {
      final bundledFile = File(p.join(configuration.assetsDir.path, assetKey));
      await bundledFile.writeAsBytes([1, 2, 3]);

      final resolved = await store.resolve(assetKey);

      expect(resolved, bundledFile.uri);
    });

    test('resolves app cache before bundled asset', () async {
      final bundledFile = File(p.join(configuration.assetsDir.path, assetKey));
      await bundledFile.writeAsBytes([1, 2, 3]);

      final cachedUri = await store.write(assetKey, [9, 9, 9]);
      final resolved = await store.resolve(assetKey);

      expect(cachedUri, isNotNull);
      expect(resolved, cachedUri);
      expect(resolved, isNot(bundledFile.uri));
    });

    test('delete removes app cache without deleting bundled asset', () async {
      final bundledFile = File(p.join(configuration.assetsDir.path, assetKey));
      await bundledFile.writeAsBytes([1, 2, 3]);
      await store.write(assetKey, [9, 9, 9]);

      await store.delete(assetKey);

      final resolved = await store.resolve(assetKey);
      expect(resolved, bundledFile.uri);
      expect(await bundledFile.exists(), isTrue);
    });
  });
}
