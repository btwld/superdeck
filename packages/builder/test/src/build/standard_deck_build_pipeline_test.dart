import 'package:superdeck_builder/src/build/deck_builder.dart';
import 'package:superdeck_builder/src/tasks/asset_generation_task.dart';
import 'package:superdeck_builder/src/tasks/dart_formatter_task.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/testing_utils.dart';

void main() {
  group('StandardDeckBuildPipeline', () {
    test('creates a deck builder with the standard task pipeline', () {
      final tempDir = createTempDir();
      final workspace = createTestWorkspace(tempDir);
      final store = DeckBuildStore(workspace: workspace);

      final builder = StandardDeckBuildPipeline.create(
        workspace: workspace,
        store: store,
      );

      expect(builder, isA<DeckBuilder>());
      expect(builder.tasks, hasLength(2));
      expect(builder.tasks.first, isA<DartFormatterTask>());
      expect(builder.tasks.last, isA<AssetGenerationTask>());
    });
  });
}
