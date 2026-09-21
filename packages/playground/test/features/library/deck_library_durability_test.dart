@TestOn('mac-os')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:playground/core/data/data_sources/deck_library_asset_store.dart';
import 'package:playground/core/data/data_sources/memory_asset_cache_store.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/data/data_sources/security_scoped_file_access.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/core/domain/stores/deck_document_store.dart';
import 'package:playground/features/library/data/mac_os_deck_library.dart';
import 'package:playground/features/library/domain/deck_library_controller.dart';
import 'package:playground/features/library/domain/saved_deck.dart';
import 'package:superdeck/superdeck.dart';

import '../../helpers/fake_security_scoped_file_access.dart';

/// Deterministic 1x1 PNGs, so a resolution can be attributed to the deck it
/// came from rather than to the key alone.
final _pngA = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);
final _pngB = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
);

const _theme = SavedDeckTheme(
  id: 'technical-paper',
  version: 1,
  density: 'balanced',
);

/// The objects one application run owns.
///
/// Building a second one over the same folder is what a relaunch looks like:
/// nothing carries over except what is on disk.
final class _Run {
  final MacOsDeckLibrary library;
  final MemoryAssetCacheStore memory;
  late final DeckLibraryAssetStore assets;
  late final DeckDocumentStore document;
  late final MemoryDeckLoader loader;
  late final DeckController deckController;
  late final DeckCustomizationStore customization;
  late final DeckLibraryController controller;

  _Run(FakeSecurityScopedFileAccess access)
    : library = MacOsDeckLibrary(fileAccess: access),
      memory = MemoryAssetCacheStore() {
    assets = DeckLibraryAssetStore(library: library, fallback: memory);
    document = DeckDocumentStore(markdown: '');
    loader = MemoryDeckLoader();
    deckController = DeckController(
      deckLoader: loader,
      options: DeckOptions(),
      assetCacheStore: assets,
    );
    customization = DeckCustomizationStore(
      deckController,
      background: Colors.black,
      foreground: Colors.white,
    );
    controller = DeckLibraryController(
      library: library,
      documentStore: document,
      deckLoader: loader,
      customizationStore: customization,
      assetStore: assets,
    );
  }

  Future<void> close() async {
    controller.dispose();
    customization.dispose();
    deckController.dispose();
    await loader.dispose();
    document.dispose();
    library.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late Directory temp;
  late FakeSecurityScopedFileAccess access;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('deck_library_durability');
    PathProviderPlatform.instance = FakePathProvider(temp.path);
    access = FakeSecurityScopedFileAccess()
      ..pickedDirectory = SecurityScopedDirectoryReference(
        path: temp.path,
        bookmark: 'directory-bookmark',
      );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('a saved deck reopens with its artwork and theme in a new run', () async {
    final first = _Run(access);
    first.document.replaceMarkdown('# Generated\n\n![Hero](hero.png)\n');
    await first.memory.write('hero.png', _pngA);

    final saved = await first.controller.save(
      name: 'Urban gardens',
      images: [
        GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _pngA),
      ],
      theme: _theme,
    );
    expect(saved, isTrue);
    final defaultHeadline = first.customization.level(TextLevel.h1).family;
    await first.close();

    // A second run: new library, new caches, nothing in memory.
    final second = _Run(access);
    addTearDown(second.close);
    await second.controller.refresh();

    expect(second.controller.decks.single.name, 'Urban gardens');
    expect(await second.memory.resolve('hero.png'), isNull);

    final opened = await second.controller.open(second.controller.decks.single);

    expect(opened, isTrue);
    expect(second.controller.errorMessage, isNull);
    expect(second.document.markdown, contains('![Hero](hero.png)'));
    final resolved = await second.assets.resolve('hero.png');
    expect(resolved, isNotNull, reason: 'the reopened deck lost its artwork');
    expect(resolved!.scheme, 'file');
    expect(await File.fromUri(resolved).readAsBytes(), _pngA);
    // The theme is restored from the manifest's selection, resolved through
    // the catalog, rather than left at the session default.
    final expected = PresentationThemeCatalog.withDefaults().resolve(
      id: _theme.id,
      version: _theme.version,
      density: _theme.density,
      typographyCatalog: PresentationTypographyCatalog.withDefaults(),
    );
    expect(second.customization.level(TextLevel.h1).family, expected.headlineFamily);
    expect(expected.headlineFamily, isNot(defaultHeadline));
  });

  test('each saved deck keeps its own artwork under the same key', () async {
    final run = _Run(access);
    addTearDown(run.close);

    run.document.replaceMarkdown('# A\n\n![Hero](hero.png)\n');
    await run.controller.save(
      name: 'Deck A',
      images: [
        GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _pngA),
      ],
      theme: _theme,
    );
    // A new generation owns the runtime again, then saves its own artwork.
    run.controller.releaseOpenDeck();
    run.document.replaceMarkdown('# B\n\n![Hero](hero.png)\n');
    await run.controller.save(
      name: 'Deck B',
      images: [
        GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _pngB),
      ],
      theme: _theme,
    );

    await run.controller.refresh();
    final decks = {for (final ref in run.controller.decks) ref.name: ref};

    await run.controller.open(decks['Deck A']!);
    final fromA = await run.assets.resolve('hero.png');
    expect(await File.fromUri(fromA!).readAsBytes(), _pngA);
    expect(run.document.markdown, contains('# A'));

    await run.controller.open(decks['Deck B']!);
    final fromB = await run.assets.resolve('hero.png');
    expect(await File.fromUri(fromB!).readAsBytes(), _pngB);
    expect(run.document.markdown, contains('# B'));

    await run.controller.open(decks['Deck A']!);
    expect(
      await File.fromUri((await run.assets.resolve('hero.png'))!).readAsBytes(),
      _pngA,
      reason: 'A to B to A must return A its own artwork',
    );
  });

  test('a released deck stops answering for artwork', () async {
    final run = _Run(access);
    addTearDown(run.close);
    run.document.replaceMarkdown('# A\n\n![Hero](hero.png)\n');
    await run.controller.save(
      name: 'Deck A',
      images: [
        GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _pngA),
      ],
    );

    // The next generation's artwork lives in memory until it is saved.
    run.controller.releaseOpenDeck();
    await run.memory.write('hero.png', _pngB);
    final resolved = await run.assets.resolve('hero.png');

    expect(resolved?.scheme, 'data');
  });
}
