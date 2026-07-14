@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:playground/features/editor/domain/files/deck_file.dart';
import 'package:playground/features/editor/domain/files/deck_image_manifest.dart';
import 'package:playground/features/editor/domain/stores/deck_asset_cache_store.dart';

void main() {
  test('binds bare asset keys to the active deck sidecar', () async {
    final temp = await Directory.systemTemp.createTemp('deck_asset_store_test');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });
    final store = DeckAssetCacheStore();
    addTearDown(store.dispose);
    final reference = DeckFileReference(path: p.join(temp.path, 'talk.md'));
    store.bind(reference);
    var notifications = 0;
    store.addListener(() => notifications++);

    final written = await store.write('slide-01-art.png', [1, 2, 3]);

    final expectedPath = p.join(
      deckAssetsDirectoryPath(reference.path),
      'slide-01-art.png',
    );
    expect(store.directoryPath, deckAssetsDirectoryPath(reference.path));
    expect(written, File(expectedPath).uri);
    expect(await store.resolve('slide-01-art.png'), File(expectedPath).uri);
    expect(notifications, 1);

    store.unbind();
    expect(await store.resolve('slide-01-art.png'), isNull);
    expect(notifications, 2);
  });
}
