import 'dart:convert';
import 'dart:io';

import 'package:superdeck_builder/src/build/deck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/testing_utils.dart';

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
  });
}
