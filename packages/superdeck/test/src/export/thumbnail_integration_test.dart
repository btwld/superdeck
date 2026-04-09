import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck/src/export/async_thumbnail.dart';
import 'package:superdeck/src/export/thumbnail_service.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/fake_slide_capture_service.dart';

class _TrackingCacheStore implements AssetCacheStore {
  final Map<String, List<int>> _store = {};
  final List<String> callLog = [];

  @override
  Future<Uri?> resolve(String assetKey) async {
    callLog.add('resolve:$assetKey');
    final bytes = _store[assetKey];
    if (bytes == null) return null;
    return Uri.parse('file:///cache/$assetKey');
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    callLog.add('write:$assetKey');
    _store[assetKey] = bytes;
    return Uri.parse('file:///cache/$assetKey');
  }

  @override
  Future<void> delete(String assetKey) async {
    callLog.add('delete:$assetKey');
    _store.remove(assetKey);
  }

  bool containsKey(String key) => _store.containsKey(key);
  void clearLog() => callLog.clear();
}

String _thumbnailKey(String slideKey) => 'thumbnail_$slideKey.png';

SlideConfiguration _slide(String key, {String? thumbnailKey}) {
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
  group('ThumbnailService.generateThumbnail (single slide)', () {
    late _TrackingCacheStore cacheStore;
    late FakeSlideCaptureService captureService;
    late ThumbnailService service;

    setUp(() {
      cacheStore = _TrackingCacheStore();
      captureService = FakeSlideCaptureService();
      service = ThumbnailService(
        cacheStore: cacheStore,
        slideCaptureService: captureService,
      );
    });

    testWidgets('cache miss triggers capture then write', (tester) async {
      final context = await _pumpContext(tester);

      final uri = await service.generateThumbnail(
        slide: _slide('new'),
        context: context,
        force: false,
      );

      expect(uri, Uri.parse('file:///cache/${_thumbnailKey('new')}'));
      expect(captureService.captureCalls, 1);
      expect(cacheStore.callLog, [
        'resolve:${_thumbnailKey('new')}',
        'write:${_thumbnailKey('new')}',
      ]);
    });

    testWidgets('cache hit returns resolved URI without capture', (
      tester,
    ) async {
      final context = await _pumpContext(tester);

      // Pre-populate cache
      await cacheStore.write(_thumbnailKey('cached'), [4, 5, 6]);
      cacheStore.clearLog();

      final uri = await service.generateThumbnail(
        slide: _slide('cached'),
        context: context,
        force: false,
      );

      expect(uri, Uri.parse('file:///cache/${_thumbnailKey('cached')}'));
      expect(captureService.captureCalls, 0);
      expect(cacheStore.callLog, ['resolve:${_thumbnailKey('cached')}']);
    });

    testWidgets('force deletes cache entry then recaptures', (tester) async {
      final context = await _pumpContext(tester);

      // Pre-populate cache
      await cacheStore.write(_thumbnailKey('forced'), [7, 8, 9]);
      cacheStore.clearLog();

      final uri = await service.generateThumbnail(
        slide: _slide('forced'),
        context: context,
        force: true,
      );

      expect(uri, Uri.parse('file:///cache/${_thumbnailKey('forced')}'));
      expect(captureService.captureCalls, 1);
      expect(cacheStore.callLog, [
        'delete:${_thumbnailKey('forced')}',
        'write:${_thumbnailKey('forced')}',
      ]);
    });

    testWidgets('multiple slides each get their own cache entry', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final slides = [_slide('a'), _slide('b'), _slide('c')];

      for (final slide in slides) {
        await service.generateThumbnail(
          slide: slide,
          context: context,
          force: false,
        );
      }

      expect(captureService.captureCalls, 3);
      expect(cacheStore.containsKey(_thumbnailKey('a')), isTrue);
      expect(cacheStore.containsKey(_thumbnailKey('b')), isTrue);
      expect(cacheStore.containsKey(_thumbnailKey('c')), isTrue);
    });

    testWidgets('second call for same slide hits cache', (tester) async {
      final context = await _pumpContext(tester);
      final slide = _slide('repeat');

      // First call: cache miss → capture
      await service.generateThumbnail(
        slide: slide,
        context: context,
        force: false,
      );
      expect(captureService.captureCalls, 1);

      // Second call: cache hit → no capture
      await service.generateThumbnail(
        slide: slide,
        context: context,
        force: false,
      );
      expect(captureService.captureCalls, 1);
    });
  });

  group('ThumbnailService.generateThumbnails (batch cache management)', () {
    late _TrackingCacheStore cacheStore;
    late FakeSlideCaptureService captureService;
    late ThumbnailService service;

    setUp(() {
      cacheStore = _TrackingCacheStore();
      captureService = FakeSlideCaptureService();
      service = ThumbnailService(
        cacheStore: cacheStore,
        slideCaptureService: captureService,
      );
    });

    testWidgets('creates AsyncThumbnails for new slides', (tester) async {
      final context = await _pumpContext(tester);

      Map<String, AsyncThumbnail>? result;
      service.generateThumbnails(
        slides: [_slide('a'), _slide('b')],
        context: context,
        cache: {},
        onCacheUpdate: (cache) => result = cache,
      );

      expect(result, isNotNull);
      expect(result!.keys, unorderedEquals(['a', 'b']));
      expect(result!['a']!.thumbnailKey, _thumbnailKey('a'));
      expect(result!['b']!.thumbnailKey, _thumbnailKey('b'));
    });

    testWidgets('reuses existing AsyncThumbnail when key matches', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final existingThumbnail = AsyncThumbnail(
        thumbnailKey: _thumbnailKey('reuse'),
        generator: (ctx, {required force}) async =>
            Uri.parse('file:///tmp/reuse.png'),
      );

      Map<String, AsyncThumbnail>? result;
      service.generateThumbnails(
        slides: [_slide('reuse')],
        context: context,
        cache: {'reuse': existingThumbnail},
        onCacheUpdate: (cache) => result = cache,
      );

      expect(identical(result!['reuse'], existingThumbnail), isTrue);

      existingThumbnail.dispose();
    });

    testWidgets('replaces AsyncThumbnail when thumbnailKey changes', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final oldThumbnail = AsyncThumbnail(
        thumbnailKey: _thumbnailKey('change'),
        generator: (ctx, {required force}) async =>
            Uri.parse('file:///tmp/old.png'),
      );

      Map<String, AsyncThumbnail>? result;
      service.generateThumbnails(
        slides: [_slide('change', thumbnailKey: 'thumbnail_change_v2.png')],
        context: context,
        cache: {'change': oldThumbnail},
        onCacheUpdate: (cache) => result = cache,
      );

      expect(identical(result!['change'], oldThumbnail), isFalse);
      expect(result!['change']!.thumbnailKey, 'thumbnail_change_v2.png');
    });

    testWidgets(
        'regenerates only changed slides when presentation content updates',
        (tester) async {
      final context = await _pumpContext(tester);

      // 1. Initial generation — all cache misses
      Map<String, AsyncThumbnail>? first;
      service.generateThumbnails(
        slides: [_slide('a'), _slide('b'), _slide('c')],
        context: context,
        cache: {},
        onCacheUpdate: (cache) => first = cache,
      );

      expect(first!.length, 3);

      // 2. Simulate content edit: slide B changed (new thumbnailKey), A & C unchanged
      Map<String, AsyncThumbnail>? second;
      service.generateThumbnails(
        slides: [
          _slide('a'),
          _slide('b', thumbnailKey: 'thumbnail_b_v2.png'),
          _slide('c'),
        ],
        context: context,
        cache: first!,
        onCacheUpdate: (cache) => second = cache,
      );

      expect(second!.length, 3);

      // A and C reused (same instance)
      expect(identical(second!['a'], first!['a']), isTrue);
      expect(identical(second!['c'], first!['c']), isTrue);

      // B replaced with new thumbnailKey
      expect(identical(second!['b'], first!['b']), isFalse);
      expect(second!['b']!.thumbnailKey, 'thumbnail_b_v2.png');
    });

    testWidgets('removed slides are absent from updated cache', (tester) async {
      final context = await _pumpContext(tester);

      // Start with 3 slides
      Map<String, AsyncThumbnail>? firstResult;
      service.generateThumbnails(
        slides: [_slide('keep'), _slide('drop'), _slide('also-keep')],
        context: context,
        cache: {},
        onCacheUpdate: (cache) => firstResult = cache,
      );
      expect(firstResult!.length, 3);

      // Simulate controller's stale cleanup
      firstResult!['drop']!.dispose();
      final cleanedCache = Map<String, AsyncThumbnail>.from(firstResult!)
        ..remove('drop');

      // Regenerate with 2 slides
      Map<String, AsyncThumbnail>? secondResult;
      service.generateThumbnails(
        slides: [_slide('keep'), _slide('also-keep')],
        context: context,
        cache: cleanedCache,
        onCacheUpdate: (cache) => secondResult = cache,
      );

      expect(secondResult!.length, 2);
      expect(secondResult!.containsKey('drop'), isFalse);
    });
  });
}
