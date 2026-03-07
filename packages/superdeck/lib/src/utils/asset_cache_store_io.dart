import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/asset_cache_store_io.dart';
import 'package:superdeck_core/superdeck_core.dart';

AssetCacheStore createAssetCacheStore({
  required DeckWorkspace configuration,
}) {
  final cacheScope = GeneratedAsset.buildKey(
    configuration.superdeckDir.absolute.path,
  );
  final cacheDir = Directory(
    p.join(Directory.systemTemp.path, 'superdeck', 'asset_cache', cacheScope),
  );

  return _IoRuntimeAssetCacheStore(
    cacheStore: IoAssetCacheStore(cacheDir: cacheDir),
    bundledAssetsDir: configuration.assetsDir,
  );
}

class _IoRuntimeAssetCacheStore implements AssetCacheStore {
  final IoAssetCacheStore _cacheStore;
  final Directory _bundledAssetsDir;

  _IoRuntimeAssetCacheStore({
    required IoAssetCacheStore cacheStore,
    required Directory bundledAssetsDir,
  }) : _cacheStore = cacheStore,
       _bundledAssetsDir = bundledAssetsDir;

  @override
  Future<Uri?> resolve(String assetKey) async {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);

    final appCacheUri = await _cacheStore.resolve(normalizedKey);
    final bundledFile = File(p.join(_bundledAssetsDir.path, normalizedKey));
    if (appCacheUri == null) {
      if (!await bundledFile.exists()) {
        return null;
      }
      if (await bundledFile.length() == 0) {
        return null;
      }

      return bundledFile.uri;
    }

    if (!await bundledFile.exists()) {
      return appCacheUri;
    }
    if (await bundledFile.length() == 0) {
      return appCacheUri;
    }

    try {
      final appCacheLastModified = await File.fromUri(
        appCacheUri,
      ).lastModified();
      final bundledLastModified = await bundledFile.lastModified();

      if (bundledLastModified.isAfter(appCacheLastModified)) {
        return bundledFile.uri;
      }

      return appCacheUri;
    } on FileSystemException {
      return bundledFile.uri;
    }
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    return _cacheStore.write(normalizedKey, bytes);
  }

  @override
  Future<void> delete(String assetKey) {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    return _cacheStore.delete(normalizedKey);
  }
}
