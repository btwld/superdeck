import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:superdeck_builder/src/build/build_event.dart';
import 'package:superdeck_builder/src/build/deck_build_plugin.dart';
import 'package:superdeck_builder/src/build/deck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/testing_utils.dart';

const _eventTimeout = Duration(seconds: 5);

void main() {
  group('DeckBuilder', () {
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
      final builder = DeckBuilder(workspace: workspace, store: store);

      await workspace.slidesFile.writeAsString(markdown);
      await builder.build();

      final deckJson =
          jsonDecode(await workspace.deckJson.readAsString()) as List<dynamic>;

      expect(deckJson, hasLength(2));
      expect(deckJson.first, containsPair('key', isA<String>()));
    });

    test('full deck json also writes a raw slide array', () async {
      const markdown = '# First Slide\n\n---\n\n# Second Slide';
      final builder = DeckBuilder(workspace: workspace, store: store);

      await workspace.slidesFile.writeAsString(markdown);
      await builder.build();

      final fullDeckJson =
          jsonDecode(await workspace.deckFullJson.readAsString())
              as List<dynamic>;

      expect(fullDeckJson, hasLength(2));
      expect(fullDeckJson.first, containsPair('key', isA<String>()));
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
        final builder = DeckBuilder(workspace: workspace, store: store);

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

    test('runs build plugins against content blocks before saving', () async {
      const markdown = '# First Slide\n\nOriginal content';
      final plugin = DeckBuildPlugin(
        id: 'test.content-transform',
        transformContentBlock: (block, context) {
          expect(context.workspace, workspace);
          expect(context.slideKey, isNotEmpty);
          expect(context.slideIndex, 0);
          expect(context.sectionIndex, 0);
          expect(context.blockIndex, 0);
          expect(
            context.outputFile('plugin/image.png').path,
            endsWith('.superdeck/plugin/image.png'),
          );
          expect(
            context.assetPath('plugin/image.png'),
            '.superdeck/plugin/image.png',
          );

          return block.copyWith(
            content: '${block.content}\n\nTransformed by plugin.',
          );
        },
      );
      final builder = DeckBuilder(
        workspace: workspace,
        store: store,
        plugins: [plugin],
      );

      await workspace.slidesFile.writeAsString(markdown);
      final slides = await builder.build();
      final block = slides.single.sections.single.blocks.single as ContentBlock;

      expect(block.content, contains('Transformed by plugin.'));

      final deckJson =
          jsonDecode(await workspace.deckJson.readAsString()) as List<dynamic>;
      final savedSlide = deckJson.single as Map<String, dynamic>;
      final savedSection =
          (savedSlide['sections'] as List<dynamic>).single
              as Map<String, dynamic>;
      final savedBlock =
          (savedSection['blocks'] as List<dynamic>).single
              as Map<String, dynamic>;

      expect(savedBlock['content'], contains('Transformed by plugin.'));
    });

    test('serializes overlapping builds for a shared builder', () async {
      const markdown = '# First Slide\n\nOriginal content';
      final firstTransformStarted = Completer<void>();
      final releaseFirstTransform = Completer<void>();
      var activeTransforms = 0;
      var maxActiveTransforms = 0;
      final plugin = DeckBuildPlugin(
        id: 'test.serialized-transform',
        transformContentBlock: (block, _) async {
          activeTransforms++;
          if (activeTransforms > maxActiveTransforms) {
            maxActiveTransforms = activeTransforms;
          }
          if (!firstTransformStarted.isCompleted) {
            firstTransformStarted.complete();
          }
          await releaseFirstTransform.future;
          activeTransforms--;

          return block;
        },
      );
      final builder = DeckBuilder(
        workspace: workspace,
        store: store,
        plugins: [plugin],
      );

      await workspace.slidesFile.writeAsString(markdown);
      final firstBuild = builder.build();
      await firstTransformStarted.future;
      final secondBuild = builder.build();
      await Future<void>.delayed(Duration.zero);

      expect(maxActiveTransforms, 1);

      releaseFirstTransform.complete();
      await firstBuild;
      await secondBuild;

      expect(maxActiveTransforms, 1);
    });

    test('disposes every build plugin even when one dispose fails', () async {
      var firstDisposed = false;
      var secondDisposed = false;
      final builder = DeckBuilder(
        workspace: workspace,
        store: store,
        plugins: [
          DeckBuildPlugin(
            id: 'test.dispose-fails',
            transformContentBlock: (block, _) => block,
            dispose: () {
              firstDisposed = true;
              throw StateError('dispose failed');
            },
          ),
          DeckBuildPlugin(
            id: 'test.dispose-runs',
            transformContentBlock: (block, _) => block,
            dispose: () {
              secondDisposed = true;
            },
          ),
        ],
      );

      await builder.dispose();

      expect(firstDisposed, isTrue);
      expect(secondDisposed, isTrue);
    });

    test('watchAndBuild applies build plugins after slides.md edits', () async {
      const initialMarkdown = '# First Slide\n\nOriginal content';
      const updatedMarkdown = '# First Slide\n\nUpdated content';
      final transformedContents = <String>[];
      final plugin = DeckBuildPlugin(
        id: 'test.watch-transform',
        transformContentBlock: (block, _) {
          transformedContents.add(block.content);

          return block.copyWith(
            content:
                '${block.content}\n\n'
                'Transformed cycle ${transformedContents.length}.',
          );
        },
      );
      final builder = DeckBuilder(
        workspace: workspace,
        store: store,
        plugins: [plugin],
      );
      addTearDown(builder.dispose);

      await workspace.slidesFile.writeAsString(initialMarkdown);
      final events = StreamIterator(builder.watchAndBuild());
      addTearDown(events.cancel);

      await _expectEvent<BuildStarted>(events, 'builder');
      final firstCompleted = await _expectEvent<BuildCompleted>(
        events,
        'builder',
      );
      expect(
        _singleContentBlock(firstCompleted).content,
        contains('Transformed cycle 1.'),
      );

      await workspace.slidesFile.writeAsString(updatedMarkdown);

      await _expectEvent<BuildStarted>(events, 'builder');
      final secondCompleted = await _expectEvent<BuildCompleted>(
        events,
        'builder',
      );
      expect(
        _singleContentBlock(secondCompleted).content,
        contains('Updated content\n\nTransformed cycle 2.'),
      );
      expect(transformedContents, [
        '# First Slide\n\nOriginal content',
        '# First Slide\n\nUpdated content',
      ]);
    });
  });
}

Future<T> _expectEvent<T>(
  StreamIterator<Object?> events,
  String streamName,
) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < _eventTimeout) {
    final remaining = _eventTimeout - stopwatch.elapsed;
    final hasNext = await events.moveNext().timeout(
      remaining,
      onTimeout: () => false,
    );
    if (!hasNext) break;
    final event = events.current;
    if (event is T) return event;
  }
  fail('Timed out waiting for ${T.toString()} on $streamName');
}

ContentBlock _singleContentBlock(BuildCompleted completed) {
  final block = completed.slides.single.sections.single.blocks.single;
  expect(block, isA<ContentBlock>());

  return block as ContentBlock;
}
