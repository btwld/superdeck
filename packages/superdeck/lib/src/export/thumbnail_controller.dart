import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import '../utils/constants.dart';
import 'async_thumbnail.dart';
import 'slide_capture_service.dart';

/// A controller that manages thumbnail images for slides.
class ThumbnailController extends ChangeNotifier {
  ThumbnailController();

  final Map<String, AsyncThumbnail> _thumbnails = {};
  final _slideCaptureService = SlideCaptureService();

  void generateThumbnails(
    List<SlideConfiguration> slides,
    BuildContext context, {
    bool force = false,
  }) {
    for (final slide in slides) {
      _getAsyncThumbnail(slide, context).load(context, force);
    }
  }

  /// Clears all cached thumbnails and forces complete regeneration.
  ///
  /// This is more aggressive than [generateThumbnails] with force=true,
  /// as it disposes of all thumbnail controllers and recreates them from scratch.
  void clearAndRegenerate(
    List<SlideConfiguration> slides,
    BuildContext context,
  ) {
    // Dispose all existing thumbnails
    for (final thumbnail in _thumbnails.values) {
      thumbnail.dispose();
    }
    _thumbnails.clear();

    // Regenerate all thumbnails from scratch
    generateThumbnails(slides, context, force: true);
  }

  @override
  void dispose() {
    super.dispose();

    for (final thumbnail in _thumbnails.values) {
      thumbnail.dispose();
    }
    _thumbnails.clear();
  }

  AsyncThumbnail get(SlideConfiguration slide, BuildContext context) {
    return _getAsyncThumbnail(slide, context)..load(context);
  }

  AsyncThumbnail _getAsyncThumbnail(
    SlideConfiguration slide,
    BuildContext context,
  ) {
    return _thumbnails.putIfAbsent(slide.key, () {
      return AsyncThumbnail(
        generator: (context, force) async {
          return _generateThumbnail(
            slide: slide,
            context: context,
            force: force,
          );
        },
      );
    });
  }

  Future<File> _generateThumbnail({
    required SlideConfiguration slide,
    required BuildContext context,
    required bool force,
  }) async {
    final thumbnailFile = File(slide.thumbnailFile);

    if (!kCanRunProcess) {
      return thumbnailFile;
    }

    final isValid =
        await thumbnailFile.exists() && (await thumbnailFile.length()) > 0;

    if (isValid && !force) {
      return thumbnailFile;
    }

    final imageData = await _slideCaptureService.capture(
      slide: slide,
      // ignore: use_build_context_synchronously
      context: context,
    );

    await thumbnailFile.writeAsBytes(imageData, flush: false);

    return thumbnailFile;
  }

  static ThumbnailController of(BuildContext context) {
    return InheritedNotifierData.of<ThumbnailController>(context);
  }
}
