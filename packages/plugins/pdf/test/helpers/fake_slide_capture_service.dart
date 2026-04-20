import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';

/// Test fake for [SlideCaptureService] that returns predefined bytes.
class FakeSlideCaptureService extends SlideCaptureService {
  FakeSlideCaptureService([Uint8List? bytes])
    : bytes = bytes ?? Uint8List.fromList([1, 2, 3]);

  final Uint8List bytes;

  int captureCalls = 0;
  int captureFromKeyCalls = 0;
  final List<String> capturedKeys = [];

  @override
  Future<Uint8List> capture({
    SlideCaptureQuality quality = SlideCaptureQuality.thumbnail,
    required SlideConfiguration slide,
    required BuildContext context,
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
