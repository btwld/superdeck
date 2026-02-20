import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck/src/export/slide_capture_service.dart';
import 'package:superdeck/src/export/thumbnail_service.dart';

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

class _FakeSlideCaptureService extends SlideCaptureService {
  int captureCalls = 0;
  final Uint8List bytes;

  _FakeSlideCaptureService(this.bytes);

  @override
  Future<Uint8List> capture({
    SlideCaptureQuality quality = SlideCaptureQuality.thumbnail,
    required SlideConfiguration slide,
    required BuildContext context,
  }) async {
    captureCalls += 1;
    return bytes;
  }
}

SlideConfiguration _createSlide(String key) {
  return SlideConfiguration(
    slideIndex: 0,
    style: SlideStyle(),
    slide: Slide(key: key),
    thumbnailFile: 'thumbnail_$key.png',
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
      final capture = _FakeSlideCaptureService(Uint8List.fromList([1, 2, 3]));
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
      expect(store.callOrder, equals(['resolve:thumbnail_intro.png']));
    });

    testWidgets('captures and writes when cache misses', (tester) async {
      final context = await _pumpContext(tester);
      final store = _FakeAssetCacheStore(
        resolvedUri: null,
        writeUri: Uri.parse('file:///tmp/new-thumb.png'),
      );
      final capture = _FakeSlideCaptureService(Uint8List.fromList([7, 8, 9]));
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
        equals(['resolve:thumbnail_agenda.png', 'write:thumbnail_agenda.png']),
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
      final capture = _FakeSlideCaptureService(Uint8List.fromList([4, 5, 6]));
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
      expect(store.deletedKey, equals('thumbnail_force.png'));
      expect(
        store.callOrder,
        equals(['delete:thumbnail_force.png', 'write:thumbnail_force.png']),
      );
    });

    testWidgets('returns null when write fails', (tester) async {
      final context = await _pumpContext(tester);
      final store = _FakeAssetCacheStore(resolvedUri: null, writeUri: null);
      final capture = _FakeSlideCaptureService(Uint8List.fromList([1, 2, 3]));
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
          'resolve:thumbnail_missing.png',
          'write:thumbnail_missing.png',
        ]),
      );
    });
  });
}
