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

    test('default build plugin transform returns the original block', () async {
      const plugin = _IdentityPlugin('test.identity');
      final block = ContentBlock('Original content');
      final context = DeckBuildContext(
        workspace: workspace,
        slideKey: 'identity-test',
        slideIndex: 0,
        sectionIndex: 0,
        blockIndex: 0,
      );

      final transformed = await plugin.transformContentBlock(block, context);

      expect(identical(transformed, block), isTrue);
    });

    test('rejects build plugins with empty ids', () {
      expect(
        () => DeckBuilder(
          workspace: workspace,
          store: store,
          plugins: const [_IdentityPlugin(' ')],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate build plugin ids', () {
      expect(
        () => DeckBuilder(
          workspace: workspace,
          store: store,
          plugins: const [
            _IdentityPlugin('test.duplicate'),
            _IdentityPlugin('test.duplicate'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('runs build plugins against content blocks before saving', () async {
      const markdown = '# First Slide\n\nOriginal content';
      final plugin = _TransformPlugin(
        id: 'test.content-transform',
        transform: (block, context) {
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

    test('rejects Windows absolute plugin output paths', () {
      final context = DeckBuildContext(
        workspace: workspace,
        slideKey: 'path-guard-test',
        slideIndex: 0,
        sectionIndex: 0,
        blockIndex: 0,
      );

      for (final relativePath in ['C:/x', r'C:\x', r'\\server\share']) {
        expect(() => context.outputFile(relativePath), throwsArgumentError);
        expect(() => context.assetPath(relativePath), throwsArgumentError);
      }
    });

    test('serializes overlapping builds for a shared builder', () async {
      const markdown = '# First Slide\n\nOriginal content';
      final firstTransformStarted = Completer<void>();
      final releaseFirstTransform = Completer<void>();
      var activeTransforms = 0;
      var maxActiveTransforms = 0;
      final plugin = _TransformPlugin(
        id: 'test.serialized-transform',
        transform: (block, _) async {
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

    test('runs build lifecycle hooks around content transforms', () async {
      const markdown = '# First Slide\n\nOriginal content';
      final events = <String>[];
      final builder = DeckBuilder(
        workspace: workspace,
        store: store,
        plugins: [
          _LifecyclePlugin(
            id: 'test.lifecycle',
            onBegin: (_) {
              events.add('begin');
            },
            onTransform: (block, _) {
              events.add('transform');
              return block;
            },
            onFinish: (_) {
              events.add('finish');
            },
          ),
        ],
      );

      await workspace.slidesFile.writeAsString(markdown);
      await builder.build();

      expect(events, ['begin', 'transform', 'finish']);
    });

    test('does not run finishBuild after transform failure', () async {
      const markdown = '# First Slide\n\nOriginal content';
      final events = <String>[];
      final builder = DeckBuilder(
        workspace: workspace,
        store: store,
        plugins: [
          _LifecyclePlugin(
            id: 'test.lifecycle-failure',
            onBegin: (_) {
              events.add('begin');
            },
            onTransform: (_, _) {
              events.add('transform');
              throw StateError('transform failed');
            },
            onFinish: (_) {
              events.add('finish');
            },
          ),
        ],
      );

      await workspace.slidesFile.writeAsString(markdown);

      await expectLater(builder.build(), throwsA(isA<Exception>()));
      expect(events, ['begin', 'transform']);
    });

    test('does not run finishBuild when saving references fails', () async {
      const markdown = '# First Slide\n\nOriginal content';
      final events = <String>[];
      final failingStore = _FailingReferenceStore(
        workspace: workspace,
        onSaveReferences: () {
          events.add('save-references');
          throw StateError('save references failed');
        },
      );
      final builder = DeckBuilder(
        workspace: workspace,
        store: failingStore,
        plugins: [
          _LifecyclePlugin(
            id: 'test.lifecycle-save-failure',
            onTransform: (block, _) {
              events.add('transform');
              return block;
            },
            onFinish: (_) {
              events.add('finish');
            },
          ),
        ],
      );

      await workspace.slidesFile.writeAsString(markdown);

      await expectLater(builder.build(), throwsA(isA<StateError>()));
      expect(events, ['transform', 'save-references']);
    });

    test(
      'dispose waits for active plugin transforms before disposing',
      () async {
        const markdown = '# First Slide\n\nOriginal content';
        final transformStarted = Completer<void>();
        final releaseTransform = Completer<void>();
        final events = <String>[];
        var disposeCompleted = false;
        final builder = DeckBuilder(
          workspace: workspace,
          store: store,
          plugins: [
            _LifecyclePlugin(
              id: 'test.dispose-waits',
              onTransform: (block, _) async {
                events.add('transform-start');
                transformStarted.complete();
                await releaseTransform.future;
                events.add('transform-end');

                return block;
              },
              onDispose: () {
                events.add('dispose');
              },
            ),
          ],
        );

        await workspace.slidesFile.writeAsString(markdown);
        final buildFuture = builder.build();
        await transformStarted.future;

        final disposeFuture = builder.dispose().whenComplete(() {
          disposeCompleted = true;
        });
        await Future<void>.delayed(Duration.zero);

        expect(disposeCompleted, isFalse);
        expect(events, ['transform-start']);

        releaseTransform.complete();
        await buildFuture;
        await disposeFuture;

        expect(disposeCompleted, isTrue);
        expect(events, ['transform-start', 'transform-end', 'dispose']);
      },
    );

    test('build after dispose fails with StateError', () async {
      final builder = DeckBuilder(workspace: workspace, store: store);

      await builder.dispose();

      await expectLater(builder.build(), throwsA(isA<StateError>()));
    });

    test('disposes every build plugin even when one dispose fails', () async {
      var firstDisposed = false;
      var secondDisposed = false;
      final builder = DeckBuilder(
        workspace: workspace,
        store: store,
        plugins: [
          _DisposePlugin(
            id: 'test.dispose-fails',
            onDispose: () {
              firstDisposed = true;
              throw StateError('dispose failed');
            },
          ),
          _DisposePlugin(
            id: 'test.dispose-runs',
            onDispose: () {
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
      final plugin = _TransformPlugin(
        id: 'test.watch-transform',
        transform: (block, _) {
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

      final rebuildStarted = _expectEvent<BuildStarted>(events, 'builder');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await workspace.slidesFile.writeAsString(updatedMarkdown);

      await rebuildStarted;
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

    test('wraps generic plugin transform failures with context', () async {
      const markdown = '# First Slide\n\nOriginal content';
      final builder = DeckBuilder(
        workspace: workspace,
        store: store,
        plugins: [
          _TransformPlugin(
            id: 'test.fail-context',
            transform: (_, _) => throw StateError('transform failed'),
          ),
        ],
      );

      await workspace.slidesFile.writeAsString(markdown);

      await expectLater(
        () => builder.build(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('test.fail-context'),
              contains('section 0'),
              contains('block 0'),
              contains('transform failed'),
            ),
          ),
        ),
      );
    });

    test('preserves DeckFormatException thrown by plugins', () async {
      const markdown = '# First Slide\n\nOriginal content';
      final builder = DeckBuilder(
        workspace: workspace,
        store: store,
        plugins: [
          _TransformPlugin(
            id: 'test.format-failure',
            transform: (block, _) {
              throw DeckFormatException('Invalid plugin content.', block, 0);
            },
          ),
        ],
      );

      await workspace.slidesFile.writeAsString(markdown);

      await expectLater(
        () => builder.build(),
        throwsA(isA<DeckFormatException>()),
      );
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

final class _IdentityPlugin extends DeckBuildPlugin {
  @override
  final String id;

  const _IdentityPlugin(this.id);
}

final class _TransformPlugin extends DeckBuildPlugin {
  @override
  final String id;
  final FutureOr<ContentBlock> Function(
    ContentBlock block,
    DeckBuildContext context,
  )
  transform;

  const _TransformPlugin({required this.id, required this.transform});

  @override
  FutureOr<ContentBlock> transformContentBlock(
    ContentBlock block,
    DeckBuildContext context,
  ) {
    return transform(block, context);
  }
}

final class _DisposePlugin extends DeckBuildPlugin {
  @override
  final String id;
  final void Function() onDispose;

  const _DisposePlugin({required this.id, required this.onDispose});

  @override
  void dispose() {
    onDispose();
  }
}

final class _LifecyclePlugin extends DeckBuildPlugin {
  @override
  final String id;
  final FutureOr<void> Function(DeckWorkspace workspace)? onBegin;
  final FutureOr<ContentBlock> Function(
    ContentBlock block,
    DeckBuildContext context,
  )?
  onTransform;
  final FutureOr<void> Function(DeckWorkspace workspace)? onFinish;
  final FutureOr<void> Function()? onDispose;

  const _LifecyclePlugin({
    required this.id,
    this.onBegin,
    this.onTransform,
    this.onFinish,
    this.onDispose,
  });

  @override
  FutureOr<void> beginBuild(DeckWorkspace workspace) {
    return onBegin?.call(workspace);
  }

  @override
  FutureOr<ContentBlock> transformContentBlock(
    ContentBlock block,
    DeckBuildContext context,
  ) {
    return onTransform?.call(block, context) ?? block;
  }

  @override
  FutureOr<void> finishBuild(DeckWorkspace workspace) {
    return onFinish?.call(workspace);
  }

  @override
  FutureOr<void> dispose() {
    return onDispose?.call();
  }
}

final class _FailingReferenceStore extends DeckBuildStore {
  final FutureOr<void> Function() onSaveReferences;

  _FailingReferenceStore({
    required super.workspace,
    required this.onSaveReferences,
  });

  @override
  Future<void> saveReferences(List<Slide> slides) async {
    await onSaveReferences();
  }
}
