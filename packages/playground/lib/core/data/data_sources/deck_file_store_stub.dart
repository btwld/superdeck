import 'deck_file_store_base.dart';

/// Web/unsupported stub for [DeckFileStore].
///
/// The playground builds desktop-only today; filesystem persistence is native.
/// This stub keeps the conditional export well-typed on platforms without
/// `dart:io`. An IndexedDB implementation could replace it later (see the
/// `AssetCacheStore` web impl for the pattern).
class NativeDeckFileStore extends DeckFileStore {
  NativeDeckFileStore();

  Never _unsupported() => throw UnsupportedError(
    'Deck filesystem persistence is only available on desktop platforms.',
  );

  @override
  Future<String> decksDirectoryPath() => _unsupported();

  @override
  Future<bool> exists(String path) => _unsupported();

  @override
  Future<String> read(String path) => _unsupported();

  @override
  Future<void> write(String path, String content) => _unsupported();

  @override
  Future<String> createDeck(String name, {required String content}) =>
      _unsupported();

  @override
  Future<String?> pickDeckFile() => _unsupported();

  @override
  Stream<void> watch(String path) => _unsupported();
}
