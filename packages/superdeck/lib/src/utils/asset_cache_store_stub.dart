import 'package:superdeck_core/superdeck_core.dart';

AssetCacheStore createAssetCacheStore({
  required DeckConfiguration configuration,
}) {
  return _StubAssetCacheStore();
}

class _StubAssetCacheStore implements AssetCacheStore {
  @override
  Future<Uri?> resolve(String assetKey) async => null;

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async => null;

  @override
  Future<void> delete(String assetKey) async {}
}
