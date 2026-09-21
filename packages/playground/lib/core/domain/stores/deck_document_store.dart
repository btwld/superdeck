import 'package:flutter/foundation.dart';

/// The playground's sole logical Markdown document.
///
/// Generation publishes whole documents into it, and the preview and the saved
/// deck both read from it. Identical content is intentionally ignored so a
/// republished but unchanged document cannot trigger a preview feedback loop.
class DeckDocumentStore extends ChangeNotifier {
  int _revision = 0;
  String _markdown;

  DeckDocumentStore({required String markdown}) : _markdown = markdown;

  /// The current full Markdown document.
  String get markdown => _markdown;

  /// Counts the accepted replacements of this document.
  ///
  /// A long-running operation captures this value when it starts and compares
  /// it before it publishes, so it cannot overwrite a newer document.
  int get revision => _revision;

  /// Replaces the document and notifies listeners when its text changed.
  void replaceMarkdown(String markdown) {
    if (markdown == _markdown) return;
    _markdown = markdown;
    _revision++;
    notifyListeners();
  }
}
