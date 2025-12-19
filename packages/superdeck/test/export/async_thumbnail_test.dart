import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/export/async_thumbnail.dart';

void main() {
  group('AsyncThumbnail', () {
    group('initialization', () {
      test('initializes with idle status', () {
        final thumbnail = AsyncThumbnail(
          generator: (context, force) async {
            throw UnimplementedError('Should not be called');
          },
        );

        expect(thumbnail.status.value, equals(AsyncFileStatus.idle));
        expect(thumbnail.error.value, isNull);
        expect(thumbnail.imageProvider, isNull);

        thumbnail.dispose();
      });

      test('imageProvider returns null when no file loaded', () {
        final thumbnail = AsyncThumbnail(
          generator: (context, force) async {
            throw UnimplementedError('Should not be called');
          },
        );

        expect(thumbnail.imageProvider, isNull);

        thumbnail.dispose();
      });
    });

    group('disposal', () {
      test('can be disposed without loading', () {
        final thumbnail = AsyncThumbnail(
          generator: (context, force) async {
            throw UnimplementedError('Should not be called');
          },
        );

        // Should not throw
        thumbnail.dispose();
      });

      test('double dispose does not throw', () {
        final thumbnail = AsyncThumbnail(
          generator: (context, force) async {
            throw UnimplementedError('Should not be called');
          },
        );

        thumbnail.dispose();
        // Second dispose should not throw
        thumbnail.dispose();
      });
    });

    // Note: Widget tests for load/generate behavior are skipped because
    // signals_flutter and Flutter's widget testing framework have timing
    // issues that cause tests to hang. The core functionality is tested
    // via the DeckController tests and integration testing.
  });
}
