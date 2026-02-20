import 'package:path/path.dart' as p;

/// Platform-agnostic cache contract for runtime-generated assets.
///
/// The [assetKey] must be a bare filename (for example:
/// `thumbnail_intro.png`). Implementations decide where and how keys
/// are stored.
abstract class AssetCacheStore {
  static String validateAssetKey(String assetKey) {
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

  Future<Uri?> resolve(String assetKey);
  Future<Uri?> write(String assetKey, List<int> bytes);
  Future<void> delete(String assetKey);
}
