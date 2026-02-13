import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:superdeck/src/export/thumbnail_cache_store_base.dart';
import 'package:superdeck/src/export/thumbnail_cache_store_web.dart'
    as web_store;

void main() {
  group('WebThumbnailCacheStore', () {
    late ThumbnailCacheStore store;
    late SharedPreferencesStorePlatform originalStore;
    const slideKey = 'slide-1';
    const filePath = '.superdeck/thumbnails/thumbnail_slide-1.png';

    setUp(() {
      originalStore = SharedPreferencesStorePlatform.instance;
      SharedPreferences.setMockInitialValues(<String, Object>{});
      store = web_store.createThumbnailCacheStore();
    });

    tearDown(() {
      SharedPreferencesStorePlatform.instance = originalStore;
      SharedPreferences.resetStatic();
    });

    test('write persists bytes and resolve returns data URI', () async {
      final bytes = Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 0x00]);

      final writeUri = await store.write(
        slideKey: slideKey,
        filePath: filePath,
        bytes: bytes,
      );
      final resolvedUri = await store.resolve(
        slideKey: slideKey,
        filePath: filePath,
      );

      expect(writeUri, isNotNull);
      expect(resolvedUri, isNotNull);
      expect(writeUri!.scheme, 'data');
      expect(resolvedUri!.scheme, 'data');
      expect(resolvedUri.data, isNotNull);
      expect(resolvedUri.data!.contentAsBytes(), bytes);
    });

    test(
      'resolve returns null for invalid base64 and evicts bad key',
      () async {
        final bytes = Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 0x00]);
        await store.write(slideKey: slideKey, filePath: filePath, bytes: bytes);

        final prefs = await SharedPreferences.getInstance();
        final key = _findCacheKey(prefs);
        expect(key, isNotNull);
        await prefs.setString(key!, '%%%not_base64%%%');

        final resolvedUri = await store.resolve(
          slideKey: slideKey,
          filePath: filePath,
        );

        expect(resolvedUri, isNull);
        expect(prefs.containsKey(key), isFalse);
      },
    );

    test('delete removes persisted entry', () async {
      final bytes = Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 0x00]);
      await store.write(slideKey: slideKey, filePath: filePath, bytes: bytes);

      final prefs = await SharedPreferences.getInstance();
      final key = _findCacheKey(prefs);
      expect(key, isNotNull);
      expect(prefs.containsKey(key!), isTrue);

      await store.delete(slideKey: slideKey, filePath: filePath);

      expect(prefs.containsKey(key), isFalse);
      final resolvedUri = await store.resolve(
        slideKey: slideKey,
        filePath: filePath,
      );
      expect(resolvedUri, isNull);
    });

    test('write returns data URI when persistence reports failure', () async {
      _installStore(_FalseSetValueStore.empty());
      final bytes = Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 0x00]);

      final writeUri = await store.write(
        slideKey: slideKey,
        filePath: filePath,
        bytes: bytes,
      );

      expect(writeUri, isNotNull);
      expect(writeUri!.scheme, 'data');
      SharedPreferences.resetStatic();
      final resolvedUri = await store.resolve(
        slideKey: slideKey,
        filePath: filePath,
      );
      expect(resolvedUri, isNull);
    });

    test('write returns data URI when persistence throws', () async {
      _installStore(_ThrowingSetValueStore.empty());
      final bytes = Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 0x00]);

      final writeUri = await store.write(
        slideKey: slideKey,
        filePath: filePath,
        bytes: bytes,
      );

      expect(writeUri, isNotNull);
      expect(writeUri!.scheme, 'data');
      SharedPreferences.resetStatic();
      final resolvedUri = await store.resolve(
        slideKey: slideKey,
        filePath: filePath,
      );
      expect(resolvedUri, isNull);
    });

    test('resolve returns null when preferences init throws', () async {
      _installStore(_ThrowingGetAllStore.empty());

      final resolvedUri = await store.resolve(
        slideKey: slideKey,
        filePath: filePath,
      );

      expect(resolvedUri, isNull);
    });

    test('delete does not throw when remove fails', () async {
      _installStore(_ThrowingRemoveStore.empty());

      await store.delete(slideKey: slideKey, filePath: filePath);
    });

    test(
      'resolve returns null when cleanup remove fails for invalid payload',
      () async {
        _installStore(_ThrowingRemoveStore.empty());
        final bytes = Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 0x00]);
        await store.write(slideKey: slideKey, filePath: filePath, bytes: bytes);

        final prefs = await SharedPreferences.getInstance();
        final key = _findCacheKey(prefs);
        expect(key, isNotNull);
        await prefs.setString(key!, '%%%not_base64%%%');

        final resolvedUri = await store.resolve(
          slideKey: slideKey,
          filePath: filePath,
        );

        expect(resolvedUri, isNull);
        expect(prefs.containsKey(key), isFalse);
      },
    );
  });
}

String? _findCacheKey(SharedPreferences prefs) {
  for (final key in prefs.getKeys()) {
    if (key.startsWith('superdeck.thumbnail.')) {
      return key;
    }
  }

  return null;
}

void _installStore(SharedPreferencesStorePlatform platformStore) {
  SharedPreferencesStorePlatform.instance = platformStore;
  SharedPreferences.resetStatic();
}

class _FalseSetValueStore extends InMemorySharedPreferencesStore {
  _FalseSetValueStore.empty() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    return false;
  }
}

class _ThrowingSetValueStore extends InMemorySharedPreferencesStore {
  _ThrowingSetValueStore.empty() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    throw StateError('Simulated browser quota failure');
  }
}

class _ThrowingGetAllStore extends InMemorySharedPreferencesStore {
  _ThrowingGetAllStore.empty() : super.empty();

  @override
  Future<Map<String, Object>> getAll() async {
    throw StateError('Simulated browser storage init failure');
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    throw StateError('Simulated browser storage init failure');
  }
}

class _ThrowingRemoveStore extends InMemorySharedPreferencesStore {
  _ThrowingRemoveStore.empty() : super.empty();

  @override
  Future<bool> remove(String key) async {
    throw StateError('Simulated browser remove failure');
  }
}
