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
