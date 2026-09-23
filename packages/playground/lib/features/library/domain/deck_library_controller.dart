import 'package:flutter/foundation.dart';

import '../../../core/data/data_sources/deck_library_asset_store.dart';
import '../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../core/data/mappers/deck_markdown_codec.dart';
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

  static const _codec = DeckMarkdownCodec();

  List<SavedDeckRef> _decks = const [];
  SavedDeckRef? _openDeck;
  DeckSaveOutcome? _lastSave;
  String? _errorMessage;
  int _mutationGeneration = 0;
  int _listGeneration = 0;
  int _completedMutations = 0;
  int _inFlight = 0;
  int _deckSelectionEpoch = 0;
  bool _mutationInFlight = false;

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

  void _beginOperation() {
    _inFlight++;
    notifyListeners();
  }

  void _endOperation() {
    _inFlight--;
    notifyListeners();
  }

  bool _isLatestMutation(int generation) => generation == _mutationGeneration;

  bool _isLatestList(int generation) => generation == _listGeneration;

  bool _refreshIsStale(int generation, int seenMutations) {
    return !_isLatestList(generation) ||
        _mutationInFlight ||
        seenMutations != _completedMutations;
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

  /// The saved deck being presented, or `null` for a generated one.
  SavedDeckRef? get openDeck => _openDeck;

  /// Advances when a saved deck is committed to the runtime.
  ///
  /// A generation captures this before it can publish. Opening another deck
  /// withdraws that automatic publication; the retained result can still be
  /// accepted explicitly.
  int get deckSelectionEpoch => _deckSelectionEpoch;

  /// What the last save wrote, for the notice the Wizard shows.
  DeckSaveOutcome? get lastSave => _lastSave;

  /// A user-facing reason the last save or open did not finish.
  String? get errorMessage => _errorMessage;

  /// Whether a save, open, or refresh is running.
  bool get isBusy => _inFlight > 0;

  /// Whether decks can be stored at all on this platform.
  bool get canSave => _library.canSave;

  /// Writes one deck named [name].
  ///
  /// [markdown] is the document to persist. When it is omitted, the current
  /// runtime document is saved. [images] and [theme] belong to that same deck.
  /// An explicit [markdown] also becomes the deck on screen, so a save cannot
  /// store one deck's text beside another's artwork.
  Future<bool> save({
    required String name,
    String? markdown,
    List<GeneratedImageAsset> images = const [],
    SavedDeckTheme? theme,
  }) async {
    if (_mutationInFlight) return false;
    _mutationInFlight = true;
    final mutation = ++_mutationGeneration;
    // A refresh that started earlier, or that finishes while this save is
    // still writing, must not replace the deck this save commits.
    _listGeneration++;
    final persisted = markdown ?? _documentStore.markdown;
    _beginOperation();
    try {
      final result = await _library.save(
        name: name,
        markdown: persisted,
        images: images,
        theme: theme,
      );
      final current = _isLatestMutation(mutation);
      switch (result) {
        case Ok(:final value):
          if (current) {
            _lastSave = value;
            // The saved copy, not the run's memory, now owns this artwork.
            _openDeck = value.ref;
            _assetStore.bindTo(value.ref);
            _decks = [value.ref, ..._decks.where((ref) => ref != value.ref)];
            _errorMessage = null;
            if (markdown != null) {
              _documentStore.replaceMarkdown(persisted);
              _deckLoader.updateMarkdown(persisted);
              if (theme != null) _errorMessage = _applyTheme(theme);
            }
            _completedMutations++;
          }

          return true;
        case Failure(:final error):
          if (current) {
            _errorMessage = '$error';
            _completedMutations++;
          }

          return false;
      }
    } finally {
      _mutationInFlight = false;
      _endOperation();
    }
  }

  /// Reloads the list of saved decks.
  ///
  /// Refresh may overlap a save or an open. It does not clear [isBusy] while
  /// that other operation is still running, and a stale completion does not
  /// replace a newer deck list or error.
  Future<void> refresh() async {
    final generation = ++_listGeneration;
    final seenMutations = _completedMutations;
    _beginOperation();
    try {
      switch (await _library.list()) {
        case Ok(:final value):
          if (_refreshIsStale(generation, seenMutations)) return;
          _decks = value;
          _errorMessage = null;
        case Failure(:final error):
          if (_refreshIsStale(generation, seenMutations)) return;
          _errorMessage = '$error';
      }
    } finally {
      _endOperation();
    }
  }

  /// Publishes the saved deck at [ref] for presentation.
  ///
  /// The deck is read-only: it is loaded into the preview and the renderer,
  /// with its own artwork and the theme it was saved with. Document, artwork
  /// binding, theme, and slides change together, and only after the Markdown
  /// decodes.
  Future<bool> open(SavedDeckRef ref) async {
    if (_mutationInFlight) return false;
    _mutationInFlight = true;
    final mutation = ++_mutationGeneration;
    _listGeneration++;
    _beginOperation();
    try {
      switch (await _library.open(ref)) {
        case Ok(:final value):
          if (!_isLatestMutation(mutation)) return false;
          try {
            _codec.decode(value.markdown);
          } catch (error) {
            _errorMessage = '$error';
            _completedMutations++;

            return false;
          }
          if (!_isLatestMutation(mutation)) return false;
          _openDeck = value.ref;
          _assetStore.bindTo(value.ref);
          _documentStore.replaceMarkdown(value.markdown);
          _deckLoader.updateMarkdown(value.markdown);
          _errorMessage = _applyTheme(value.theme);
          _deckSelectionEpoch++;
          _completedMutations++;

          return true;
        case Failure(:final error):
          if (!_isLatestMutation(mutation)) return false;
          _errorMessage = '$error';
          _completedMutations++;

          return false;
      }
    } finally {
      _mutationInFlight = false;
      _endOperation();
    }
  }

  /// Forgets the open saved deck, so a new generation owns the runtime again.
  void releaseOpenDeck() {
    _openDeck = null;
    _lastSave = null;
    _assetStore.bindTo(null);
    notifyListeners();
  }
}
