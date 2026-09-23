import 'dart:async';

import 'package:flutter/material.dart' show Color, Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/deck_file.dart';
import 'package:playground/core/data/data_sources/deck_library_asset_store.dart';
import 'package:playground/core/data/data_sources/memory_asset_cache_store.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/core/result.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/core/domain/stores/deck_document_store.dart';
import 'package:playground/features/ai/generation/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/generation/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/generation/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/generation/domain/generated_deck_result_applier.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_generation_controller.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_page.dart';
import 'package:playground/features/library/domain/deck_library_controller.dart';
import 'package:playground/features/library/domain/saved_deck.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart' hide Ok;

import '../../../helpers/fake_deck_library.dart';

const _savedMarkdown = '''
---
title: Saved A
---

Saved deck A stays on screen.
''';

const _otherMarkdown = '''
---
title: Saved B
---

Saved deck B stays on screen.
''';

const _boldTheme = SavedDeckTheme(
  id: 'bold-product',
  version: 1,
  density: 'balanced',
);

const _paperTheme = SavedDeckTheme(
  id: 'technical-paper',
  version: 1,
  density: 'balanced',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('generated result application', () {
    test('a rejected application leaves the saved deck intact', () async {
      final scope = await _showingSavedDeck();

      final application = await applyGeneratedDeckResult(
        applier: scope.applier,
        result: _generatedResult(),
        isValid: () => false,
        releaseSavedDeck: scope.libraryController.releaseOpenDeck,
      );

      expect(application.published, isFalse);
      _expectSavedDeckIntact(scope);
    });

    test('an abandoned application leaves the saved deck intact', () async {
      final scope = await _showingSavedDeck();
      var accepted = true;

      final application = await applyGeneratedDeckResult(
        applier: scope.applier,
        result: _generatedResult(),
        isValid: () {
          final current = accepted;
          accepted = false;
          return current;
        },
        releaseSavedDeck: scope.libraryController.releaseOpenDeck,
      );

      expect(application.published, isFalse);
      _expectSavedDeckIntact(scope);
    });

    test('a thrown application leaves the saved deck intact', () async {
      final scope = await _showingSavedDeck(fallback: _ThrowingAssetCache());

      await expectLater(
        applyGeneratedDeckResult(
          applier: scope.applier,
          result: _generatedResult(),
          isValid: () => true,
          releaseSavedDeck: scope.libraryController.releaseOpenDeck,
        ),
        throwsA(isA<StateError>()),
      );

      _expectSavedDeckIntact(scope);
    });
  });

  group('one deck per save and publication', () {
    test(
      'saving a retained generation writes that generation after another deck was opened',
      () async {
        final scope = await _showingSavedDeck(markdown: _otherMarkdown);
        final wizard = _wizard(
          scope,
          result: _generatedResult(assetKey: 'generated-a.png'),
        );

        await wizard.controller.createOutline(_request);
        await wizard.controller.generateSlides();
        expect(wizard.controller.result, isNotNull);

        final reopened = await scope.libraryController.open(scope.savedRef);
        expect(reopened, isTrue);
        await _flush();
        expect(scope.document.markdown, _otherMarkdown);

        final saved = await saveRetainedWizardDeck(
          library: scope.libraryController,
          result: wizard.controller.result!,
          name: 'Generated copy',
        );

        expect(saved, isTrue);
        final path = scope.libraryController.openDeck!.reference.path;
        final stored = scope.library.markdown[path]!;
        expect(stored, contains('Only the generated deck.'));
        expect(stored, contains('generated-a.png'));
        expect(stored, isNot(contains('Saved deck B stays on screen.')));
        expect(scope.library.assets[path]?['generated-a.png'], [1, 2, 3]);
        expect(scope.library.themes[path], _paperTheme);
        expect(scope.document.markdown, stored);
        await _flush();
        expect(
          scope.deck.session.loadedSlides.value?.single.options?.title,
          'Generated A',
        );
      },
    );

    test(
      'a saved deck opened during generation is not replaced, and accepting the generation publishes only that generation',
      () async {
        final scope = _newScope();
        await scope.library.save(
          name: 'Saved A',
          markdown: _savedMarkdown,
          images: [
            GeneratedImageAsset.success(
              assetKey: 'saved-a.png',
              bytes: [4, 5, 6],
            ),
          ],
          theme: _boldTheme,
        );
        final savedRef = scope.library.saved.single;
        final gate = Completer<DeckGenerationResult>();
        final wizard = _wizard(scope, pendingResult: gate);

        await wizard.controller.createOutline(_request);
        final composition = wizard.controller.generateSlides();
        await Future<void>.delayed(Duration.zero);
        expect(wizard.controller.stage, WizardGenerationStage.composing);

        final opened = await scope.libraryController.open(savedRef);
        expect(opened, isTrue);
        await _flush();
        final saved = _snapshot(scope);
        final artwork = await scope.assets.resolve('saved-a.png');
        expect(artwork, isNotNull);

        gate.complete(_generatedResult());
        await composition;

        expect(wizard.controller.stage, WizardGenerationStage.completed);
        expect(wizard.controller.result, isNotNull);
        _expectSnapshot(scope, saved);
        expect(await scope.assets.resolve('saved-a.png'), artwork);

        await wizard.controller.acceptRetainedGeneration();
        await _flush();

        expect(scope.libraryController.openDeck, isNull);
        expect(scope.document.markdown, contains('Only the generated deck.'));
        expect(
          scope.document.markdown,
          isNot(contains('Saved deck A stays on screen.')),
        );
        expect(
          scope.deck.session.loadedSlides.value?.single.options?.title,
          'Generated A',
        );
        expect(scope.customization.background, isNot(saved.background));
        final generatedUri = await scope.assets.resolve('generated-a.png');
        final savedUri = await scope.assets.resolve('saved-a.png');
        expect(generatedUri, isNotNull);
        expect(savedUri, isNull);
      },
    );
  });

  group('library open and refresh', () {
    test(
      'a malformed open reports failure and keeps the previous deck',
      () async {
        final scope = await _showingSavedDeck();
        final saved = _snapshot(scope);
        final artwork = await scope.assets.resolve('saved-a.png');
        final broken = await scope.library.save(
          name: 'Broken',
          markdown: '@column\n',
        );
        final brokenRef = switch (broken) {
          Ok(:final value) => value.ref,
          Failure(:final error) => fail(
            'could not stage a broken deck: $error',
          ),
        };

        final opened = await scope.libraryController.open(brokenRef);

        expect(opened, isFalse);
        expect(scope.libraryController.errorMessage, isNotNull);
        _expectSnapshot(scope, saved);
        expect(await scope.assets.resolve('saved-a.png'), artwork);
      },
    );

    test(
      'an overlapping refresh does not mark the library idle while a save is still running',
      () async {
        final scope = _newScope();
        final saveEntered = Completer<void>();
        final releaseSave = Completer<void>();
        scope.library.beforeSave = () async {
          if (!saveEntered.isCompleted) saveEntered.complete();
          await releaseSave.future;
        };
        final saving = scope.libraryController.save(
          name: 'Current',
          markdown: _savedMarkdown,
          images: [
            GeneratedImageAsset.success(
              assetKey: 'saved-a.png',
              bytes: [4, 5, 6],
            ),
          ],
          theme: _boldTheme,
        );
        await saveEntered.future;

        final listEntered = Completer<void>();
        final releaseList = Completer<void>();
        scope.library.beforeList = () async {
          if (!listEntered.isCompleted) listEntered.complete();
          await releaseList.future;
        };
        scope.library.listError = Exception('stale list');
        final refreshing = scope.libraryController.refresh();
        await listEntered.future;
        releaseList.complete();
        await refreshing;

        expect(scope.libraryController.isBusy, isTrue);

        releaseSave.complete();
        final saved = await saving;
        await _flush();

        expect(saved, isTrue);
        expect(scope.libraryController.isBusy, isFalse);
        expect(scope.libraryController.decks.single.name, 'Current');
        expect(scope.libraryController.openDeck?.name, 'Current');
        expect(scope.libraryController.lastSave, isNotNull);
        expect(scope.libraryController.errorMessage, isNull);
        expect(scope.document.markdown, _savedMarkdown);
        expect(
          scope.deck.session.loadedSlides.value?.single.options?.title,
          'Saved A',
        );
        expect(await scope.assets.resolve('saved-a.png'), isNotNull);
        expect(scope.customization.background, isNot(Colors.black));
      },
    );

    test(
      'a refresh started during a save does not erase that save after it commits',
      () async {
        final scope = _newScope();
        final saveEntered = Completer<void>();
        final releaseSave = Completer<void>();
        scope.library.beforeSave = () async {
          if (!saveEntered.isCompleted) saveEntered.complete();
          await releaseSave.future;
        };
        final listEntered = Completer<void>();
        final releaseList = Completer<void>();
        scope.library.beforeList = () async {
          if (!listEntered.isCompleted) listEntered.complete();
          await releaseList.future;
        };

        final saving = scope.libraryController.save(name: 'Current');
        await saveEntered.future;
        final refreshing = scope.libraryController.refresh();
        await listEntered.future;

        releaseSave.complete();
        final saved = await saving;
        expect(saved, isTrue);
        expect(scope.libraryController.decks.single.name, 'Current');
        expect(scope.libraryController.openDeck?.name, 'Current');
        expect(scope.libraryController.isBusy, isTrue);

        scope.library.listError = Exception('late stale list');
        releaseList.complete();
        await refreshing;

        expect(scope.libraryController.decks.single.name, 'Current');
        expect(scope.libraryController.openDeck?.name, 'Current');
        expect(scope.libraryController.lastSave, isNotNull);
        expect(scope.libraryController.errorMessage, isNull);
        expect(scope.libraryController.isBusy, isFalse);
      },
    );

    test('an overlapping refresh does not drop a successful open', () async {
      final scope = _newScope();
      scope.document.replaceMarkdown(_savedMarkdown);
      final saved = await scope.libraryController.save(name: 'Saved A');
      expect(saved, isTrue);
      final ref = scope.libraryController.openDeck!;
      scope.libraryController.releaseOpenDeck();
      scope.document.replaceMarkdown('# Draft\n');

      final openEntered = Completer<void>();
      final releaseOpen = Completer<void>();
      scope.library.beforeOpen = () async {
        if (!openEntered.isCompleted) openEntered.complete();
        await releaseOpen.future;
      };
      final opening = scope.libraryController.open(ref);
      await openEntered.future;

      final listEntered = Completer<void>();
      final releaseList = Completer<void>();
      scope.library.beforeList = () async {
        if (!listEntered.isCompleted) listEntered.complete();
        await releaseList.future;
      };
      scope.library.listError = Exception('stale list');
      final refreshing = scope.libraryController.refresh();
      await listEntered.future;
      releaseList.complete();
      await refreshing;

      expect(scope.libraryController.isBusy, isTrue);
      expect(scope.document.markdown, '# Draft\n');

      releaseOpen.complete();
      final opened = await opening;
      await _flush();

      expect(opened, isTrue);
      expect(scope.libraryController.isBusy, isFalse);
      expect(scope.libraryController.openDeck, ref);
      expect(scope.document.markdown, _savedMarkdown);
      expect(
        scope.deck.session.loadedSlides.value?.single.options?.title,
        'Saved A',
      );
      expect(scope.libraryController.errorMessage, isNull);
    });

    test(
      'a slower refresh does not replace the deck list or error from a newer save',
      () async {
        final scope = _newScope();
        final listEntered = Completer<void>();
        final releaseList = Completer<void>();
        scope.library.beforeList = () async {
          if (!listEntered.isCompleted) listEntered.complete();
          await releaseList.future;
        };
        scope.library.listError = Exception('older list');
        final refreshing = scope.libraryController.refresh();
        await listEntered.future;

        final saved = await scope.libraryController.save(name: 'Newer');

        expect(saved, isTrue);
        expect(scope.libraryController.isBusy, isTrue);
        expect(scope.libraryController.decks.single.name, 'Newer');
        expect(scope.libraryController.errorMessage, isNull);

        releaseList.complete();
        await refreshing;

        expect(scope.libraryController.decks.single.name, 'Newer');
        expect(scope.libraryController.errorMessage, isNull);
        expect(scope.libraryController.isBusy, isFalse);
      },
    );

    test(
      'a slower refresh does not replace the error from a newer open',
      () async {
        final scope = await _showingSavedDeck();
        final listEntered = Completer<void>();
        final releaseList = Completer<void>();
        scope.library.beforeList = () async {
          if (!listEntered.isCompleted) listEntered.complete();
          await releaseList.future;
        };
        scope.library.listError = Exception('older list');
        final refreshing = scope.libraryController.refresh();
        await listEntered.future;
        scope.library.openError = Exception('missing deck');

        final opened = await scope.libraryController.open(scope.savedRef);

        expect(opened, isFalse);
        expect(scope.libraryController.isBusy, isTrue);
        expect(scope.libraryController.errorMessage, contains('missing deck'));

        releaseList.complete();
        await refreshing;

        expect(scope.libraryController.errorMessage, contains('missing deck'));
        expect(scope.libraryController.decks, isNotEmpty);
      },
    );
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

const _request = DeckGenerationRequest(
  userIntent: 'Ownership',
  slideCount: 1,
  themeId: 'technical-paper',
);

typedef _OwnedScope = ({
  DeckLibraryController libraryController,
  FakeDeckLibrary library,
  DeckDocumentStore document,
  MemoryDeckLoader loader,
  DeckCustomizationStore customization,
  DeckLibraryAssetStore assets,
  DeckController deck,
  GeneratedDeckResultApplier applier,
  SavedDeckRef savedRef,
  Uri? artworkUri,
  Color background,
  String? slideTitle,
});

_OwnedScope _newScope({AssetCacheStore? fallback}) {
  final library = FakeDeckLibrary();
  final memory = fallback ?? MemoryAssetCacheStore();
  final assets = DeckLibraryAssetStore(library: library, fallback: memory);
  final document = DeckDocumentStore(markdown: '# Draft\n');
  final loader = MemoryDeckLoader();
  final deck = DeckController(
    deckLoader: loader,
    options: DeckOptions(),
    assetCacheStore: assets,
  );
  final customization = DeckCustomizationStore(
    deck,
    background: Colors.black,
    foreground: Colors.white,
  );
  final libraryController = DeckLibraryController(
    library: library,
    documentStore: document,
    deckLoader: loader,
    customizationStore: customization,
    assetStore: assets,
  );
  final applier = GeneratedDeckResultApplier(
    documentStore: document,
    deckLoader: loader,
    assetCacheStore: assets,
    customizationStore: customization,
  );
  addTearDown(() {
    libraryController.dispose();
    customization.dispose();
    deck.dispose();
    document.dispose();
  });

  return (
    libraryController: libraryController,
    library: library,
    document: document,
    loader: loader,
    customization: customization,
    assets: assets,
    deck: deck,
    applier: applier,
    savedRef: SavedDeckRef(
      reference: DeckFileReference(path: '/unset'),
      name: 'unset',
      savedAt: DateTime.utc(2026),
    ),
    artworkUri: null,
    background: Colors.black,
    slideTitle: null,
  );
}

Future<_OwnedScope> _showingSavedDeck({
  AssetCacheStore? fallback,
  String markdown = _savedMarkdown,
  String name = 'Saved A',
  String assetKey = 'saved-a.png',
  SavedDeckTheme theme = _boldTheme,
}) async {
  final scope = _newScope(fallback: fallback);
  scope.document.replaceMarkdown(markdown);
  final saved = await scope.libraryController.save(
    name: name,
    images: [
      GeneratedImageAsset.success(assetKey: assetKey, bytes: [4, 5, 6]),
    ],
    theme: theme,
  );
  expect(saved, isTrue);
  final ref = scope.libraryController.openDeck!;
  final opened = await scope.libraryController.open(ref);
  expect(opened, isTrue);
  final uri = await scope.assets.resolve(assetKey);
  expect(uri, isNotNull);
  expect(scope.deck.session.loadedSlides.value, isNotNull);

  return (
    libraryController: scope.libraryController,
    library: scope.library,
    document: scope.document,
    loader: scope.loader,
    customization: scope.customization,
    assets: scope.assets,
    deck: scope.deck,
    applier: scope.applier,
    savedRef: ref,
    artworkUri: uri,
    background: scope.customization.background,
    slideTitle: scope.deck.session.loadedSlides.value?.single.options?.title,
  );
}

typedef _Snapshot = ({
  SavedDeckRef? openDeck,
  String markdown,
  Uri? artworkUri,
  Color background,
  String? slideTitle,
});

_Snapshot _snapshot(_OwnedScope scope) => (
  openDeck: scope.libraryController.openDeck,
  markdown: scope.document.markdown,
  artworkUri: scope.artworkUri,
  background: scope.customization.background,
  slideTitle: scope.deck.session.loadedSlides.value?.single.options?.title,
);

void _expectSnapshot(_OwnedScope scope, _Snapshot saved) {
  expect(scope.libraryController.openDeck, saved.openDeck);
  expect(scope.document.markdown, saved.markdown);
  expect(scope.customization.background, saved.background);
  expect(
    scope.deck.session.loadedSlides.value?.single.options?.title,
    saved.slideTitle,
  );
}

Future<void> _expectSavedDeckIntact(_OwnedScope scope) async {
  expect(scope.libraryController.openDeck, scope.savedRef);
  expect(scope.document.markdown, _savedMarkdown);
  expect(await scope.assets.resolve('saved-a.png'), scope.artworkUri);
  expect(scope.customization.background, scope.background);
  expect(
    scope.deck.session.loadedSlides.value?.single.options?.title,
    scope.slideTitle,
  );
}

DeckGenerationResult _generatedResult({String assetKey = 'generated-a.png'}) {
  final themes = PresentationThemeCatalog.withDefaults();
  final typography = PresentationTypographyCatalog.withDefaults();

  return DeckGenerationResult.success(
    slides: [_generatedSlide(assetKey)],
    plan: _plan(),
    theme: themes.resolve(
      id: 'technical-paper',
      version: 1,
      density: 'balanced',
      typographyCatalog: typography,
    ),
    generatedImages: [
      GeneratedImageAsset.success(assetKey: assetKey, bytes: [1, 2, 3]),
    ],
  );
}

Slide _generatedSlide(String assetKey) => Slide.parse({
  'key': 'opening',
  'options': {'title': 'Generated A', 'style': 'visual'},
  'sections': [
    {
      'type': 'section',
      'blocks': [
        {
          'type': 'block',
          'content': '## Generated A\n\nOnly the generated deck.',
        },
        {
          'type': 'widget',
          'name': 'image',
          'args': {'src': assetKey, 'fit': 'cover'},
        },
      ],
    },
  ],
});

DeckPlan _plan() => DeckPlan.parse({
  'topic': 'Ownership',
  'story': 'One deck is saved and shown.',
  'theme': {'id': 'technical-paper', 'version': 1, 'density': 'balanced'},
  'sections': [
    {
      'key': 'main',
      'title': 'Main',
      'purpose': 'Keep one deck together.',
      'transition': 'Close clearly.',
      'slideKeys': ['opening'],
    },
  ],
  'slides': [
    {
      'key': 'opening',
      'title': 'Generated A',
      'purpose': 'Show the generated deck.',
      'sectionKey': 'main',
      'assertion': 'The generated deck stands alone.',
      'contentUnits': ['Only the generated deck.'],
      'narrativeRole': 'opening',
      'contentBrief': 'Open with the generated deck.',
      'continuity': 'Lead into the story.',
      'composition': 'content',
      'treatment': 'visual',
      'density': 'balanced',
      'elements': <Object?>[],
    },
  ],
});

({WizardGenerationController controller}) _wizard(
  _OwnedScope scope, {
  DeckGenerationResult? result,
  Completer<DeckGenerationResult>? pendingResult,
}) {
  final service = _ScriptedGenerator(
    result: result ?? _generatedResult(),
    pendingResult: pendingResult,
  );
  final controller = WizardGenerationController(
    service: service,
    applyResult: (generated, {required isValid}) {
      return applyGeneratedDeckResult(
        applier: scope.applier,
        result: generated,
        isValid: isValid,
        releaseSavedDeck: scope.libraryController.releaseOpenDeck,
      );
    },
    deckSelectionEpoch: () => scope.libraryController.deckSelectionEpoch,
  );
  addTearDown(controller.dispose);

  return (controller: controller);
}

final class _ScriptedGenerator extends DeckGeneratorService {
  _ScriptedGenerator({required this.result, this.pendingResult})
    : super(apiKey: 'test-key');

  final DeckGenerationResult result;
  final Completer<DeckGenerationResult>? pendingResult;

  @override
  Future<DeckPlanningResult> plan(
    DeckGenerationRequest request, {
    onProgress,
    onTrace,
    isCancelled,
  }) async {
    return DeckPlanningResult.success(_plan());
  }

  @override
  Future<DeckGenerationResult> generateFromPlan(
    DeckGenerationRequest request,
    DeckPlan approvedPlan, {
    onProgress,
    onTrace,
    isCancelled,
  }) {
    final pending = pendingResult;
    if (pending != null) return pending.future;

    return Future<DeckGenerationResult>.value(result);
  }
}

final class _ThrowingAssetCache extends MemoryAssetCacheStore {
  @override
  Future<Uri?> write(String assetKey, List<int> bytes) {
    throw StateError('cannot store artwork');
  }
}
