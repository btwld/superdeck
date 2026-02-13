import 'thumbnail_cache_store_base.dart';
import 'thumbnail_cache_store_stub.dart'
    if (dart.library.io) 'thumbnail_cache_store_io.dart'
    if (dart.library.js_interop) 'thumbnail_cache_store_web.dart'
    as platform;

export 'thumbnail_cache_store_base.dart';

ThumbnailCacheStore createThumbnailCacheStore() {
  return platform.createThumbnailCacheStore();
}
