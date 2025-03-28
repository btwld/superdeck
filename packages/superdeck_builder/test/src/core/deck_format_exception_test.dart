import 'package:superdeck_builder/src/core/deck_format_exception.dart';
import 'package:test/test.dart';

void main() {
  group('DeckFormatException', () {
    test('constructs properly with given values', () {
      final exception =
          DeckFormatException('Invalid format', 'source text', 10);

      expect(exception.message, equals('Invalid format'));
      expect(exception.source, equals('source text'));
      expect(exception.offset, equals(10));
    });

    test('extends FormatException', () {
      final exception =
          DeckFormatException('Invalid format', 'source text', 10);

      expect(exception, isA<FormatException>());
    });
  });
}
