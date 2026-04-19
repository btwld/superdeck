import 'dart:async';
import 'dart:io';

import 'package:superdeck_builder/src/build/build_event.dart';
import 'package:superdeck_builder/src/build/deck_builder.dart';
import 'package:superdeck_builder/src/build/task_exception.dart';
import 'package:superdeck_builder/src/tasks/slide_context.dart';
import 'package:superdeck_builder/src/tasks/task.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/testing_utils.dart';

final class ThrowingTask extends Task {
  ThrowingTask() : super('throwing_task');

  @override
  Future<void> run(SlideContext context) async {
    throw Exception('boom');
  }
}

void main() {
  group('DeckBuilder.watchAndBuild', () {
    late Directory tempDir;
    late DeckWorkspace workspace;
    late DeckBuildStore store;

    setUp(() {
      tempDir = createTempDir(prefix: 'deck_builder_watch_test');
      workspace = createTestWorkspace(tempDir);
      store = DeckBuildStore(workspace: workspace);
    });

    test('emits BuildStarted before the initial build result', () async {
      final builder = DeckBuilder(
        tasks: const [],
        workspace: workspace,
        store: store,
      );
      final iterator = StreamIterator(builder.watchAndBuild());
      addTearDown(iterator.cancel);
      addTearDown(builder.dispose);

      await workspace.slidesFile.writeAsString('# First Slide');

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isA<BuildStarted>());
    });

    test('emits BuildCompleted after a successful build', () async {
      final builder = DeckBuilder(
        tasks: const [],
        workspace: workspace,
        store: store,
      );
      final iterator = StreamIterator(builder.watchAndBuild());
      addTearDown(iterator.cancel);
      addTearDown(builder.dispose);

      await workspace.slidesFile.writeAsString('# First Slide');

      await _nextEvent(iterator);
      final event = await _nextEvent(iterator);

      expect(
        event,
        isA<BuildCompleted>().having(
          (event) => event.slides,
          'slides',
          hasLength(1),
        ),
      );
    });

    test('emits BuildFailed when a task fails', () async {
      final builder = DeckBuilder(
        tasks: [ThrowingTask()],
        workspace: workspace,
        store: store,
      );
      final iterator = StreamIterator(builder.watchAndBuild());
      addTearDown(iterator.cancel);
      addTearDown(builder.dispose);

      await workspace.slidesFile.writeAsString('# First Slide');

      await _nextEvent(iterator);
      final event = await _nextEvent(iterator);

      expect(
        event,
        isA<BuildFailed>()
            .having((event) => event.error, 'error', isA<TaskException>())
            .having((event) => event.stackTrace, 'stackTrace', isNotNull),
      );
    });

    test('emits started and completed for a rebuild cycle', () async {
      final builder = DeckBuilder(
        tasks: const [],
        workspace: workspace,
        store: store,
      );
      final iterator = StreamIterator(builder.watchAndBuild());
      addTearDown(iterator.cancel);
      addTearDown(builder.dispose);

      await workspace.slidesFile.writeAsString('# First Slide');

      expect(await _nextEvent(iterator), isA<BuildStarted>());
      expect(await _nextEvent(iterator), isA<BuildCompleted>());

      final rebuildStarted = _nextEvent(iterator);
      await _modifySlidesFile(workspace, '# Second Slide');

      expect(await rebuildStarted, isA<BuildStarted>());
      expect(await _nextEvent(iterator), isA<BuildCompleted>());
    });
  });
}

Future<BuildEvent> _nextEvent(StreamIterator<BuildEvent> iterator) async {
  final hasEvent = await iterator.moveNext().timeout(
    const Duration(seconds: 5),
  );
  expect(hasEvent, isTrue);

  return iterator.current;
}

Future<void> _modifySlidesFile(
  DeckWorkspace workspace,
  String markdown,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await workspace.slidesFile.writeAsString(markdown);
}
