import 'dart:io';

import 'package:flutter/widgets.dart';

import '../deck/slide_configuration.dart';
import 'async_thumbnail.dart';
import 'slide_capture_service.dart';

/// Stateless service for thumbnail generation operations.
///
/// Handles thumbnail generation and cache management without maintaining
/// any state. The controller using this service owns the cache and is
/// notified of updates via the [onCacheUpdate] callback.
class ThumbnailService {
  final _slideCaptureService = SlideCaptureService();

  /// Generates thumbnails for all slides, updating the cache as needed.
  ///
  /// For each slide, either reuses an existing [AsyncThumbnail] from [cache]
  /// or creates a new one. Calls [onCacheUpdate] with the updated cache
  /// after processing all slides.
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
      final thumbnail = updatedCache.putIfAbsent(
        slide.key,
        () => AsyncThumbnail(
          generator: (ctx, force) => _generateThumbnail(slide, ctx, force),
        ),
      );
      thumbnail.load(context, force);
    }

    onCacheUpdate(updatedCache);
  }

  /// Generates a single thumbnail for a slide.
  ///
  /// Returns the existing thumbnail file if [force] is false and the file
  /// exists with non-zero size. Otherwise, captures a new thumbnail using
  /// [SlideCaptureService] and writes it to disk.
  Future<File> _generateThumbnail(
    SlideConfiguration slide,
    BuildContext context,
    bool force,
  ) async {
    final file = File(slide.thumbnailFile);

    if (!force && await file.exists() && await file.length() > 0) {
      return file;
    }

    final imageData = await _slideCaptureService.capture(
      slide: slide,
      // ignore: use_build_context_synchronously
      context: context,
    );

    await file.writeAsBytes(imageData);
    return file;
  }
}
