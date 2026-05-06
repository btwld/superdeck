import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/fake_slide_capture_service.dart';

class _FakeAssetCacheStore implements AssetCacheStore {
  final List<String> callOrder = [];

  Uri? resolvedUri;
  Uri? writeUri;
  String? deletedKey;
  List<int>? writtenBytes;

  _FakeAssetCacheStore({this.resolvedUri, this.writeUri});

  @override
  Future<Uri?> resolve(String assetKey) async {
    callOrder.add('resolve:$assetKey');
    return resolvedUri;
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    callOrder.add('write:$assetKey');
    writtenBytes = bytes;
    return writeUri;
  }

  @override
  Future<void> delete(String assetKey) async {
    callOrder.add('delete:$assetKey');
    deletedKey = assetKey;
  }
}

String _thumbnailKey(String key, {String? suffix}) {
  if (suffix == null) {
    return 'thumbnail_$key.png';
  }
  return 'thumbnail_${key}_$suffix.png';
}

SlideConfiguration _createSlide(String key, {String? thumbnailKey}) {
  return SlideConfiguration(
    slideIndex: 0,
    style: SlideStyle(),
    slide: Slide(key: key),
    thumbnailKey: thumbnailKey ?? _thumbnailKey(key),
  );
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(key: key),
    ),
  );
  return key.currentContext!;
}

void main() {
  group('ThumbnailService', () {
    testWidgets('returns cache hit without capturing', (tester) async {
      final context = await _pumpContext(tester);
      final store = _FakeAssetCacheStore(
        resolvedUri: Uri.parse('file:///tmp/cache-thumb.png'),
      );
      final capture = FakeSlideCaptureService(Uint8List.fromList([1, 2, 3]));
      final service = ThumbnailService(
        cacheStore: store,
        slideCaptureService: capture,
      );

      final result = await service.generateThumbnail(
        slide: _createSlide('intro'),
        context: context,
        force: false,
      );

      expect(result, equals(Uri.parse('file:///tmp/cache-thumb.png')));
      expect(capture.captureCalls, 0);
      expect(store.callOrder, equals(["resolve:${_thumbnailKey('intro')}"]));
    });

    testWidgets('captures and writes when cache misses', (tester) async {
      final context = await _pumpContext(tester);
      final store = _FakeAssetCacheStore(
        resolvedUri: null,
        writeUri: Uri.parse('file:///tmp/new-thumb.png'),
      );
      final capture = FakeSlideCaptureService(Uint8List.fromList([7, 8, 9]));
      final service = ThumbnailService(
        cacheStore: store,
        slideCaptureService: capture,
      );

      final result = await service.generateThumbnail(
        slide: _createSlide('agenda'),
        context: context,
        force: false,
      );

      expect(result, equals(Uri.parse('file:///tmp/new-thumb.png')));
      expect(capture.captureCalls, 1);
      expect(store.writtenBytes, equals([7, 8, 9]));
      expect(
        store.callOrder,
        equals([
          "resolve:${_thumbnailKey('agenda')}",
          "write:${_thumbnailKey('agenda')}",
        ]),
      );
    });

    testWidgets('force generation deletes cache before writing', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final store = _FakeAssetCacheStore(
        resolvedUri: Uri.parse('file:///tmp/old-thumb.png'),
        writeUri: Uri.parse('file:///tmp/new-thumb.png'),
      );
      final capture = FakeSlideCaptureService(Uint8List.fromList([4, 5, 6]));
      final service = ThumbnailService(
        cacheStore: store,
        slideCaptureService: capture,
      );

      final result = await service.generateThumbnail(
        slide: _createSlide('force'),
        context: context,
        force: true,
      );

      expect(result, equals(Uri.parse('file:///tmp/new-thumb.png')));
      expect(capture.captureCalls, 1);
      expect(store.deletedKey, equals(_thumbnailKey('force')));
      expect(
        store.callOrder,
        equals([
          "delete:${_thumbnailKey('force')}",
          "write:${_thumbnailKey('force')}",
        ]),
      );
    });

    testWidgets('returns null when write fails', (tester) async {
      final context = await _pumpContext(tester);
      final store = _FakeAssetCacheStore(resolvedUri: null, writeUri: null);
      final capture = FakeSlideCaptureService(Uint8List.fromList([1, 2, 3]));
      final service = ThumbnailService(
        cacheStore: store,
        slideCaptureService: capture,
      );

      final result = await service.generateThumbnail(
        slide: _createSlide('missing'),
        context: context,
        force: false,
      );

      expect(result, isNull);
      expect(capture.captureCalls, 1);
      expect(
        store.callOrder,
        equals([
          "resolve:${_thumbnailKey('missing')}",
          "write:${_thumbnailKey('missing')}",
        ]),
      );
    });

    testWidgets('replaces cached async thumbnail when thumbnail key changes', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final store = _FakeAssetCacheStore(
        resolvedUri: Uri.parse('file:///tmp/updated-thumb.png'),
      );
      final capture = FakeSlideCaptureService(Uint8List.fromList([1, 2, 3]));
      final service = ThumbnailService(
        cacheStore: store,
        slideCaptureService: capture,
      );
      final oldThumbnail = AsyncThumbnail(
        thumbnailKey: _thumbnailKey('same', suffix: 'old'),
        generator: (ctx, {required force}) async =>
            Uri.parse('file:///tmp/old-thumb.png'),
      );

      Map<String, AsyncThumbnail>? updatedCache;
      service.generateThumbnails(
        slides: [
          _createSlide(
            'same',
            thumbnailKey: _thumbnailKey('same', suffix: 'new'),
          ),
        ],
        context: context,
        cache: {'same': oldThumbnail},
        onCacheUpdate: (cache) {
          updatedCache = cache;
        },
      );

      expect(updatedCache, isNotNull);
      expect(updatedCache!['same'], isNot(same(oldThumbnail)));
      expect(
        updatedCache!['same']!.thumbnailKey,
        _thumbnailKey('same', suffix: 'new'),
      );
    });
  });
}
