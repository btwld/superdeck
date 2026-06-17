import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';

/// Test fake for [SlideCaptureService] that returns predefined bytes.
class FakeSlideCaptureService extends SlideCaptureService {
  FakeSlideCaptureService([Uint8List? bytes])
    : bytes = bytes ?? Uint8List.fromList([1, 2, 3]);

  final Uint8List bytes;

  int captureFromKeyCalls = 0;

  @override
  Future<Uint8List> capture({
    SlideCaptureQuality quality = SlideCaptureQuality.thumbnail,
    required SlideConfiguration slide,
    required BuildContext context,
  }) async {
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
