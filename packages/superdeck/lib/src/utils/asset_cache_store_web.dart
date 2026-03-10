import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

AssetCacheStore createAssetCacheStore({
  required DeckConfiguration configuration,
}) {
  return _WebAssetCacheStore(
    bundledAssetsPath: configuration.bundledAssetsPath,
  );
}

class _WebAssetCacheStore implements AssetCacheStore {
  final Map<String, Uint8List> _cache = {};
  final String _bundledAssetsPath;

  _WebAssetCacheStore({required String bundledAssetsPath})
    : _bundledAssetsPath = _normalizePath(bundledAssetsPath);

  @override
  Future<Uri?> resolve(String assetKey) async {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);

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
      final bundledBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      if (bundledBytes.isEmpty) {
        return null;
      }
      _cache[normalizedKey] = bundledBytes;
      return Uri.dataFromBytes(
        bundledBytes,
        mimeType: _mimeTypeForAssetKey(normalizedKey),
      );
    } on FlutterError {
      return null;
    }
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
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
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    _cache.remove(normalizedKey);
  }

  static String _normalizePath(String path) {
    return path.replaceAll('\\', '/');
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
