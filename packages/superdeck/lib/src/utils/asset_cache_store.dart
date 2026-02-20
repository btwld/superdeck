export 'asset_cache_store_stub.dart'
    if (dart.library.js_interop) 'asset_cache_store_web.dart'
    if (dart.library.io) 'asset_cache_store_io.dart';
