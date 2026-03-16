@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/utils/asset_cache_store.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('Web AssetCacheStore', () {
    late AssetCacheStore store;

    setUp(() {
      store = RuntimeAssetCacheStore(
        workspace: DeckWorkspace(projectDir: '/tmp/fake'),
      );
    });

    test('resolve returns null for missing key', () async {
      final uri = await store.resolve('missing_key.png');
      expect(uri, isNull);
    });

    test('write and resolve round-trip', () async {
      const key = 'roundtrip_test.png';
      final bytes = [1, 2, 3, 4, 5];
      final writtenUri = await store.write(key, bytes);

      expect(writtenUri, isNotNull);
      expect(writtenUri!.scheme, 'data');

      final resolvedUri = await store.resolve(key);
      expect(resolvedUri, equals(writtenUri));
    });

    test('write skips empty payloads', () async {
      const key = 'empty_payload.png';
      final uri = await store.write(key, const []);
      expect(uri, isNull);

      final resolved = await store.resolve(key);
      expect(resolved, isNull);
    });

    test('delete removes stored asset', () async {
      const key = 'delete_test.png';
      await store.write(key, [9, 8, 7]);
      await store.delete(key);

      final resolved = await store.resolve(key);
      expect(resolved, isNull);
    });

    test('rejects non-key path values', () async {
      expect(
        () => store.resolve('nested/thumbnail.png'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => store.write('../thumbnail.png', [1]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'survives reload: new store resolves previously written key',
      () async {
        const key = 'persist_test.png';
        await store.write(key, [10, 20, 30]);

        // Simulate reload: new store instance, empty memory cache
        final freshStore = RuntimeAssetCacheStore(
          workspace: DeckWorkspace(projectDir: '/tmp/fake'),
        );

        final resolved = await freshStore.resolve(key);
        expect(resolved, isNotNull);
        expect(resolved!.scheme, 'data');
      },
    );
  });
}
