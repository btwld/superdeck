import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:test/test.dart';

void main() {
  group('superdeck_builder public api', () {
    test('exports the supported build surface', () {
      final task = DartFormatterTask();
      final error = DeckFormatException('invalid', '', 0);

      expect(task, isA<Task>());
      expect(StandardDeckBuildPipeline.create, isNotNull);
      expect(DeckBuilder, isNotNull);
      expect(BuildStarted(), isA<BuildEvent>());
      expect(error, isA<Exception>());
    });
  });
}
