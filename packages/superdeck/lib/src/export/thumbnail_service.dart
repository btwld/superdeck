import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../slides/slide_data.dart';
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

  /// Generates thumbnails for all slides, updating the cache as needed.
  ///
  /// For each slide, either reuses an existing [AsyncThumbnail] from [cache]
  /// or creates a new one. Calls [onCacheUpdate] with the updated cache
  /// after processing all slides.
  ///
  /// If [force] is true, regenerates all thumbnails even if they exist.
  void generateThumbnails({
    required List<SlideData> slides,
    required BuildContext context,
    required Map<String, AsyncThumbnail> cache,
    required void Function(Map<String, AsyncThumbnail>) onCacheUpdate,
    bool force = false,
  }) {
    final updatedCache = Map<String, AsyncThumbnail>.from(cache);

    for (final slide in slides) {
      final thumbnail = updatedCache.putIfAbsent(
        slide.key,
        () => AsyncThumbnail(
          generator: (ctx, {required force}) =>
              generateThumbnail(slide: slide, context: ctx, force: force),
        ),
      );
      thumbnail.load(context, force);
    }

    onCacheUpdate(updatedCache);
  }

  /// Generates a single thumbnail for a slide.
  ///
  /// Resolve order:
  /// 1. Cache store resolve (app cache first, then bundled fallback by platform)
  /// 2. Capture/generate fresh
  /// 3. Cache store write
  ///
  /// Returns null when nothing can be resolved/generated.
  @visibleForTesting
  Future<Uri?> generateThumbnail({
    required SlideData slide,
    required BuildContext context,
    required bool force,
  }) async {
    if (!force) {
      final resolvedUri = await _cacheStore.resolve(slide.thumbnailFile);
      if (resolvedUri != null) {
        return resolvedUri;
      }
    } else {
      await _cacheStore.delete(slide.thumbnailFile);
    }

    final imageData = await _slideCaptureService.capture(
      slide: slide,
      // ignore: use_build_context_synchronously
      context: context,
    );

    return _cacheStore.write(slide.thumbnailFile, imageData);
  }
}
