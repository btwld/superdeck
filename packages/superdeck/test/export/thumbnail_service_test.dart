import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/export/async_thumbnail.dart';
import 'package:superdeck/src/export/slide_capture_service.dart';
import 'package:superdeck/src/export/thumbnail_service.dart';
import 'package:superdeck/src/styling/styling.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('ThumbnailService', () {
    late ThumbnailService service;
    late _FakeSlideCaptureService captureService;
    late Directory tempDir;

    setUp(() async {
      captureService = _FakeSlideCaptureService();
      service = ThumbnailService(slideCaptureService: captureService);
      tempDir = await Directory.systemTemp.createTemp('thumbnail_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('syncs cache entries for slides with thumbnail files', () {
      final slide = _buildSlide(
        key: 'slide-a',
        thumbnailFile: '${tempDir.path}/thumbnail_a.png',
      );

      Map<String, AsyncThumbnail>? updated;
      service.generateThumbnails(
        slides: [slide],
        cache: {},
        onCacheUpdate: (cache) => updated = cache,
      );

      expect(updated, isNotNull);
      expect(updated!.containsKey('slide-a'), isTrue);
    });

    test('removes cache entries for null/empty thumbnail paths', () {
      final existingA = AsyncThumbnail(generator: (_, __) async => null);
      final existingB = AsyncThumbnail(generator: (_, __) async => null);
      final cache = <String, AsyncThumbnail>{'a': existingA, 'b': existingB};

      Map<String, AsyncThumbnail>? updated;
      service.generateThumbnails(
        slides: [
          _buildSlide(key: 'a', thumbnailFile: null),
          _buildSlide(key: 'b', thumbnailFile: ''),
        ],
        cache: cache,
        onCacheUpdate: (next) => updated = next,
      );

      expect(updated, isNotNull);
      expect(updated, isEmpty);
    });

    test('removes stale cache entries for deleted slides', () {
      final stale = AsyncThumbnail(generator: (_, __) async => null);
      final cache = <String, AsyncThumbnail>{'stale': stale};

      Map<String, AsyncThumbnail>? updated;
      service.generateThumbnails(
        slides: [],
        cache: cache,
        onCacheUpdate: (next) => updated = next,
      );

      expect(updated, isNotNull);
      expect(updated, isEmpty);
    });

    test(
      'load generates missing thumbnails and creates parent directories',
      () async {
        final missingPath =
            '${tempDir.path}/nonexistent/subdir/thumbnail_missing.png';
        final parentDir = Directory('${tempDir.path}/nonexistent/subdir');
        final file = File(missingPath);
        expect(await parentDir.exists(), isFalse);
        expect(await file.exists(), isFalse);

        var cache = <String, AsyncThumbnail>{};
        service.generateThumbnails(
          slides: [_buildSlide(key: 'missing', thumbnailFile: missingPath)],
          cache: cache,
          onCacheUpdate: (next) => cache = next,
        );

        await cache['missing']!.load(_FakeBuildContext());

        expect(await parentDir.exists(), isTrue);
        expect(await file.exists(), isTrue);
        expect(await file.length(), greaterThan(0));
        expect(captureService.captureCalls, 1);
      },
    );

    test('load reuses existing thumbnails when force is false', () async {
      final thumbnailPath = '${tempDir.path}/thumbnail_ok.png';
      final file = File(thumbnailPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x00]);
      final originalLength = await file.length();

      var cache = <String, AsyncThumbnail>{};
      service.generateThumbnails(
        slides: [_buildSlide(key: 'ok', thumbnailFile: thumbnailPath)],
        cache: cache,
        onCacheUpdate: (next) => cache = next,
      );

      await cache['ok']!.load(_FakeBuildContext());

      expect(await file.exists(), isTrue);
      expect(await file.length(), originalLength);
      expect(captureService.captureCalls, 0);
    });

    test('force load regenerates and overwrites existing thumbnails', () async {
      final thumbnailPath = '${tempDir.path}/thumbnail_force.png';
      final file = File(thumbnailPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

      captureService.nextBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0xAA,
        0xBB,
      ]);

      var cache = <String, AsyncThumbnail>{};
      service.generateThumbnails(
        slides: [_buildSlide(key: 'force', thumbnailFile: thumbnailPath)],
        cache: cache,
        onCacheUpdate: (next) => cache = next,
      );

      await cache['force']!.load(_FakeBuildContext(), true);

      final bytes = await file.readAsBytes();
      expect(bytes, equals(captureService.nextBytes));
      expect(captureService.captureCalls, 1);
    });

    test(
      'load falls back to app cache when configured thumbnail path is not writable',
      () async {
        final slideKey = 'fallback-${tempDir.uri.pathSegments.last}';
        final invalidThumbnailPath = tempDir.path;

        var cache = <String, AsyncThumbnail>{};
        final slide = _buildSlide(
          key: slideKey,
          thumbnailFile: invalidThumbnailPath,
        );

        service.generateThumbnails(
          slides: [slide],
          cache: cache,
          onCacheUpdate: (next) => cache = next,
        );
        await cache[slideKey]!.load(_FakeBuildContext());
        expect(captureService.captureCalls, 1);

        cache = <String, AsyncThumbnail>{};
        service.generateThumbnails(
          slides: [slide],
          cache: cache,
          onCacheUpdate: (next) => cache = next,
        );
        await cache[slideKey]!.load(_FakeBuildContext());

        // Second load should resolve from fallback cache instead of recapturing.
        expect(captureService.captureCalls, 1);
      },
    );

    test(
      'recreates cache entry when thumbnail path changes for same slide key',
      () {
        final firstPath = '${tempDir.path}/thumb_a.png';
        final secondPath = '${tempDir.path}/thumb_b.png';
        final firstSlide = _buildSlide(
          key: 'refresh',
          thumbnailFile: firstPath,
        );
        final secondSlide = _buildSlide(
          key: 'refresh',
          thumbnailFile: secondPath,
        );

        var cache = <String, AsyncThumbnail>{};
        service.generateThumbnails(
          slides: [firstSlide],
          cache: cache,
          onCacheUpdate: (next) => cache = next,
        );

        final initial = cache['refresh']!;

        service.generateThumbnails(
          slides: [secondSlide],
          cache: cache,
          onCacheUpdate: (next) => cache = next,
        );

        final refreshed = cache['refresh']!;
        expect(identical(refreshed, initial), isFalse);
        expect(refreshed.filePath, secondPath);
      },
    );
  });
}

class _FakeSlideCaptureService extends SlideCaptureService {
  Uint8List nextBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
  int captureCalls = 0;

  @override
  Future<Uint8List> capture({
    SlideCaptureQuality quality = SlideCaptureQuality.thumbnail,
    required SlideConfiguration slide,
    required BuildContext context,
  }) async {
    captureCalls++;
    return nextBytes;
  }
}

SlideConfiguration _buildSlide({
  required String key,
  required String? thumbnailFile,
}) {
  return SlideConfiguration(
    slideIndex: 0,
    style: SlideStyle(),
    slide: Slide(
      key: key,
      sections: [
        SectionBlock([ContentBlock('Content')]),
      ],
    ),
    thumbnailFile: thumbnailFile,
  );
}

class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
