import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../files/deck_file.dart';
import '../files/deck_image_manifest.dart';

/// Resolves bare generated-image keys against the active deck's sidecar.
class DeckAssetCacheStore extends ChangeNotifier implements AssetCacheStore {
  Directory? _directory;

  String? get directoryPath => _directory?.path;

  void bind(DeckFileReference reference, {bool notify = true}) {
    final path = deckAssetsDirectoryPath(reference.path);
    if (_directory?.path == path) return;
    _directory = Directory(path);
    if (notify) notifyListeners();
  }

  void unbind() {
    if (_directory == null) return;
    _directory = null;
    notifyListeners();
  }

  /// Re-resolves visible images after repository-owned sidecar writes.
  void refresh() => notifyListeners();

  @override
  Future<Uri?> resolve(String assetKey) async {
    final store = _store;
    return store?.resolve(assetKey);
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    final store = _requireStore();
    final uri = await store.write(assetKey, bytes);
    if (uri != null) notifyListeners();
    return uri;
  }

  @override
  Future<void> delete(String assetKey) async {
    final store = _requireStore();
    await store.delete(assetKey);
    notifyListeners();
  }

  IoAssetCacheStore? get _store {
    final directory = _directory;
    return directory == null ? null : IoAssetCacheStore(cacheDir: directory);
  }

  IoAssetCacheStore _requireStore() {
    return _store ??
        (throw StateError('No deck is bound to the generated asset store.'));
  }
}
