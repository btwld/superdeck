import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/testing_utils.dart';

void main() {
  group('IoAssetCacheStore', () {
    late Directory tempDir;
    late IoAssetCacheStore store;

    setUp(() {
      tempDir = createTempDir();
      store = IoAssetCacheStore(cacheDir: tempDir);
    });

    test('resolve returns null when key is missing', () async {
      final uri = await store.resolve('thumbnail_missing.png');
      expect(uri, isNull);
    });

    test('write persists bytes and resolve returns the file uri', () async {
      final key = 'thumbnail_intro.png';
      final bytes = [1, 2, 3];

      final writtenUri = await store.write(key, bytes);
      final resolvedUri = await store.resolve(key);
      final file = File(p.join(tempDir.path, key));

      expect(writtenUri, equals(file.uri));
      expect(resolvedUri, equals(file.uri));
      expect(await file.readAsBytes(), bytes);
    });

    test('write skips empty payloads', () async {
      const key = 'thumbnail_empty.png';
      final file = File(p.join(tempDir.path, key));

      final writtenUri = await store.write(key, const []);
      final resolvedUri = await store.resolve(key);

      expect(writtenUri, isNull);
      expect(resolvedUri, isNull);
      expect(await file.exists(), isFalse);
    });

    test('delete removes stored asset', () async {
      const key = 'thumbnail_slide.png';
      await store.write(key, [9, 8, 7]);

      await store.delete(key);

      expect(await store.resolve(key), isNull);
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
  });
}
