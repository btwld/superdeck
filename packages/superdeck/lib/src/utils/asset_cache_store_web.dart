import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

AssetCacheStore createAssetCacheStore({
  required DeckConfiguration configuration,
}) {
  return _WebAssetCacheStore(bundledAssetsPath: configuration.assetsDir.path);
}

class _WebAssetCacheStore implements AssetCacheStore {
  final Map<String, Uint8List> _cache = {};
  final String _bundledAssetsPath;

  _WebAssetCacheStore({required String bundledAssetsPath})
    : _bundledAssetsPath = _normalizePath(bundledAssetsPath);

  @override
  Future<Uri?> resolve(String assetKey) async {
    final normalizedKey = _normalizeAssetKey(assetKey);

    final cachedBytes = _cache[normalizedKey];
    if (cachedBytes != null && cachedBytes.isNotEmpty) {
      return Uri.dataFromBytes(
        cachedBytes,
        mimeType: _mimeTypeForAssetKey(normalizedKey),
      );
    }

    final bundledPath = p.posix.join(_bundledAssetsPath, normalizedKey);
    try {
      final byteData = await rootBundle.load(bundledPath);
      if (byteData.lengthInBytes == 0) {
        return null;
      }
      return Uri(path: bundledPath);
    } on Object {
      return null;
    }
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    final normalizedKey = _normalizeAssetKey(assetKey);
    final data = Uint8List.fromList(bytes);
    if (data.isEmpty) {
      return null;
    }

    _cache[normalizedKey] = data;
    return Uri.dataFromBytes(
      data,
      mimeType: _mimeTypeForAssetKey(normalizedKey),
    );
  }

  @override
  Future<void> delete(String assetKey) async {
    final normalizedKey = _normalizeAssetKey(assetKey);
    _cache.remove(normalizedKey);
  }

  static String _normalizePath(String path) {
    return path.replaceAll('\\', '/');
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

  String _mimeTypeForAssetKey(String assetKey) {
    return switch (p.extension(assetKey).toLowerCase()) {
      '.png' => 'image/png',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.svg' => 'image/svg+xml',
      _ => 'application/octet-stream',
    };
  }
}
