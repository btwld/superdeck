import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/deck_library_asset_store.dart';
import 'package:playground/core/data/data_sources/memory_asset_cache_store.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/core/domain/stores/deck_document_store.dart';
import 'package:playground/features/library/domain/deck_library_controller.dart';
import 'package:playground/features/library/domain/saved_deck.dart';
import 'package:superdeck/superdeck.dart';

import '../../../helpers/fake_deck_library.dart';

const _theme = SavedDeckTheme(
  id: 'technical-paper',
  version: 1,
  density: 'balanced',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  ({
    DeckLibraryController controller,
    FakeDeckLibrary library,
    DeckDocumentStore document,
    MemoryDeckLoader loader,
    DeckCustomizationStore customization,
    DeckLibraryAssetStore assets,
    MemoryAssetCacheStore memory,
  })
  newScope() {
    final library = FakeDeckLibrary();
    final memory = MemoryAssetCacheStore();
    final assets = DeckLibraryAssetStore(library: library, fallback: memory);
    final document = DeckDocumentStore(markdown: '# Generated\n');
    final loader = MemoryDeckLoader();
    final deckController = DeckController(
      deckLoader: loader,
      options: DeckOptions(),
      assetCacheStore: assets,
    );
    final customization = DeckCustomizationStore(
      deckController,
      background: Colors.black,
      foreground: Colors.white,
    );
    final controller = DeckLibraryController(
      library: library,
      documentStore: document,
      deckLoader: loader,
      customizationStore: customization,
      assetStore: assets,
    );
    addTearDown(() {
      controller.dispose();
      customization.dispose();
      deckController.dispose();
      loader.dispose();
      document.dispose();
    });

    return (
      controller: controller,
      library: library,
      document: document,
      loader: loader,
      customization: customization,
      assets: assets,
      memory: memory,
    );
  }

  group('save', () {
    test('writes the current document and keeps its artwork reachable', () async {
      final scope = newScope();
      await scope.memory.write('hero.png', [1, 2, 3]);

      final saved = await scope.controller.save(
        name: 'My talk',
        images: [
          GeneratedImageAsset.success(assetKey: 'hero.png', bytes: [1, 2, 3]),
        ],
        theme: _theme,
      );

      expect(saved, isTrue);
      expect(scope.library.markdown['/decks/My talk.md'], '# Generated\n');
      expect(scope.controller.lastSave?.isComplete, isTrue);
      expect(scope.controller.openDeck?.name, 'My talk');
      expect(scope.controller.decks.single.name, 'My talk');
      // The saved copy now answers for the artwork, not the run's memory.
      expect(await scope.assets.resolve('hero.png'), isNotNull);
    });

    test('names artwork that had no bytes', () async {
      final scope = newScope();

      await scope.controller.save(
        name: 'My talk',
        images: const [
          GeneratedImageAsset.failure(assetKey: 'hero.png', error: 'timeout'),
        ],
      );

      expect(scope.controller.lastSave?.isComplete, isFalse);
      expect(scope.controller.lastSave?.missingAssetKeys, ['hero.png']);
    });

    test('a failed save reports why and opens nothing', () async {
      final scope = newScope()..library.saveError = Exception('disk full');

      final saved = await scope.controller.save(name: 'My talk');

      expect(saved, isFalse);
      expect(scope.controller.errorMessage, contains('disk full'));
      expect(scope.controller.openDeck, isNull);
      expect(scope.controller.lastSave, isNull);
    });

    test('saving twice keeps both decks', () async {
      final scope = newScope();

      await scope.controller.save(name: 'My talk');
      await scope.controller.save(name: 'My talk');

      expect(scope.library.saveCount, 2);
      expect(
        scope.controller.decks.map((ref) => ref.name),
        containsAll(<String>['My talk', 'My talk 2']),
      );
    });
  });

  group('open', () {
    test('publishes a saved deck and its theme', () async {
      final scope = newScope();
      await scope.controller.save(name: 'My talk', theme: _theme);
      scope.document.replaceMarkdown('# Something else\n');
      scope.controller.releaseOpenDeck();
      final ref = scope.controller.decks.single;

      final opened = await scope.controller.open(ref);

      expect(opened, isTrue);
      expect(scope.document.markdown, '# Generated\n');
      expect(scope.controller.openDeck, ref);
      expect(scope.controller.errorMessage, isNull);
      expect(scope.customization.level(TextLevel.h1).family, isNotEmpty);
    });

    test('a theme the catalog no longer has is reported, not guessed', () async {
      final scope = newScope();
      await scope.controller.save(
        name: 'My talk',
        theme: const SavedDeckTheme(
          id: 'technical-paper',
          version: 99,
          density: 'balanced',
        ),
      );
      final familyBefore = scope.customization.level(TextLevel.h1).family;

      await scope.controller.open(scope.controller.decks.single);

      expect(scope.controller.errorMessage, contains('no longer has'));
      expect(scope.customization.level(TextLevel.h1).family, familyBefore);
    });

    test('a deck that cannot be read reports and keeps the current one', () async {
      final scope = newScope()..library.openError = Exception('gone');
      await scope.controller.save(name: 'My talk');
      final ref = scope.controller.decks.single;
      scope.controller.releaseOpenDeck();

      final opened = await scope.controller.open(ref);

      expect(opened, isFalse);
      expect(scope.controller.errorMessage, contains('gone'));
      expect(scope.controller.openDeck, isNull);
    });

    test('releasing the open deck returns artwork to the run', () async {
      final scope = newScope();
      await scope.memory.write('hero.png', [9]);
      await scope.controller.save(
        name: 'My talk',
        images: [
          GeneratedImageAsset.success(assetKey: 'hero.png', bytes: [1]),
        ],
      );

      scope.controller.releaseOpenDeck();

      expect(scope.controller.openDeck, isNull);
      expect(await scope.assets.resolve('hero.png'), isNotNull);
    });
  });

  test('refresh reports a library it cannot read', () async {
    final scope = newScope()..library.listError = Exception('no folder');

    await scope.controller.refresh();

    expect(scope.controller.decks, isEmpty);
    expect(scope.controller.errorMessage, contains('no folder'));
  });
}
