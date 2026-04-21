import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck/src/deck/loaders/file_deck_loader.dart';
import 'package:superdeck_builder/src/build/build_event.dart';
import 'package:superdeck_builder/src/build/deck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

const _eventTimeout = Duration(seconds: 5);

const _initialMarkdown = '''
---
title: Opening
---
# Opening

First slide content.

---
title: Second
---
# Second Slide

Second slide content.
''';

const _updatedMarkdown = '''
---
title: Opening
---
# Updated Opening

First slide content changed by the real watch test.

---
title: Second
---
# Second Slide

Second slide content.

---
title: Third
---
# Third Slide

Third slide content added by editing slides.md.
''';

void main() {
  group('CLI watch integration (real file edit)', () {
    late Directory tempDir;
    late DeckWorkspace workspace;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('watch_integration_');
      Directory(p.join(tempDir.path, '.superdeck')).createSync(recursive: true);
      workspace = DeckWorkspace(projectDir: tempDir.path);
      await workspace.slidesFile.writeAsString(_initialMarkdown);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test(
      'builder and loader propagate a real slides.md edit end-to-end',
      () async {
        final store = DeckBuildStore(workspace: workspace);
        final builder = StandardDeckBuildPipeline.create(
          workspace: workspace,
          store: store,
        );
        addTearDown(builder.dispose);

        final builderEvents = StreamIterator(builder.watchAndBuild());
        addTearDown(builderEvents.cancel);

        // Initial build from setUp's slides.md
        await _expectEvent<BuildStarted>(builderEvents, 'builder');
        final firstCompleted =
            await _expectEvent<BuildCompleted>(builderEvents, 'builder');
        expect(firstCompleted.slides, hasLength(2));

        final loader = FileDeckLoader(workspace: workspace);
        addTearDown(loader.dispose);

        final loaderEvents = StreamIterator(loader.load());
        addTearDown(loaderEvents.cancel);

        await _expectEvent<SlidesLoadingEvent>(loaderEvents, 'loader');
        final initialLoad =
            await _expectEvent<SlidesLoadedEvent>(loaderEvents, 'loader');
        expect(initialLoad.slides, hasLength(2));

        // Edit slides.md → builder rebuilds → loader re-emits.
        // Wait on builder events sequentially (StreamIterator can't be
        // pre-armed with concurrent moveNext calls).
        await workspace.slidesFile.writeAsString(_updatedMarkdown);

        await _expectEvent<BuildStarted>(builderEvents, 'builder');
        final secondCompleted =
            await _expectEvent<BuildCompleted>(builderEvents, 'builder');
        expect(secondCompleted.slides, hasLength(3));

        final updatedLoad = await _expectEvent<SlidesLoadedEvent>(
          loaderEvents,
          'loader',
          where: (e) => e.slides.length >= 3,
        );
        expect(
          _firstContent(updatedLoad.slides.first),
          contains('# Updated Opening'),
          reason: 'loader should reflect the edited slides.md',
        );
      },
    );
  });
}

Future<T> _expectEvent<T>(
  StreamIterator<Object?> events,
  String streamName, {
  bool Function(T)? where,
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < _eventTimeout) {
    final remaining = _eventTimeout - stopwatch.elapsed;
    final hasNext = await events.moveNext().timeout(
          remaining,
          onTimeout: () => false,
        );
    if (!hasNext) break;
    final event = events.current;
    if (event is T && (where == null || where(event))) {
      return event;
    }
  }
  fail('Timed out waiting for ${T.toString()} on $streamName');
}

String _firstContent(Slide slide) {
  final block = slide.sections.single.blocks.single;
  expect(block, isA<ContentBlock>());
  return (block as ContentBlock).content;
}
