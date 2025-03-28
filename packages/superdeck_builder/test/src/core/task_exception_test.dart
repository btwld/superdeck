import 'package:superdeck_builder/src/core/task_exception.dart';
import 'package:test/test.dart';

void main() {
  group('TaskException', () {
    test('constructs properly with given values', () {
      final exception = TaskException('testTask', Exception('test'), 5);

      expect(exception.taskName, equals('testTask'));
      expect(exception.originalException, isA<Exception>());
      expect(exception.slideIndex, equals(5));
    });

    test('toString returns formatted message', () {
      final exception = TaskException('testTask', Exception('test'), 5);

      expect(
        exception.toString(),
        equals('Error in task "testTask" at slide index 5: Exception: test'),
      );
    });
  });
}
