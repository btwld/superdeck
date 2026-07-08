/// Entry point for the deck file store: re-exports the interface plus the
/// platform-selected [NativeDeckFileStore] via conditional import (native
/// `dart:io` impl, web stub), mirroring `AssetCacheStore`'s pattern.
library;

export 'deck_file_store_base.dart';
export 'deck_file_store_stub.dart'
    if (dart.library.io) 'deck_file_store_io.dart';
