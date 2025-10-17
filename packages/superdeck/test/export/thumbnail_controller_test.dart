import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/export/thumbnail_controller.dart';

void main() {
  group('AsyncThumbnail', () {
    test('initializes correctly', () async {
      final thumbnail = AsyncThumbnail(
        generator: (context, force) async {
          throw UnimplementedError('Test generator');
        },
      );

      // Just verify it was created successfully
      expect(thumbnail, isNotNull);

      thumbnail.dispose();
    });

    // Note: Dispose test skipped - requires BuildContext and proper lifecycle

    // Note: Full thumbnail capture tests would require widget testing
    // with a real BuildContext and file system mocking
  });
}
