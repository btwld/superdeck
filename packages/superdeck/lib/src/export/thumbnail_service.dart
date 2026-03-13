import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../deck/slide_configuration.dart';
import 'async_thumbnail.dart';
import 'slide_capture_service.dart';

/// Stateless service for thumbnail generation operations.
///
/// Handles thumbnail generation and cache management without maintaining
/// any state. The controller using this service owns the cache and is
/// notified of updates via the [onCacheUpdate] callback.
class ThumbnailService {
  final AssetCacheStore _cacheStore;
  final SlideCaptureService _slideCaptureService;

  /// Creates a ThumbnailService.
  ///
  /// [cacheStore] is required and handles key-based cache resolution.
  /// [slideCaptureService] can be injected for testing. If not provided,
  /// a default instance is created.
  ThumbnailService({
    required AssetCacheStore cacheStore,
    SlideCaptureService? slideCaptureService,
  }) : _cacheStore = cacheStore,
       _slideCaptureService = slideCaptureService ?? SlideCaptureService();

  AsyncThumbnail _createThumbnail(
    SlideConfiguration slide,
    Map<String, AsyncThumbnail> cache,
  ) {
    final thumbnail = AsyncThumbnail(
      thumbnailKey: slide.thumbnailKey,
      generator: (ctx, {required force}) =>
          generateThumbnail(slide: slide, context: ctx, force: force),
    );
    cache[slide.key] = thumbnail;
    return thumbnail;
  }

  /// Generates thumbnails for all slides, updating the cache as needed.
  ///
  /// For each slide, either reuses an existing [AsyncThumbnail] from [cache]
  /// or replaces it when the runtime thumbnail key changes. Calls
  /// [onCacheUpdate] with the updated cache after processing all slides.
  ///
  /// If [force] is true, regenerates all thumbnails even if they exist.
  void generateThumbnails({
    required List<SlideConfiguration> slides,
    required BuildContext context,
    required Map<String, AsyncThumbnail> cache,
    required void Function(Map<String, AsyncThumbnail>) onCacheUpdate,
    bool force = false,
  }) {
    final updatedCache = Map<String, AsyncThumbnail>.from(cache);

    for (final slide in slides) {
      final existing = updatedCache[slide.key];
      late final AsyncThumbnail thumbnail;
      if (existing == null) {
        thumbnail = _createThumbnail(slide, updatedCache);
      } else if (existing.thumbnailKey == slide.thumbnailKey) {
        thumbnail = existing;
      } else {
        existing.dispose();
        thumbnail = _createThumbnail(slide, updatedCache);
      }

      thumbnail.load(context, force);
    }

    onCacheUpdate(updatedCache);
  }

  /// Generates a single thumbnail for a slide.
  ///
  /// Resolve order:
  /// 1. Cache store resolve for the exact runtime key
  /// 2. Capture/generate fresh
  /// 3. Cache store write
  ///
  /// Returns null when nothing can be resolved/generated.
  @visibleForTesting
  Future<Uri?> generateThumbnail({
    required SlideConfiguration slide,
    required BuildContext context,
    required bool force,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (!force) {
      final resolvedUri = await _cacheStore.resolve(slide.thumbnailKey);
      if (resolvedUri != null) {
        stopwatch.stop();
        debugPrint(
          '[ThumbnailService] Thumbnail cache hit [${slide.thumbnailKey}] in ${stopwatch.elapsedMilliseconds}ms',
        );
        return resolvedUri;
      }
    } else {
      await _cacheStore.delete(slide.thumbnailKey);
    }

    final imageData = await _slideCaptureService.capture(
      slide: slide,
      // ignore: use_build_context_synchronously
      context: context,
    );

    final uri = await _cacheStore.write(slide.thumbnailKey, imageData);

    stopwatch.stop();
    debugPrint(
      '[ThumbnailService] Thumbnail ${force ? "force-" : ""}generated [${slide.thumbnailKey}] in ${stopwatch.elapsedMilliseconds}ms',
    );

    return uri;
  }
}
