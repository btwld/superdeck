import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../helpers/testing_utils.dart';
import 'package:superdeck_builder/src/build/deck_builder.dart';
import 'package:superdeck_builder/src/tasks/slide_context.dart';
import 'package:superdeck_builder/src/tasks/task.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

/// Mock Task for testing DeckBuilder lifecycle
final class MockTask extends Task {
  bool wasDisposed = false;
  final Duration? disposeDelay;
  final bool throwOnDispose;

  MockTask({this.disposeDelay, this.throwOnDispose = false})
    : super('MockTask');

  @override
  FutureOr<void> run(SlideContext context) {
    // No-op for testing
  }

  @override
  FutureOr<void> dispose() async {
    if (disposeDelay != null) {
      await Future.delayed(disposeDelay!);
    }
    if (throwOnDispose) {
      throw StateError('Simulated dispose error');
    }
    wasDisposed = true;
  }
}

void main() {
  group('DeckBuilder', () {
    group('build', () {
      late Directory tempDir;
      late DeckWorkspace workspace;
      late DeckBuildStore store;

      setUp(() {
        tempDir = createTempDir();
        workspace = createTestWorkspace(tempDir);
        store = DeckBuildStore(workspace: workspace);
      });

      test('deck json writes a raw slide array', () async {
        const markdown = '# First Slide\n\n---\n\n# Second Slide';
        final builder = DeckBuilder(
          tasks: [],
          workspace: workspace,
          store: store,
        );
        addTearDown(builder.dispose);

        await workspace.slidesFile.writeAsString(markdown);
        await builder.build();

        final deckJson =
            jsonDecode(await workspace.deckJson.readAsString())
                as List<dynamic>;

        expect(deckJson, hasLength(2));
        expect(deckJson.first, containsPair('key', isA<String>()));
      });

      test('full deck json also writes a raw slide array', () async {
        const markdown = '# First Slide\n\n---\n\n# Second Slide';
        final builder = DeckBuilder(
          tasks: [],
          workspace: workspace,
          store: store,
        );
        addTearDown(builder.dispose);

        await workspace.slidesFile.writeAsString(markdown);
        await builder.build();

        final fullDeckJson =
            jsonDecode(await workspace.deckFullJson.readAsString())
                as List<dynamic>;

        expect(fullDeckJson, hasLength(2));
        expect(fullDeckJson.first, containsPair('key', isA<String>()));
      });

      test('generated assets metadata excludes runtime thumbnails', () async {
        const markdown = '# First Slide\n\n---\n\n# Second Slide';
        final builder = DeckBuilder(
          tasks: [],
          workspace: workspace,
          store: store,
        );
        addTearDown(builder.dispose);

        await workspace.slidesFile.writeAsString(markdown);
        await builder.build();

        final assetsRef =
            jsonDecode(await workspace.assetsRefJson.readAsString())
                as Map<String, dynamic>;

        expect(assetsRef['files'], isEmpty);
      });
    });

    group('dispose', () {
      test('disposes all tasks', () async {
        final task1 = MockTask();
        final task2 = MockTask();
        final task3 = MockTask();

        final builder = DeckBuilder(
          tasks: [task1, task2, task3],
          workspace: DeckWorkspace(),
          store: DeckBuildStore(workspace: DeckWorkspace()),
        );

        await builder.dispose();

        expect(task1.wasDisposed, isTrue);
        expect(task2.wasDisposed, isTrue);
        expect(task3.wasDisposed, isTrue);
      });

      test('completes without error when no tasks', () async {
        final builder = DeckBuilder(
          tasks: [],
          workspace: DeckWorkspace(),
          store: DeckBuildStore(workspace: DeckWorkspace()),
        );

        await expectLater(builder.dispose(), completes);
      });

      test('disposes tasks in parallel (not sequentially)', () async {
        // Create tasks with different dispose delays
        final task1 = MockTask(disposeDelay: const Duration(milliseconds: 50));
        final task2 = MockTask(disposeDelay: const Duration(milliseconds: 50));
        final task3 = MockTask(disposeDelay: const Duration(milliseconds: 50));

        final builder = DeckBuilder(
          tasks: [task1, task2, task3],
          workspace: DeckWorkspace(),
          store: DeckBuildStore(workspace: DeckWorkspace()),
        );

        final stopwatch = Stopwatch()..start();
        await builder.dispose();
        stopwatch.stop();

        // If parallel: ~50ms total; if sequential: ~150ms total
        // Allow some margin for timing variations
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(120), // Well under 150ms means parallel
          reason: 'Tasks should dispose in parallel, not sequentially',
        );

        expect(task1.wasDisposed, isTrue);
        expect(task2.wasDisposed, isTrue);
        expect(task3.wasDisposed, isTrue);
      });

      test('can be called multiple times safely', () async {
        final task = MockTask();

        final builder = DeckBuilder(
          tasks: [task],
          workspace: DeckWorkspace(),
          store: DeckBuildStore(workspace: DeckWorkspace()),
        );

        // First dispose
        await expectLater(builder.dispose(), completes);
        expect(task.wasDisposed, isTrue);

        // Second dispose should also complete (task.dispose() will be called
        // again but our MockTask handles this gracefully)
        await expectLater(builder.dispose(), completes);
      });
    });

    group('constructor', () {
      test('accepts empty task list', () {
        expect(
          () => DeckBuilder(
            tasks: [],
            workspace: DeckWorkspace(),
            store: DeckBuildStore(workspace: DeckWorkspace()),
          ),
          returnsNormally,
        );
      });

      test('accepts custom concurrentSlides parameter', () {
        expect(
          () => DeckBuilder(
            tasks: [],
            workspace: DeckWorkspace(),
            store: DeckBuildStore(workspace: DeckWorkspace()),
            concurrentSlides: 8,
          ),
          returnsNormally,
        );
      });
    });
  });
}
