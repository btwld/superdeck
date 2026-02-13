import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runtime thumbnail pipeline uses capture + platform cache abstraction',
    () async {
      final source = await File(
        'lib/src/export/thumbnail_service.dart',
      ).readAsString();

      expect(source.contains("import 'dart:io';"), isFalse);
      expect(source.contains('SlideCaptureService'), isTrue);
      expect(source.contains('createThumbnailCacheStore'), isTrue);
    },
  );
}
