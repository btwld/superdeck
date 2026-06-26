import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/tools/deck_store.dart';
import 'package:playground/features/ai/core/tools/errors.dart';
import 'package:playground/utils/memory_deck_loader.dart';

/// Reads the live slide list from a [MemoryDeckLoader].
typedef SlidesProvider = List<Slide> Function();

/// In-memory [DeckStore] — web-safe, no dart:io.
///
/// Reads the current slide list via a [SlidesProvider] callback so that
/// [DeckToolsService] always sees the live state from [MemoryDeckLoader].
/// Writes serialize slides back to Markdown and push them into the loader.
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
    // An empty presentation is valid state (e.g. before any content is
    // loaded), so this never throws despite the interface name.
    return DeckDocument(slides: _slidesProvider(), style: _currentStyle);
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

}
