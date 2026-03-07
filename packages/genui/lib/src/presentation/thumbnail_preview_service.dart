import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck/tooling.dart';

import '../ai/schemas/deck_schemas.dart';
import '../debug_logger.dart';
import '../utils/style_builder.dart';

/// Function signature for capturing a single slide as a PNG image.
///
/// Abstracted to allow test injection without depending on
/// [SlideCaptureService] (which is not part of SuperDeck's public API).
typedef SlideCaptureFn =
    Future<Uint8List> Function(SlideData slide, BuildContext context);

/// Service for generating slide thumbnail previews from slide data.
///
/// Accepts slides directly (no disk I/O), builds [SlideData]s,
/// and uses [SlideCaptureService] to render each slide offscreen at
/// thumbnail quality.
///
/// The capture function can be injected via [captureSlide] for testing.
class ThumbnailPreviewService {
  ThumbnailPreviewService({SlideCaptureFn? captureSlide})
    : _captureSlide = captureSlide;

  final SlideCaptureFn? _captureSlide;

  /// Lazily created default capture service instance.
  SlideCaptureService? _defaultService;

  Future<Uint8List> _capture(SlideData slide, BuildContext context) {
    if (_captureSlide case final fn?) return fn(slide, context);
    _defaultService ??= SlideCaptureService();
    return _defaultService!.capture(
      slide: slide,
      context: context,
      quality: SlideCaptureQuality.thumbnail,
    );
  }

  /// Generates thumbnail previews for the given [slides].
  ///
  /// Builds slide configurations with the provided [style], then captures
  /// each slide as a thumbnail-quality PNG.
  ///
  /// Calls [onThumbnailCaptured] as each slide is captured, allowing the UI
  /// to display thumbnails incrementally.
  ///
  /// Checks [isCancelled] before each capture to support cancellation.
  /// Stops early if the [context] is unmounted.
  ///
  /// Returns the list of captured thumbnails with their original slide index.
  Future<List<(int, Uint8List)>> generatePreviews({
    required BuildContext context,
    required List<Slide> slides,
    DeckStyleType? style,
    void Function(int slideIndex, Uint8List imageBytes)? onThumbnailCaptured,
    bool Function()? isCancelled,
  }) async {
    debugLog.section('Thumbnail Preview Generation');

    if (slides.isEmpty) return [];

    final configuration = DeckWorkspace();
    final theme = buildDeckThemeFromStyle(style);
    final slideBuilder = SlideDataBuilder(configuration: configuration);
    final slideConfigs = slideBuilder.buildSlides(slides, theme);

    debugLog.log(
      'THUMBNAIL',
      'Generating previews for ${slideConfigs.length} slides',
    );

    final thumbnails = <(int, Uint8List)>[];

    for (var i = 0; i < slideConfigs.length; i++) {
      if (isCancelled?.call() ?? false) {
        debugLog.log('THUMBNAIL', 'Generation cancelled at slide $i');
        break;
      }

      if (!context.mounted) {
        debugLog.log('THUMBNAIL', 'Context unmounted, stopping at slide $i');
        break;
      }

      try {
        final imageBytes = await _capture(slideConfigs[i], context);
        thumbnails.add((i, imageBytes));
        onThumbnailCaptured?.call(i, imageBytes);

        debugLog.log(
          'THUMBNAIL',
          'Captured slide $i/${slideConfigs.length} '
              '(${imageBytes.length} bytes)',
        );
      } catch (e) {
        debugLog.log('THUMBNAIL', 'Failed to capture slide $i: $e');
      }
    }

    debugLog.log(
      'THUMBNAIL',
      'Preview generation complete: '
          '${thumbnails.length}/${slideConfigs.length} slides captured',
    );

    return thumbnails;
  }
}
