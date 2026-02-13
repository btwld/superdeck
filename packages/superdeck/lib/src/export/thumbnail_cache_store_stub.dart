import 'dart:typed_data';

import 'thumbnail_cache_store_base.dart';

ThumbnailCacheStore createThumbnailCacheStore() => _StubThumbnailCacheStore();

class _StubThumbnailCacheStore implements ThumbnailCacheStore {
  @override
  Future<void> delete({required String slideKey, String? filePath}) async {}

  @override
  Future<Uri?> resolve({required String slideKey, String? filePath}) async {
    return null;
  }

  @override
  Future<Uri?> write({
    required String slideKey,
    String? filePath,
    required Uint8List bytes,
  }) async {
    return null;
  }
}
