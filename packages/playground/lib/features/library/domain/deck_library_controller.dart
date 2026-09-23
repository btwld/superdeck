import 'package:flutter/foundation.dart';

import '../../../core/data/data_sources/deck_library_asset_store.dart';
import '../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../core/domain/design/generated_deck_style_mapper.dart';
import '../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../core/domain/design/presentation_typography_catalog.dart';
import '../../../core/domain/generated_image_asset.dart';
import '../../../core/domain/stores/deck_customization_store.dart';
import '../../../core/domain/stores/deck_document_store.dart';
import '../../../core/result.dart';
import 'deck_library.dart';
import 'saved_deck.dart';

/// Saves generated decks and opens saved ones for presentation.
///
/// One object owns both directions because they share the runtime a deck is
/// published into: the document, the preview loader, the theme, and which
/// deck's artwork the renderer resolves.
class DeckLibraryController extends ChangeNotifier {
  final DeckLibrary _library;
  final DeckDocumentStore _documentStore;
  final MemoryDeckLoader _deckLoader;
  final DeckCustomizationStore _customizationStore;
  final DeckLibraryAssetStore _assetStore;
  final PresentationThemeCatalog _themeCatalog;
  final PresentationTypographyCatalog _typographyCatalog;

  List<SavedDeckRef> _decks = const [];
  DeckSaveOutcome? _lastSave;
  String? _errorMessage;
  bool _isBusy = false;

  DeckLibraryController({
    required DeckLibrary library,
    required DeckDocumentStore documentStore,
    required MemoryDeckLoader deckLoader,
    required DeckCustomizationStore customizationStore,
    required DeckLibraryAssetStore assetStore,
    PresentationThemeCatalog? themeCatalog,
    PresentationTypographyCatalog? typographyCatalog,
  }) : _library = library,
       _documentStore = documentStore,
       _deckLoader = deckLoader,
       _customizationStore = customizationStore,
       _assetStore = assetStore,
       _themeCatalog = themeCatalog ?? PresentationThemeCatalog.withDefaults(),
       _typographyCatalog =
           typographyCatalog ?? PresentationTypographyCatalog.withDefaults();

  void _setBusy({required bool busy}) {
    _isBusy = busy;
    notifyListeners();
  }

  /// Restores the appearance a deck was saved with.
  ///
  /// A selection the catalog no longer offers leaves the current theme alone
  /// and is reported, rather than resolving to a different-looking deck.
  String? _applyTheme(SavedDeckTheme? theme) {
    if (theme == null) return null;
    try {
      final resolved = _themeCatalog.resolve(
        id: theme.id,
        version: theme.version,
        typographyCatalog: _typographyCatalog,
        density: theme.density,
      );
      _customizationStore.applyGeneratedStyle(resolved.toGeneratedDeckStyle());

      return null;
    } catch (_) {
      return 'This deck was saved with the "${theme.id}" theme, version '
          '${theme.version}, which this version of SuperDeck no longer has. '
          'The deck opens with the current theme.';
    }
  }

  /// Saved decks, newest first.
  List<SavedDeckRef> get decks => _decks;

  /// What the last save wrote, for the notice the Wizard shows.
  DeckSaveOutcome? get lastSave => _lastSave;

  /// A user-facing reason the last save or open did not finish.
  String? get errorMessage => _errorMessage;

  /// Whether a save or open is running.
  bool get isBusy => _isBusy;

  /// Whether decks can be stored at all on this platform.
  bool get canSave => _library.canSave;

  /// Writes the current document as a new deck named [name].
  ///
  /// [images] carries the artwork of the generation that produced the
  /// document, and [theme] the selection it was generated with.
  Future<bool> save({
    required String name,
    List<GeneratedImageAsset> images = const [],
    SavedDeckTheme? theme,
  }) async {
    if (_isBusy) return false;
    _errorMessage = null;
    _setBusy(busy: true);
    try {
      final result = await _library.save(
        name: name,
        markdown: _documentStore.markdown,
        images: images,
        theme: theme,
      );
      switch (result) {
        case Ok(:final value):
          _lastSave = value;
          // The saved copy, not the run's memory, now owns this artwork.
          _assetStore.bindTo(value.ref);
          _decks = [value.ref, ..._decks.where((ref) => ref != value.ref)];

          return true;
        case Failure(:final error):
          _errorMessage = '$error';

          return false;
      }
    } finally {
      _setBusy(busy: false);
    }
  }

  /// Reloads the list of saved decks.
  Future<void> refresh() async {
    _errorMessage = null;
    _setBusy(busy: true);
    try {
      switch (await _library.list()) {
        case Ok(:final value):
          _decks = value;
        case Failure(:final error):
          _errorMessage = '$error';
      }
    } finally {
      _setBusy(busy: false);
    }
  }

  /// Publishes the saved deck at [ref] for presentation.
  ///
  /// The deck is read-only: it is loaded into the preview and the renderer,
  /// with its own artwork and the theme it was saved with.
  Future<bool> open(SavedDeckRef ref) async {
    if (_isBusy) return false;
    _errorMessage = null;
    _setBusy(busy: true);
    try {
      switch (await _library.open(ref)) {
        case Ok(:final value):
          _assetStore.bindTo(value.ref);
          _documentStore.replaceMarkdown(value.markdown);
          _deckLoader.updateMarkdown(value.markdown);
          _errorMessage = _applyTheme(value.theme);

          return true;
        case Failure(:final error):
          _errorMessage = '$error';

          return false;
      }
    } finally {
      _setBusy(busy: false);
    }
  }

  /// Forgets the open saved deck, so a new generation owns the runtime again.
  void releaseOpenDeck() {
    _lastSave = null;
    _assetStore.bindTo(null);
    notifyListeners();
  }
}
