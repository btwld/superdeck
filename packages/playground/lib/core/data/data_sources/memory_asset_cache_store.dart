import 'dart:typed_data';

import 'package:superdeck_core/superdeck_core.dart';

/// In-memory [AssetCacheStore] for generated thumbnails/assets. State is lost on
/// reload — adequate for the playground.
class MemoryAssetCacheStore implements AssetCacheStore {
  final Map<String, Uint8List> _cache = {};

  @override
  Future<Uri?> resolve(String assetKey) async {
    final key = AssetCacheStore.validateAssetKey(assetKey);
    final bytes = _cache[key];
    if (bytes == null || bytes.isEmpty) return null;
    return Uri.dataFromBytes(bytes, mimeType: 'image/png');
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    final key = AssetCacheStore.validateAssetKey(assetKey);
    final data = Uint8List.fromList(bytes);
    if (data.isEmpty) return null;
    _cache[key] = data;
    return Uri.dataFromBytes(data, mimeType: 'image/png');
  }

  @override
  Future<void> delete(String assetKey) async {
    final key = AssetCacheStore.validateAssetKey(assetKey);
    _cache.remove(key);
  }
}
