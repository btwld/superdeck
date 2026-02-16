import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'thumbnail_cache_store_base.dart';

ThumbnailCacheStore createThumbnailCacheStore() => _WebThumbnailCacheStore();

class _WebThumbnailCacheStore implements ThumbnailCacheStore {
  static const _keyPrefix = 'superdeck.thumbnail.';
  // Use 32-bit FNV-1a to stay within JavaScript's safe integer range.
  static const _fnvOffset = 0x811c9dc5;
  static const _fnvPrime = 0x01000193;
  static const _fnvMask = 0xFFFFFFFF;

  static String _cacheKey(String slideKey, String? filePath) {
    final input = '$slideKey|${filePath ?? ''}';
    var hash = _fnvOffset;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * _fnvPrime) & _fnvMask;
    }

    return '$_keyPrefix${hash.toRadixString(16).padLeft(8, '0')}';
  }

  @override
  Future<void> delete({required String slideKey, String? filePath}) async {
    final key = _cacheKey(slideKey, filePath);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (error) {
      debugPrint(
        '[ThumbnailCacheStore:web] Failed to delete cache entry "$key": '
        '$error',
      );
    }
  }

  @override
  Future<Uri?> resolve({required String slideKey, String? filePath}) async {
    final key = _cacheKey(slideKey, filePath);
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(key);
      if (encoded == null || encoded.isEmpty) {
        return null;
      }

      // Validate the payload before returning a data URI to avoid
      // repeatedly attempting to decode corrupted cache values.
      base64Decode(encoded);

      return Uri.parse('data:image/png;base64,$encoded');
    } catch (error) {
      debugPrint(
        '[ThumbnailCacheStore:web] Failed to resolve cache entry "$key": '
        '$error',
      );
      if (prefs != null) {
        try {
          await prefs.remove(key);
        } catch (cleanupError) {
          debugPrint(
            '[ThumbnailCacheStore:web] Failed to evict invalid entry "$key": '
            '$cleanupError',
          );
        }
      }
      return null;
    }
  }

  @override
  Future<Uri?> write({
    required String slideKey,
    String? filePath,
    required Uint8List bytes,
  }) async {
    final key = _cacheKey(slideKey, filePath);
    final encoded = base64Encode(bytes);

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(key, encoded);
      if (!saved) {
        debugPrint(
          '[ThumbnailCacheStore:web] Failed to persist cache entry "$key": '
          'setString returned false.',
        );
      }
    } catch (error) {
      debugPrint(
        '[ThumbnailCacheStore:web] Failed to persist cache entry "$key": '
        '$error',
      );
    }

    // Return in-memory data URI regardless of persistence success so
    // callers can still render generated thumbnails immediately.
    return Uri.parse('data:image/png;base64,$encoded');
  }
}
