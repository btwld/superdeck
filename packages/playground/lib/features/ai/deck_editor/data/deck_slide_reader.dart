import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';

import '../ai/deck_tool_schemas.dart';
import '../domain/deck_tool_error.dart';

typedef SlideCaptureCallback =
    Future<Uint8List> Function({
      required SlideConfiguration slide,
      required BuildContext context,
      required SlideCaptureQuality quality,
    });

/// Reads and captures one slide from a single immutable live configuration list.
final class DeckSlideReader {
  DeckSlideReader({
    required BuildContext context,
    required DeckController deckController,
    SlideCaptureCallback? capture,
  }) : _context = context,
       _deckController = deckController,
       _capture = capture ?? SlideCaptureService().capture;

  final BuildContext _context;
  final DeckController _deckController;
  final SlideCaptureCallback _capture;

  Future<Map<String, Object?>> read(int index) async {
    final snapshot = List<SlideConfiguration>.unmodifiable(
      _deckController.slides.value,
    );
    if (index < 0 || index >= snapshot.length) {
      throw DeckToolError(
        DeckToolErrorCode.slideIndexOutOfRange,
        'Slide index $index is outside the live preview.',
      );
    }
    if (!_context.mounted) {
      throw const DeckToolError(
        DeckToolErrorCode.contextUnavailable,
        'The deck editing route is no longer mounted.',
      );
    }

    final configuration = snapshot[index];
    final Uint8List bytes;
    try {
      bytes = await _capture(
        slide: configuration,
        context: _context,
        quality: SlideCaptureQuality.thumbnail,
      );
    } catch (error) {
      if (!_context.mounted) {
        throw DeckToolError(
          DeckToolErrorCode.contextUnavailable,
          'The deck editing route is no longer mounted.',
          cause: error,
        );
      }
      throw DeckToolError(
        DeckToolErrorCode.captureFailed,
        'The slide thumbnail could not be rendered.',
        cause: error,
      );
    }
    if (bytes.isEmpty) {
      throw const DeckToolError(
        DeckToolErrorCode.captureFailed,
        'The slide thumbnail renderer returned no image data.',
      );
    }

    final slides = [for (final item in snapshot) item.slide];
    final slide = configuration.slide;
    return {
      'index': index,
      'title': ?slide.options?.title,
      'slide': slideToKeylessMap(slide),
      'thumbnailBase64': base64Encode(bytes),
      'deck': deckSnapshot(slides),
    };
  }
}
