import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/export/async_thumbnail.dart';
import 'package:superdeck/src/export/thumbnail_service.dart';
import 'package:superdeck/src/styling/styling.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('ThumbnailService', () {
    late ThumbnailService service;
    late Directory tempDir;

    setUp(() async {
      service = const ThumbnailService();
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

    test('sync does not create missing parent directories', () async {
      final missingPath =
          '${tempDir.path}/nonexistent/subdir/thumbnail_missing.png';
      final parentDir = Directory('${tempDir.path}/nonexistent/subdir');
      final file = File(missingPath);
      expect(await parentDir.exists(), isFalse);
      expect(await file.exists(), isFalse);

      service.generateThumbnails(
        slides: [_buildSlide(key: 'missing', thumbnailFile: missingPath)],
        cache: {},
        onCacheUpdate: (_) {},
      );

      expect(await parentDir.exists(), isFalse);
      expect(await file.exists(), isFalse);
    });

    test('sync does not mutate existing thumbnail files', () async {
      final thumbnailPath = '${tempDir.path}/thumbnail_ok.png';
      final file = File(thumbnailPath);
      await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);
      final originalLength = await file.length();

      service.generateThumbnails(
        slides: [_buildSlide(key: 'ok', thumbnailFile: thumbnailPath)],
        cache: {},
        onCacheUpdate: (_) {},
      );

      expect(await file.exists(), isTrue);
      expect(await file.length(), originalLength);
    });

    test(
      'recreates unresolved entry when syncing a now-available file path',
      () async {
        final thumbnailPath = '${tempDir.path}/thumbnail_refresh.png';
        final slide = _buildSlide(key: 'refresh', thumbnailFile: thumbnailPath);

        var cache = <String, AsyncThumbnail>{};
        service.generateThumbnails(
          slides: [slide],
          cache: cache,
          onCacheUpdate: (next) => cache = next,
        );

        final initial = cache['refresh']!;
        expect(initial.shouldRefreshOnSync, isFalse);

        await initial.load(_FakeBuildContext());

        expect(initial.shouldRefreshOnSync, isTrue);

        final file = File(thumbnailPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

        service.generateThumbnails(
          slides: [slide],
          cache: cache,
          onCacheUpdate: (next) => cache = next,
        );

        final refreshed = cache['refresh']!;
        expect(identical(refreshed, initial), isFalse);
        expect(refreshed.shouldRefreshOnSync, isFalse);
      },
    );
  });
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
