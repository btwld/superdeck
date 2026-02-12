import 'dart:io';

import '../deck/slide_configuration.dart';
import 'async_thumbnail.dart';

/// Stateless service for read-only thumbnail cache operations.
///
/// Handles thumbnail cache synchronization without maintaining any state.
/// The controller using this service owns the cache and is notified of
/// updates via the [onCacheUpdate] callback.
class ThumbnailService {
  const ThumbnailService();

  /// Synchronizes thumbnail entries for all slides, updating cache as needed.
  ///
  /// For each slide, either reuses an existing [AsyncThumbnail] from [cache],
  /// creates a new read-only [AsyncThumbnail], or removes entries for slides
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
        updatedCache.remove(entry.key)?.dispose();
      }
    }

    for (final slide in slides) {
      final thumbnailFile = slide.thumbnailFile;
      if (thumbnailFile == null || thumbnailFile.isEmpty) {
        updatedCache.remove(slide.key)?.dispose();
        continue;
      }

      final thumbnail = updatedCache.putIfAbsent(
        slide.key,
        () => AsyncThumbnail(
          filePath: thumbnailFile,
          generator: (_, force) => _resolveThumbnailFile(slide, force),
        ),
      );
      // Recreate entry if path changed or previous resolution ended with no file.
      if (thumbnail.filePath != thumbnailFile ||
          thumbnail.shouldRefreshOnSync) {
        updatedCache.remove(slide.key)?.dispose();
        updatedCache[slide.key] = AsyncThumbnail(
          filePath: thumbnailFile,
          generator: (_, force) => _resolveThumbnailFile(slide, force),
        );
      }
    }

    onCacheUpdate(updatedCache);
  }

  /// Resolves a thumbnail file for a slide without generating or writing files.
  ///
  /// Returns `null` if the thumbnail file is absent or empty.
  Future<File?> _resolveThumbnailFile(SlideConfiguration slide, bool _) async {
    final thumbnailFile = slide.thumbnailFile;
    if (thumbnailFile == null || thumbnailFile.isEmpty) {
      return null;
    }

    final file = File(thumbnailFile);
    if (!await file.exists()) {
      return null;
    }

    final length = await file.length();
    if (length <= 0) {
      return null;
    }

    return file;
  }
}
