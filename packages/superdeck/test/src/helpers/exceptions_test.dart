import 'package:superdeck/src/helpers/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('DeckTaskException', () {
    test('constructs properly with given values', () {
      final exception = DeckTaskException('testTask', Exception('test'), 5);

      expect(exception.taskName, equals('testTask'));
      expect(exception.exception, isA<Exception>());
      expect(exception.slideIndex, equals(5));
    });

    test('formats message correctly', () {
      final exception = DeckTaskException('testTask', Exception('test'), 5);

      expect(exception.message, equals('Error running task on slide 5'));
    });

    test('toString returns message', () {
      final exception = DeckTaskException('testTask', Exception('test'), 5);

      expect(exception.toString(), equals(exception.message));
    });
  });

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
