import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/tools/deck_store.dart';
import 'package:playground/features/ai/core/tools/errors.dart';
import 'package:playground/utils/memory_deck_loader.dart';

/// In-memory [DeckStore] — web-safe, no dart:io.
///
/// Reads the current slide list via a [SlidesProvider] callback so that
/// [DeckToolsService] always sees the live state from [MemoryDeckLoader].
/// Writes serialize slides back to Markdown and push them into the loader.
typedef SlidesProvider = List<Slide> Function();

class InMemoryDeckStore implements DeckStore {
  InMemoryDeckStore({
    required SlidesProvider slidesProvider,
    required MemoryDeckLoader deckLoader,
    DeckStyleType? initialStyle,
  }) : _slidesProvider = slidesProvider,
       _deckLoader = deckLoader,
       _currentStyle = initialStyle;

  final SlidesProvider _slidesProvider;
  final MemoryDeckLoader _deckLoader;
  DeckStyleType? _currentStyle;

  @override
  Future<DeckDocument> readRequired() async {
    final slides = _slidesProvider();
    if (slides.isEmpty) {
      // Return an empty document rather than throwing — an empty presentation
      // is valid state (e.g. before any content is loaded).
      return DeckDocument(slides: const [], style: _currentStyle);
    }
    return DeckDocument(slides: slides, style: _currentStyle);
  }

  @override
  Future<void> writeCanonical({
    required List<Slide> slides,
    DeckStyleType? style,
  }) async {
    _currentStyle = style;
    try {
      final markdown = const SlideSerializer().serialize(slides);
      _deckLoader.updateMarkdown(markdown);
    } catch (e) {
      throw DeckToolException.deckWriteFailed(
        path: '<in-memory>',
        details: '$e',
      );
    }
  }

  /// Updates the stored style without touching slides.
  void updateStyle(DeckStyleType? style) {
    _currentStyle = style;
  }

  /// Returns the most recently written style.
  DeckStyleType? get currentStyle => _currentStyle;
}
