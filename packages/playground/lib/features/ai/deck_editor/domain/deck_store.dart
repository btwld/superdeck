import 'package:superdeck_core/superdeck_core.dart';

/// Canonical document operations used by the deck editing tools.
abstract interface class DeckStore {
  /// Decodes the editor's current document.
  List<Slide> read();

  /// Replaces the editor with [slides] and completes after the preview observes it.
  Future<List<Slide>> write(List<Slide> slides);

  /// Restores exact source [markdown] and completes after preview synchronization.
  Future<List<Slide>> restore(String markdown);

  /// Completes when the current editor document and preview agree structurally.
  Future<List<Slide>> synchronize();
}
