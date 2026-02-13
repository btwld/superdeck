import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'thumbnail_cache_store_base.dart';

ThumbnailCacheStore createThumbnailCacheStore() => _IoThumbnailCacheStore();

class _IoThumbnailCacheStore implements ThumbnailCacheStore {
  static const _runtimeCacheFolder = 'superdeck/thumbnails';
  static const _fnvOffset = 0xcbf29ce484222325;
  static const _fnvPrime = 0x100000001b3;
  static const _fnvMask = 0xFFFFFFFFFFFFFFFF;

  static String _cacheIdentity(String slideKey, String? filePath) {
    final input = '$slideKey|${filePath ?? ''}';
    var hash = _fnvOffset;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * _fnvPrime) & _fnvMask;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  Future<File> _runtimeCacheFile(String slideKey, String? filePath) async {
    final cacheRootDir = await getApplicationCacheDirectory();
    final cacheDir = Directory(p.join(cacheRootDir.path, _runtimeCacheFolder));
    final extension = (filePath != null && filePath.isNotEmpty)
        ? p.extension(filePath)
        : '.png';
    final identity = _cacheIdentity(slideKey, filePath);
    final fileName = 'thumb_$identity${extension.isEmpty ? '.png' : extension}';

    return File(p.join(cacheDir.path, fileName));
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File?> _tryReadPrimary(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final length = await file.length();
    if (length <= 0) {
      return null;
    }

    return file;
  }

  Future<File?> _tryWritePrimary(String? filePath, Uint8List bytes) async {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final file = File(filePath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  @override
  Future<void> delete({required String slideKey, String? filePath}) async {
    try {
      if (filePath != null && filePath.isNotEmpty) {
        await _deleteIfExists(File(filePath));
      }

      final fallback = await _runtimeCacheFile(slideKey, filePath);
      await _deleteIfExists(fallback);
    } on FileSystemException catch (error) {
      debugPrint(
        '[ThumbnailCacheStore:io] Failed to delete cached thumbnail for '
        '"$slideKey": $error',
      );
    } catch (error) {
      debugPrint(
        '[ThumbnailCacheStore:io] Unexpected delete error for "$slideKey": '
        '$error',
      );
    }
  }

  @override
  Future<Uri?> resolve({required String slideKey, String? filePath}) async {
    final primary = await _tryReadPrimary(filePath);
    if (primary != null) {
      return primary.uri;
    }

    final fallback = await _runtimeCacheFile(slideKey, filePath);
    if (!await fallback.exists()) {
      return null;
    }

    final length = await fallback.length();
    if (length <= 0) {
      return null;
    }

    return fallback.uri;
  }

  @override
  Future<Uri?> write({
    required String slideKey,
    String? filePath,
    required Uint8List bytes,
  }) async {
    try {
      final primary = await _tryWritePrimary(filePath, bytes);
      if (primary != null) {
        return primary.uri;
      }
    } on FileSystemException {
      // Fall back to app cache directory when the configured path
      // is unavailable (e.g. read-only bundle locations).
    }

    final fallback = await _runtimeCacheFile(slideKey, filePath);
    final parent = fallback.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    await fallback.writeAsBytes(bytes, flush: true);
    return fallback.uri;
  }
}
