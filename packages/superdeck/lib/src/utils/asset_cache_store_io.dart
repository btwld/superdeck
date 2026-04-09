import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

class RuntimeAssetCacheStore implements AssetCacheStore {
  final String _cacheScope;
  Future<IoAssetCacheStore>? _cacheStoreFuture;

  RuntimeAssetCacheStore({DeckWorkspace? workspace})
    : _cacheScope = generateValueHash(
        (workspace ?? DeckWorkspace()).superdeckDir.absolute.path,
      );

  Future<IoAssetCacheStore> _cacheStore() {
    final existingFuture = _cacheStoreFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final future = _createCacheStore();
    _cacheStoreFuture = future;
    return future.catchError((Object error, StackTrace stackTrace) {
      if (identical(_cacheStoreFuture, future)) {
        _cacheStoreFuture = null;
      }
      throw error;
    });
  }

  Future<IoAssetCacheStore> _createCacheStore() async {
    final cacheRoot = await getApplicationCacheDirectory();
    final cacheDir = Directory(
      p.join(cacheRoot.path, 'superdeck', 'asset_cache', _cacheScope),
    );
    return IoAssetCacheStore(cacheDir: cacheDir);
  }

  @override
  Future<Uri?> resolve(String assetKey) async {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    return (await _cacheStore()).resolve(normalizedKey);
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    return (await _cacheStore()).write(normalizedKey, bytes);
  }

  @override
  Future<void> delete(String assetKey) async {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    return (await _cacheStore()).delete(normalizedKey);
  }
}
