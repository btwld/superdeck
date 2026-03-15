import 'dart:io';

import 'package:path/path.dart' as p;

import 'asset_cache_store.dart';

/// IO-backed [AssetCacheStore] that persists assets under [cacheDir].
class IoAssetCacheStore implements AssetCacheStore {
  final Directory cacheDir;

  IoAssetCacheStore({required this.cacheDir});

  @override
  Future<Uri?> resolve(String assetKey) async {
    final file = _assetFile(assetKey);
    if (!await file.exists()) {
      return null;
    }
    if (await file.length() == 0) {
      return null;
    }
    return file.uri;
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    final file = _assetFile(assetKey);
    if (bytes.isEmpty) {
      return null;
    }
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.uri;
  }

  @override
  Future<void> delete(String assetKey) async {
    final file = _assetFile(assetKey);
    if (await file.exists()) {
      await file.delete();
    }
  }

  File _assetFile(String assetKey) {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    return File(p.join(cacheDir.path, normalizedKey));
  }
}
