import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/capture/slide_capture_service.dart';

/// Test fake for [SlideCaptureService] that returns predefined bytes.
///
/// Overrides both [capture] and [captureFromKey] so thumbnail tests can avoid
/// rendering real slide images.
class FakeSlideCaptureService extends SlideCaptureService {
  FakeSlideCaptureService([Uint8List? bytes])
    : bytes = bytes ?? Uint8List.fromList([1, 2, 3]);

  final Uint8List bytes;

  /// Number of times [capture] was called.
  int captureCalls = 0;

  /// Number of times [captureFromKey] was called.
  int captureFromKeyCalls = 0;

  /// Slide keys passed to [capture], in order.
  final List<String> capturedKeys = [];

  @override
  Future<Uint8List> capture({
    SlideCaptureQuality quality = SlideCaptureQuality.thumbnail,
    required SlideConfiguration slide,
    required BuildContext context,
    bool includeDebugLayout = false,
  }) async {
    captureCalls++;
    capturedKeys.add(slide.key);
    return bytes;
  }

  @override
  Future<Uint8List> captureFromKey({
    required GlobalKey key,
    required SlideCaptureQuality quality,
  }) async {
    captureFromKeyCalls++;
    return bytes;
  }
}
