import 'dart:io';

import 'package:path/path.dart' as p;

/// Platform-agnostic cache contract for runtime-generated assets.
///
/// The [assetKey] must be a bare filename (for example:
/// `thumbnail_intro.png`). Implementations decide where and how keys
/// are stored.
abstract class AssetCacheStore {
  Future<Uri?> resolve(String assetKey);
  Future<Uri?> write(String assetKey, List<int> bytes);
  Future<void> delete(String assetKey);
}

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
    final normalizedKey = _normalizeAssetKey(assetKey);
    return File(p.join(cacheDir.path, normalizedKey));
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
