import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:web/web.dart' as web;

AssetCacheStore createAssetCacheStore({DeckConfiguration? configuration}) {
  return _WebAssetCacheStore();
}

class _WebAssetCacheStore implements AssetCacheStore {
  static const _dbName = 'superdeck_asset_cache';
  static const _storeName = 'assets';
  static const _dbVersion = 1;

  final Map<String, Uint8List> _cache = {};
  Future<web.IDBDatabase?>? _dbFuture;

  /// Opens the IndexedDB database, reusing a cached future on success.
  /// On failure, clears the cached future so the next call retries.
  Future<web.IDBDatabase?> _openDb() {
    final existing = _dbFuture;
    if (existing != null) return existing;

    final future = _initDb();
    _dbFuture = future;
    return future.catchError((Object error) {
      if (identical(_dbFuture, future)) {
        _dbFuture = null;
      }
      debugPrint('[AssetCacheStore] IndexedDB unavailable: $error');
      return null;
    });
  }

  Future<web.IDBDatabase?> _initDb() {
    final completer = Completer<web.IDBDatabase?>();
    try {
      final request = web.window.indexedDB.open(_dbName, _dbVersion);

      request.onupgradeneeded = (web.Event event) {
        final db = (event.target as web.IDBRequest).result as web.IDBDatabase;
        if (!db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      }.toJS;

      request.onsuccess = (web.Event event) {
        final db = (event.target as web.IDBRequest).result as web.IDBDatabase;
        completer.complete(db);
      }.toJS;

      request.onerror = (web.Event _) {
        completer.complete(null);
      }.toJS;
    } catch (e) {
      debugPrint('[AssetCacheStore] IndexedDB open failed: $e');
      completer.complete(null);
    }
    return completer.future;
  }

  Future<Uint8List?> _idbGet(String key) async {
    final db = await _openDb();
    if (db == null) return null;

    final completer = Completer<Uint8List?>();
    try {
      final txn = db.transaction(_storeName.toJS, 'readonly');
      final store = txn.objectStore(_storeName);
      final request = store.get(key.toJS);

      request.onsuccess = (web.Event _) {
        final result = request.result;
        if (result == null || result.isUndefined) {
          completer.complete(null);
        } else {
          completer.complete((result as JSUint8Array).toDart);
        }
      }.toJS;

      request.onerror = (web.Event _) {
        debugPrint('[AssetCacheStore] IndexedDB get failed for "$key"');
        completer.complete(null);
      }.toJS;
    } catch (e) {
      debugPrint('[AssetCacheStore] IndexedDB get error: $e');
      completer.complete(null);
    }
    return completer.future;
  }

  Future<void> _idbWriteTxn(
    void Function(web.IDBObjectStore store) action,
  ) async {
    final db = await _openDb();
    if (db == null) return;

    final completer = Completer<void>();
    try {
      final txn = db.transaction(_storeName.toJS, 'readwrite');
      final store = txn.objectStore(_storeName);
      action(store);

      txn.oncomplete = (web.Event _) {
        completer.complete();
      }.toJS;

      txn.onerror = (web.Event _) {
        debugPrint('[AssetCacheStore] IndexedDB write transaction failed');
        completer.complete();
      }.toJS;
    } catch (e) {
      debugPrint('[AssetCacheStore] IndexedDB write error: $e');
      completer.complete();
    }
    return completer.future;
  }

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

    final storedBytes = await _idbGet(normalizedKey);
    if (storedBytes != null && storedBytes.isNotEmpty) {
      _cache[normalizedKey] = storedBytes;
      return Uri.dataFromBytes(
        storedBytes,
        mimeType: _mimeTypeForAssetKey(normalizedKey),
      );
    }

    return null;
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    final data = Uint8List.fromList(bytes);
    if (data.isEmpty) return null;

    _cache[normalizedKey] = data;
    await _idbWriteTxn((store) => store.put(data.toJS, normalizedKey.toJS));

    return Uri.dataFromBytes(
      data,
      mimeType: _mimeTypeForAssetKey(normalizedKey),
    );
  }

  @override
  Future<void> delete(String assetKey) async {
    final normalizedKey = AssetCacheStore.validateAssetKey(assetKey);
    _cache.remove(normalizedKey);
    await _idbWriteTxn((store) => store.delete(normalizedKey.toJS));
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
