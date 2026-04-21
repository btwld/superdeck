import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:superdeck_builder/src/build/deck_builder.dart';
import 'package:superdeck_builder/src/build/task_exception.dart';
import 'package:superdeck_builder/src/tasks/slide_context.dart';
import 'package:superdeck_builder/src/tasks/task.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/testing_utils.dart';

final class MockTask extends Task {
  bool wasDisposed = false;
  final Duration? disposeDelay;
  final bool throwOnDispose;

  MockTask({this.disposeDelay, this.throwOnDispose = false})
    : super('mock_task');

  @override
  FutureOr<void> run(SlideContext context) {}

  @override
  FutureOr<void> dispose() async {
    if (disposeDelay != null) {
      await Future<void>.delayed(disposeDelay!);
    }
    if (throwOnDispose) {
      throw StateError('Simulated dispose error');
    }
    wasDisposed = true;
  }
}

final class RecordingTask extends Task {
  final String marker;
  final List<String> runLog;
  final Duration delay;
  final bool writeTitle;

  RecordingTask({
    required this.marker,
    required this.runLog,
    this.delay = Duration.zero,
    this.writeTitle = false,
  }) : super(marker);

  @override
  Future<void> run(SlideContext context) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    runLog.add('${context.slideIndex}:$marker');

    final updatedFrontmatter = <String, Object?>{
      ...context.slide.frontmatter,
      if (writeTitle) 'title': 'slide-${context.slideIndex}',
    };

    context.updateSlide(
      context.slide.copyWith(
        content: '${context.slide.content}\n<!-- $marker -->',
        frontmatter: updatedFrontmatter,
      ),
    );
  }
}

final class ThrowingTask extends Task {
  ThrowingTask() : super('throwing_task');

  @override
  Future<void> run(SlideContext context) async {
    throw Exception('boom');
  }
}

void main() {
  group('DeckBuilder', () {
    group('build', () {
      late Directory tempDir;
      late DeckWorkspace workspace;
      late DeckBuildStore store;

      setUp(() {
        tempDir = createTempDir(prefix: 'deck_builder_test');
        workspace = createTestWorkspace(tempDir);
        store = DeckBuildStore(workspace: workspace);
      });

      test('deck json writes a raw slide array', () async {
        const markdown = '# First Slide\n\n---\n\n# Second Slide';
        final builder = DeckBuilder(
          tasks: const [],
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
          tasks: const [],
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

      test('wraps task failures in TaskException', () async {
        const markdown = '# First Slide';
        final builder = DeckBuilder(
          tasks: [ThrowingTask()],
          workspace: workspace,
          store: store,
        );
        addTearDown(builder.dispose);

        await workspace.slidesFile.writeAsString(markdown);

        await expectLater(
          builder.build(),
          throwsA(
            isA<TaskException>()
                .having((error) => error.taskName, 'taskName', 'throwing_task')
                .having((error) => error.slideIndex, 'slideIndex', 0),
          ),
        );
      });

      test('runs tasks in declared order for each slide', () async {
        const markdown = '# First Slide';
        final runLog = <String>[];
        final builder = DeckBuilder(
          tasks: [
            RecordingTask(marker: 'first', runLog: runLog),
            RecordingTask(marker: 'second', runLog: runLog),
          ],
          workspace: workspace,
          store: store,
        );
        addTearDown(builder.dispose);

        await workspace.slidesFile.writeAsString(markdown);
        await builder.build();

        expect(runLog, equals(['0:first', '0:second']));
      });

      test('preserves slide order after concurrent processing', () async {
        const markdown = '''
---
title: Raw 0
---
# Slide 0

---
title: Raw 1
---
# Slide 1

---
title: Raw 2
---
# Slide 2

---
title: Raw 3
---
# Slide 3
''';
        final runLog = <String>[];
        final builder = DeckBuilder(
          tasks: [
            RecordingTask(
              marker: 'ordered',
              runLog: runLog,
              delay: const Duration(milliseconds: 10),
              writeTitle: true,
            ),
          ],
          workspace: workspace,
          store: store,
          concurrentSlides: 2,
        );
        addTearDown(builder.dispose);

        await workspace.slidesFile.writeAsString(markdown);
        final slides = await builder.build();

        expect(
          slides.map((slide) => slide.options?.title).toList(),
          equals(['slide-0', 'slide-1', 'slide-2', 'slide-3']),
        );
      });

      test('processes all slides when count exceeds concurrency', () async {
        const markdown = '''
---
title: Raw 0
---
# Slide 0

---
title: Raw 1
---
# Slide 1

---
title: Raw 2
---
# Slide 2

---
title: Raw 3
---
# Slide 3

---
title: Raw 4
---
# Slide 4
''';
        final runLog = <String>[];
        final builder = DeckBuilder(
          tasks: [
            RecordingTask(marker: 'visit', runLog: runLog, writeTitle: true),
          ],
          workspace: workspace,
          store: store,
          concurrentSlides: 2,
        );
        addTearDown(builder.dispose);

        await workspace.slidesFile.writeAsString(markdown);
        final slides = await builder.build();

        expect(slides, hasLength(5));
        expect(
          runLog,
          equals(['0:visit', '1:visit', '2:visit', '3:visit', '4:visit']),
        );
      });

      test(
        'build output includes parsed options, sections, and comments',
        () async {
          const markdown = '''
---
title: Agenda
style: keynote
---
# Agenda

@block
Discuss release plan.

<!-- Speaker note -->
''';
          final builder = DeckBuilder(
            tasks: const [],
            workspace: workspace,
            store: store,
          );
          addTearDown(builder.dispose);

          await workspace.slidesFile.writeAsString(markdown);
          final slides = await builder.build();
          final slide = slides.single;

          expect(slide.options?.title, 'Agenda');
          expect(slide.options?.style, 'keynote');
          expect(slide.sections, isNotEmpty);
          expect(slide.sections.first.blocks, isNotEmpty);
          expect(slide.comments, equals(['Speaker note']));
        },
      );
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
          tasks: const [],
          workspace: DeckWorkspace(),
          store: DeckBuildStore(workspace: DeckWorkspace()),
        );

        await expectLater(builder.dispose(), completes);
      });

      test('disposes tasks in parallel (not sequentially)', () async {
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

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(120),
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

        await expectLater(builder.dispose(), completes);
        expect(task.wasDisposed, isTrue);
        await expectLater(builder.dispose(), completes);
      });
    });
  });
}
