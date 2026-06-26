import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';

/// A snapshot of the current deck contents held by a [DeckStore].
class DeckDocument {
  const DeckDocument({required this.slides, required this.style});

  final List<Slide> slides;
  final DeckStyleType? style;
}

/// Read/write seam between [DeckToolsService] and the underlying storage.
///
/// Concrete implementations may write to disk (DeckDocumentStore) or keep the
/// deck entirely in-memory ([InMemoryDeckStore]).
abstract interface class DeckStore {
  /// Returns the current deck document, throwing if unavailable.
  Future<DeckDocument> readRequired();

  /// Persists [slides] (and optional [style]) as the canonical deck state.
  Future<void> writeCanonical({
    required List<Slide> slides,
    DeckStyleType? style,
  });
}
