/// Shared identity for SuperDeck plugin types.
///
/// Runtime and build plugins use different lifecycle APIs, but both expose a
/// stable [id] so registration, diagnostics, and duplicate checks can refer to
/// plugins consistently.
abstract base class DeckPlugin {
  /// Creates a SuperDeck plugin.
  const DeckPlugin();

  /// Stable identifier used for plugin registration and diagnostics.
  ///
  /// IDs must be non-empty and unique within one registration surface.
  String get id;
}
