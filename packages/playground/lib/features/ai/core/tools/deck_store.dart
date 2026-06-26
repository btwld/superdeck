import 'package:superdeck_core/superdeck_core.dart';

/// A snapshot of the current live deck contents held by a [DeckStore].
class DeckDocument {
  const DeckDocument({required this.slides});

  final List<Slide> slides;
}

/// Read/write seam between [DeckToolsService] and live deck state.
abstract interface class DeckStore {
  /// Returns the current live deck document.
  Future<DeckDocument> readRequired();

  /// Persists [slides] as canonical markdown and waits for live observation.
  Future<void> writeCanonical(List<Slide> slides);

  /// Writes raw markdown through parse/serialize canonicalization.
  ///
  /// Returns the canonical markdown observed from the live deck.
  Future<String> writeCanonicalMarkdown(String markdown);

  /// Alias for route-boundary callers that describe the operation as a flush.
  Future<String> flushMarkdownToCanonical(String markdown);
}
