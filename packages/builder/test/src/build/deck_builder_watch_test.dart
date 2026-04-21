import 'dart:async';
import 'dart:io';

import 'package:superdeck_builder/src/build/build_event.dart';
import 'package:superdeck_builder/src/build/deck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/testing_utils.dart';

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
      final builder = DeckBuilder(workspace: workspace, store: store);
      final iterator = StreamIterator(builder.watchAndBuild());
      addTearDown(iterator.cancel);

      await workspace.slidesFile.writeAsString('# First Slide');

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isA<BuildStarted>());
    });

    test('emits BuildCompleted after a successful build', () async {
      final builder = DeckBuilder(workspace: workspace, store: store);
      final iterator = StreamIterator(builder.watchAndBuild());
      addTearDown(iterator.cancel);

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

    test('emits BuildFailed when the build throws', () async {
      // `@column` is an unsupported directive — BlockParser throws
      // DeckFormatException, which DeckBuilder surfaces as BuildFailed.
      await workspace.slidesFile.writeAsString('# Slide\n\n@column\n');

      final builder = DeckBuilder(workspace: workspace, store: store);
      final iterator = StreamIterator(builder.watchAndBuild());
      addTearDown(iterator.cancel);

      await _nextEvent(iterator);
      final event = await _nextEvent(iterator);

      expect(
        event,
        isA<BuildFailed>().having(
          (event) => event.stackTrace,
          'stackTrace',
          isNotNull,
        ),
      );
    });

    test('emits started and completed for a rebuild cycle', () async {
      final builder = DeckBuilder(workspace: workspace, store: store);
      final iterator = StreamIterator(builder.watchAndBuild());
      addTearDown(iterator.cancel);

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
