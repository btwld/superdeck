import 'dart:async';

import 'package:flutter/widgets.dart';

import '../deck/slide_configuration.dart';
import 'async_thumbnail.dart';
import 'slide_capture_service.dart';
import 'thumbnail_cache_store.dart';

/// Stateless service for runtime thumbnail generation and cache synchronization.
///
/// Handles thumbnail generation + cache synchronization without maintaining
/// any state.
/// The controller using this service owns the cache and is notified of
/// updates via the [onCacheUpdate] callback.
class ThumbnailService {
  final SlideCaptureService _slideCaptureService;
  final ThumbnailCacheStore _cacheStore;

  ThumbnailService({
    SlideCaptureService? slideCaptureService,
    ThumbnailCacheStore? cacheStore,
  }) : _slideCaptureService = slideCaptureService ?? SlideCaptureService(),
       _cacheStore = cacheStore ?? createThumbnailCacheStore();

  /// Synchronizes thumbnail entries for all slides, updating cache as needed.
  ///
  /// For each slide, either reuses an existing [AsyncThumbnail] from [cache],
  /// creates a new [AsyncThumbnail], or removes entries for slides
  /// without thumbnail paths.
  void generateThumbnails({
    required List<SlideConfiguration> slides,
    required Map<String, AsyncThumbnail> cache,
    required void Function(Map<String, AsyncThumbnail>) onCacheUpdate,
  }) {
    final updatedCache = Map<String, AsyncThumbnail>.from(cache);
    final currentKeys = slides.map((slide) => slide.key).toSet();

    for (final entry in cache.entries) {
      if (!currentKeys.contains(entry.key)) {
        unawaited(
          _cacheStore.delete(
            slideKey: entry.key,
            filePath: entry.value.filePath,
          ),
        );
        updatedCache.remove(entry.key)?.dispose();
      }
    }

    for (final slide in slides) {
      final thumbnailFile = slide.thumbnailFile;
      if (thumbnailFile == null || thumbnailFile.isEmpty) {
        final existing = updatedCache.remove(slide.key);
        if (existing != null) {
          unawaited(
            _cacheStore.delete(
              slideKey: slide.key,
              filePath: existing.filePath,
            ),
          );
          existing.dispose();
        }
        continue;
      }

      final thumbnail = updatedCache.putIfAbsent(
        slide.key,
        () => AsyncThumbnail(
          filePath: thumbnailFile,
          generator: (context, force) =>
              _resolveOrGenerateThumbnail(slide, context, force),
        ),
      );
      // Recreate entry if path changed or previous resolution ended with no URI.
      if (thumbnail.filePath != thumbnailFile ||
          thumbnail.shouldRefreshOnSync) {
        unawaited(
          _cacheStore.delete(slideKey: slide.key, filePath: thumbnail.filePath),
        );
        updatedCache.remove(slide.key)?.dispose();
        updatedCache[slide.key] = AsyncThumbnail(
          filePath: thumbnailFile,
          generator: (context, force) =>
              _resolveOrGenerateThumbnail(slide, context, force),
        );
      }
    }

    onCacheUpdate(updatedCache);
  }

  /// Resolves a thumbnail URI for a slide or generates and caches it.
  ///
  /// Returns `null` only when generation or persistence cannot produce a URI.
  Future<Uri?> _resolveOrGenerateThumbnail(
    SlideConfiguration slide,
    BuildContext context,
    bool force,
  ) async {
    final thumbnailFile = slide.thumbnailFile;
    if (!force) {
      final cached = await _cacheStore.resolve(
        slideKey: slide.key,
        filePath: thumbnailFile,
      );
      if (cached != null) {
        return cached;
      }
    }

    if (context case Element element when !element.mounted) {
      return null;
    }

    final imageData = await _slideCaptureService.capture(
      slide: slide,
      // ignore: use_build_context_synchronously
      context: context,
    );

    final cachedUri = await _cacheStore.write(
      slideKey: slide.key,
      filePath: thumbnailFile,
      bytes: imageData,
    );
    if (cachedUri != null) {
      return cachedUri;
    }

    if (thumbnailFile == null || thumbnailFile.isEmpty) {
      return null;
    }

    return Uri.file(thumbnailFile);
  }
}
