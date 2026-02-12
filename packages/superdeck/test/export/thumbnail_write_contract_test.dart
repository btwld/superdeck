import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runtime thumbnail pipeline contains no filesystem write calls',
    () async {
      final source = await File(
        'lib/src/export/thumbnail_service.dart',
      ).readAsString();

      expect(source.contains('writeAsBytes('), isFalse);
      expect(source.contains('create(recursive: true)'), isFalse);
      expect(source.contains('SlideCaptureService'), isFalse);
    },
  );
}
