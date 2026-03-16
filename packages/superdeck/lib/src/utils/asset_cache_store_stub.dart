import 'package:superdeck_core/superdeck_core.dart';

class RuntimeAssetCacheStore implements AssetCacheStore {
  RuntimeAssetCacheStore({DeckWorkspace? workspace});

  @override
  Future<Uri?> resolve(String assetKey) async => null;

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async => null;

  @override
  Future<void> delete(String assetKey) async {}
}
