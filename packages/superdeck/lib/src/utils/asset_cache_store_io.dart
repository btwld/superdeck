import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

AssetCacheStore createAssetCacheStore({
  required DeckConfiguration configuration,
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
    final normalizedKey = _normalizeAssetKey(assetKey);

    final appCacheUri = await _cacheStore.resolve(normalizedKey);
    if (appCacheUri != null) {
      return appCacheUri;
    }

    final bundledFile = File(p.join(_bundledAssetsDir.path, normalizedKey));
    if (!await bundledFile.exists()) {
      return null;
    }
    if (await bundledFile.length() == 0) {
      return null;
    }

    return bundledFile.uri;
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) {
    final normalizedKey = _normalizeAssetKey(assetKey);
    return _cacheStore.write(normalizedKey, bytes);
  }

  @override
  Future<void> delete(String assetKey) {
    final normalizedKey = _normalizeAssetKey(assetKey);
    return _cacheStore.delete(normalizedKey);
  }

  String _normalizeAssetKey(String assetKey) {
    final normalized = p.basename(assetKey);
    if (normalized.isEmpty || normalized != assetKey) {
      throw ArgumentError.value(
        assetKey,
        'assetKey',
        'Asset key must be a bare filename',
      );
    }
    return normalized;
  }
}
